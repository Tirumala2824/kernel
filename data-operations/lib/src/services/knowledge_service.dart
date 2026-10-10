import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart' show listEquals, mapEquals;
import 'package:kernel_contracts/kernel_contracts.dart';

import '../db/database.dart';
import '../mappers.dart';
import '../support.dart';

/// Returns the card pack JSON (docs/knowledge-cards.md). The app passes
/// `() => rootBundle.loadString('assets/knowledge/pest_cards.json')`.
typedef KnowledgeCardsSource = Future<String> Function();

/// Curated knowledge cards with on-device semantic search (guardrails §9).
///
/// - The pack is read from [KnowledgeCardsSource] on first use and mirrored
///   into `knowledge_cards`: valid cards are upserted, cards no longer in
///   the pack (or now invalid) are removed with their embeddings. If the
///   source fails or is not JSON, the stored cards are used and the next
///   call tries again. Without a source, the stored cards are used.
/// - [search] embeds with the [Embedder] (EmbeddingGemma) at [embeddingDim]
///   and ranks by cosine similarity once every card has a cached vector for
///   the embedder's current model version. Missing vectors are computed in
///   the background ([indexEmbeddings]); until then, and whenever the
///   embedder is missing or fails, a keyword search over names, signs and
///   summary answers instead. [search] never throws.
///
/// Everything runs on the phone; nothing is sent anywhere.
class DriftKnowledgeService implements KnowledgeService {
  DriftKnowledgeService(
    this._db,
    this._clock, {
    this._cardsJson,
    this._embedder,
  });

  /// Matryoshka dimension of the cached card vectors.
  static const embeddingDim = 256;

  final KernelDatabase _db;
  final Clock _clock;
  final KnowledgeCardsSource? _cardsJson;
  final Embedder? _embedder;

  List<KnowledgeCard>? _cache;
  Future<void>? _syncing;
  final _indexing = <String, Future<bool>>{};
  bool _closed = false;

  /// Every stored card, by English name.
  @override
  Future<List<KnowledgeCard>> all() async => _cards();

  @override
  Future<KnowledgeCard?> get(String id) async {
    for (final card in await _cards()) {
      if (card.id == id) return card;
    }
    return null;
  }

  /// Top [limit] cards for [query]. Semantic scores are cosine similarities
  /// (-1..1); keyword scores are 0..1. Empty for a blank query, a
  /// non-positive limit or no cards. Never throws.
  @override
  Future<List<KnowledgeHit>> search(String query, {int limit = 3}) async {
    final text = query.trim();
    if (text.isEmpty || limit <= 0) return const [];
    List<KnowledgeCard> cards;
    try {
      cards = await _cards();
    } catch (_) {
      return const [];
    }
    if (cards.isEmpty) return const [];
    try {
      final semantic = await _semanticSearch(text, cards, limit);
      if (semantic != null) return semantic;
    } catch (_) {
      // Fall through to the keyword search.
    }
    try {
      return keywordSearch(text, cards, limit: limit);
    } catch (_) {
      return const [];
    }
  }

  /// Computes the missing card vectors for the embedder's current model
  /// version now (one job per version at a time). True when every card has
  /// a vector afterwards. Older model versions' vectors are dropped once
  /// the current version is complete. Never throws.
  Future<bool> indexEmbeddings() async {
    final embedder = _embedder;
    if (embedder == null || _closed) return false;
    try {
      if (!await embedder.isAvailable()) return false;
      final version = blankToNull(await embedder.modelVersion());
      if (version == null) return false;
      return await _indexVersion(version);
    } catch (_) {
      return false;
    }
  }

  /// Stops background indexing and waits briefly for a running job.
  Future<void> dispose() async {
    _closed = true;
    final jobs = [..._indexing.values];
    if (jobs.isEmpty) return;
    try {
      await Future.wait(jobs).timeout(const Duration(seconds: 5));
    } catch (_) {
      // A job that outlives the database fails quietly on its own.
    }
  }

  Future<List<KnowledgeCard>> _cards() async {
    final cached = _cache;
    if (cached != null) return cached;
    await (_syncing ??= _sync().whenComplete(() => _syncing = null));
    return _cache ?? await _readAll();
  }

  /// Mirrors the pack into the table, then caches the stored cards. A
  /// failing source leaves the table untouched and nothing cached.
  Future<void> _sync() async {
    final source = _cardsJson;
    if (source != null) {
      final KnowledgePack pack;
      try {
        pack = parseKnowledgePack(await source());
      } catch (_) {
        return;
      }
      await _store(pack);
    }
    _cache = await _readAll();
  }

  Future<void> _store(KnowledgePack pack) {
    return _db.transaction(() async {
      final existing = {
        for (final row in await _db.select(_db.knowledgeCards).get())
          row.cardId: row,
      };
      final keep = {for (final card in pack.cards) card.id};
      final stale = [
        for (final id in existing.keys)
          if (!keep.contains(id)) id,
      ];
      if (stale.isNotEmpty) {
        await (_db.delete(
          _db.cardEmbeddings,
        )..where((e) => e.cardId.isIn(stale))).go();
        await (_db.delete(
          _db.knowledgeCards,
        )..where((c) => c.cardId.isIn(stale))).go();
      }
      final now = _clock().toUtc();
      for (final card in pack.cards) {
        final row = existing[card.id];
        final hash = cardContentHash(card);
        if (row != null && _same(row, card, pack.version, hash)) continue;
        final fields = KnowledgeCardsCompanion(
          updatedAt: Value(now),
          names: Value(card.names),
          pestGroup: Value(card.group),
          safety: Value(card.safety),
          summary: Value(card.summary),
          signs: Value(card.signs),
          lookAlikes: Value(card.lookAlikes),
          healthRisks: Value(card.healthRisks),
          safeSteps: Value(card.safeSteps),
          callProfessionalWhen: Value(card.callProfessionalWhen),
          firstAid: Value(card.firstAid),
          legal: Value(card.legal),
          sources: Value(card.sources),
          reviewStatus: Value(card.reviewStatus),
          packVersion: Value(pack.version),
          contentHash: Value(hash),
        );
        if (row == null) {
          await _db
              .into(_db.knowledgeCards)
              .insert(
                fields.copyWith(
                  id: Value(newId()),
                  createdAt: Value(now),
                  cardId: Value(card.id),
                ),
              );
        } else {
          await (_db.update(
            _db.knowledgeCards,
          )..where((c) => c.cardId.equals(card.id))).write(fields);
        }
      }
    });
  }

  static bool _same(
    KnowledgeCardRow row,
    KnowledgeCard card,
    String version,
    String hash,
  ) =>
      row.contentHash == hash &&
      row.packVersion == version &&
      mapEquals(row.names, card.names) &&
      row.pestGroup == card.group &&
      row.safety == card.safety &&
      row.summary == card.summary &&
      listEquals(row.signs, card.signs) &&
      listEquals(row.lookAlikes, card.lookAlikes) &&
      listEquals(row.healthRisks, card.healthRisks) &&
      listEquals(row.safeSteps, card.safeSteps) &&
      listEquals(row.callProfessionalWhen, card.callProfessionalWhen) &&
      listEquals(row.firstAid, card.firstAid) &&
      row.legal == card.legal &&
      listEquals(row.sources, card.sources) &&
      row.reviewStatus == card.reviewStatus;

  Future<List<KnowledgeCard>> _readAll() async {
    final rows = await _db.select(_db.knowledgeCards).get();
    final cards = [for (final row in rows) row.toModel()]
      ..sort((a, b) {
        final byName = a.names['en']!.toLowerCase().compareTo(
          b.names['en']!.toLowerCase(),
        );
        return byName != 0 ? byName : a.id.compareTo(b.id);
      });
    return List.unmodifiable(cards);
  }

  /// Null when semantic search cannot answer yet (no embedder, no model,
  /// vectors still missing, or the query could not be embedded).
  Future<List<KnowledgeHit>?> _semanticSearch(
    String query,
    List<KnowledgeCard> cards,
    int limit,
  ) async {
    final embedder = _embedder;
    if (embedder == null || _closed) return null;
    if (!await embedder.isAvailable()) return null;
    final version = blankToNull(await embedder.modelVersion());
    if (version == null) return null;
    final vectors = await _cachedVectors(version, cards);
    if (vectors.length < cards.length) {
      _scheduleIndex(version);
      return null;
    }
    final q = await embedder.embedText(
      query,
      task: EmbeddingTask.searchQuery,
      dim: embeddingDim,
    );
    if (q == null || q.dim != embeddingDim || q.modelVersion != version) {
      return null;
    }
    final hits = [
      for (final card in cards)
        KnowledgeHit(card: card, score: q.cosine(vectors[card.id]!)),
    ]..sort(_byScore);
    return List.unmodifiable(hits.take(limit));
  }

  /// Cached vectors for [version] whose content hash still matches.
  Future<Map<String, EmbeddingVector>> _cachedVectors(
    String version,
    List<KnowledgeCard> cards,
  ) async {
    final rows =
        await (_db.select(_db.cardEmbeddings)..where(
              (e) =>
                  e.modelVersion.equals(version) & e.dim.equals(embeddingDim),
            ))
            .get();
    final hashes = {for (final card in cards) card.id: cardContentHash(card)};
    return {
      for (final row in rows)
        if (hashes[row.cardId] == row.contentHash &&
            row.vector.lengthInBytes == embeddingDim * 4)
          row.cardId: EmbeddingVector(
            values: decodeVector(row.vector),
            modelVersion: version,
          ),
    };
  }

  void _scheduleIndex(String version) {
    if (_indexing.containsKey(version) || _closed) return;
    unawaited(_indexVersion(version));
  }

  Future<bool> _indexVersion(String version) {
    final running = _indexing[version];
    if (running != null) return running;
    final job = _runIndex(version).catchError((Object _) => false);
    _indexing[version] = job;
    return job.whenComplete(() => _indexing.remove(version));
  }

  Future<bool> _runIndex(String version) async {
    final embedder = _embedder!;
    final cards = await _cards();
    final cached = await _cachedVectors(version, cards);
    for (final card in cards) {
      if (_closed) return false;
      if (cached.containsKey(card.id)) continue;
      final vector = await embedder.embedText(
        cardEmbeddingText(card),
        task: EmbeddingTask.searchDocument,
        dim: embeddingDim,
      );
      if (_closed) return false;
      // Busy, unloaded or swapped model: stop and retry on a later search.
      if (vector == null ||
          vector.dim != embeddingDim ||
          vector.modelVersion != version) {
        return false;
      }
      final now = _clock().toUtc();
      await _db
          .into(_db.cardEmbeddings)
          .insert(
            CardEmbeddingsCompanion.insert(
              id: newId(),
              createdAt: now,
              updatedAt: now,
              cardId: card.id,
              modelVersion: version,
              dim: embeddingDim,
              vector: encodeVector(vector.values),
              contentHash: cardContentHash(card),
            ),
            onConflict: DoUpdate(
              (_) => CardEmbeddingsCompanion(
                vector: Value(encodeVector(vector.values)),
                contentHash: Value(cardContentHash(card)),
                updatedAt: Value(now),
              ),
              target: [
                _db.cardEmbeddings.cardId,
                _db.cardEmbeddings.modelVersion,
                _db.cardEmbeddings.dim,
              ],
            ),
          );
    }
    if (_closed) return false;
    await (_db.delete(
      _db.cardEmbeddings,
    )..where((e) => e.modelVersion.equals(version).not())).go();
    return true;
  }
}

/// A parsed card pack: its `version` and the cards that passed validation.
class KnowledgePack {
  const KnowledgePack({
    required this.version,
    required this.cards,
    required this.skipped,
  });

  final String version;
  final List<KnowledgeCard> cards;

  /// Ids (or positions, `#<index>`) of cards that were left out.
  final List<String> skipped;
}

/// Parses the pack JSON (docs/knowledge-cards.md). Throws [FormatException]
/// when the document itself is unusable (not JSON, no `version`, no `cards`
/// list). Individual cards that break the schema rules are skipped:
/// - `id` must be snake_case and unique (the first one wins);
/// - `names.en`, `summary` and `reviewStatus` must not be blank;
/// - `group` and `safety` must be known values;
/// - at least one source;
/// - `protectedWildlife` needs a `legal` text.
KnowledgePack parseKnowledgePack(String json) {
  final decoded = jsonDecode(json);
  if (decoded is! Map<String, Object?>) {
    throw const FormatException('card pack must be a JSON object');
  }
  final version = decoded['version'];
  if (version is! String || version.trim().isEmpty) {
    throw const FormatException('card pack needs a version');
  }
  final list = decoded['cards'];
  if (list is! List<Object?>) {
    throw const FormatException('card pack needs a cards list');
  }
  final cards = <KnowledgeCard>[];
  final skipped = <String>[];
  final seen = <String>{};
  for (var i = 0; i < list.length; i++) {
    final raw = list[i];
    final card = raw is Map<String, Object?> ? _parseCard(raw) : null;
    if (card == null || !seen.add(card.id)) {
      final id = raw is Map<String, Object?> ? raw['id'] : null;
      skipped.add(id is String && id.isNotEmpty ? id : '#$i');
      continue;
    }
    cards.add(card);
  }
  return KnowledgePack(
    version: version.trim(),
    cards: List.unmodifiable(cards),
    skipped: List.unmodifiable(skipped),
  );
}

final _cardId = RegExp(r'^[a-z][a-z0-9]*(_[a-z0-9]+)*$');

KnowledgeCard? _parseCard(Map<String, Object?> raw) {
  final id = raw['id'];
  if (id is! String || !_cardId.hasMatch(id)) return null;
  final namesRaw = raw['names'];
  if (namesRaw is! Map<String, Object?>) return null;
  final names = <String, String>{};
  for (final entry in namesRaw.entries) {
    final value = entry.value;
    if (value is String && value.trim().isNotEmpty) {
      names[entry.key.trim()] = value.trim();
    }
  }
  if (names['en'] == null) return null;
  final group = _enum(PestGroup.values, raw['group']);
  final safety = _enum(SafetyLevel.values, raw['safety']);
  final summary = _text(raw['summary']);
  final reviewStatus = _text(raw['reviewStatus']);
  if (group == null ||
      safety == null ||
      summary == null ||
      reviewStatus == null) {
    return null;
  }
  final lists = <String, List<String>>{};
  for (final key in const [
    'signs',
    'lookAlikes',
    'healthRisks',
    'safeSteps',
    'callProfessionalWhen',
    'firstAid',
    'sources',
  ]) {
    final value = raw[key];
    if (value == null) {
      lists[key] = const [];
      continue;
    }
    if (value is! List<Object?>) return null;
    lists[key] = List.unmodifiable([
      for (final entry in value)
        if (entry is String && entry.trim().isNotEmpty) entry.trim(),
    ]);
  }
  final legalRaw = raw['legal'];
  if (legalRaw != null && legalRaw is! String) return null;
  final legal = blankToNull(legalRaw as String?);
  if (lists['sources']!.isEmpty) return null;
  if (safety == SafetyLevel.protectedWildlife && legal == null) return null;
  return KnowledgeCard(
    id: id,
    names: Map.unmodifiable(names),
    group: group,
    safety: safety,
    summary: summary,
    signs: lists['signs']!,
    lookAlikes: lists['lookAlikes']!,
    healthRisks: lists['healthRisks']!,
    safeSteps: lists['safeSteps']!,
    callProfessionalWhen: lists['callProfessionalWhen']!,
    firstAid: lists['firstAid']!,
    legal: legal,
    sources: lists['sources']!,
    reviewStatus: reviewStatus,
  );
}

T? _enum<T extends Enum>(List<T> values, Object? name) {
  if (name is! String) return null;
  for (final value in values) {
    if (value.name == name.trim()) return value;
  }
  return null;
}

String? _text(Object? value) => value is String ? blankToNull(value) : null;

/// The text a card is embedded from: its names, summary and signs.
String cardEmbeddingText(KnowledgeCard card) {
  final others = [
    for (final entry in card.names.entries)
      if (entry.key != 'en') entry,
  ]..sort((a, b) => a.key.compareTo(b.key));
  return [
    [card.names['en']!, for (final e in others) e.value].join(' / '),
    card.summary,
    if (card.signs.isNotEmpty) 'Signs: ${card.signs.join('; ')}',
  ].join('\n');
}

/// FNV-1a (64-bit) of [cardEmbeddingText], as hex. Detects card edits that
/// invalidate a cached vector; not a security hash.
String cardContentHash(KnowledgeCard card) {
  var hash = 0xcbf29ce484222325;
  for (final byte in utf8.encode(cardEmbeddingText(card))) {
    hash ^= byte;
    hash *= 0x100000001b3;
  }
  return hash.toUnsigned(64).toRadixString(16).padLeft(16, '0');
}

Uint8List encodeVector(Float32List values) {
  final data = ByteData(values.length * 4);
  for (var i = 0; i < values.length; i++) {
    data.setFloat32(i * 4, values[i], Endian.little);
  }
  return data.buffer.asUint8List();
}

Float32List decodeVector(Uint8List bytes) {
  final data = ByteData.sublistView(bytes);
  final values = Float32List(bytes.lengthInBytes ~/ 4);
  for (var i = 0; i < values.length; i++) {
    values[i] = data.getFloat32(i * 4, Endian.little);
  }
  return values;
}

int _byScore(KnowledgeHit a, KnowledgeHit b) {
  final byScore = b.score.compareTo(a.score);
  if (byScore != 0) return byScore;
  final byName = a.card.names['en']!.toLowerCase().compareTo(
    b.card.names['en']!.toLowerCase(),
  );
  return byName != 0 ? byName : a.card.id.compareTo(b.card.id);
}

final _stopWords =
    ('a an and any are at be by can do does for from how i in is it its me '
            'my of on or our that the there this to what when where which who '
            'why with you your')
        .split(' ')
        .toSet();

final _word = RegExp(r'[\p{L}\p{M}\p{N}]+', unicode: true);

List<String> _words(String text) => [
  for (final match in _word.allMatches(text.toLowerCase())) match[0]!,
];

/// Light English plural folding so "cockroaches" finds "cockroach".
String _stem(String token) {
  if (!RegExp(r'^[a-z]+$').hasMatch(token)) return token;
  if (token.length > 4 && token.endsWith('ies')) {
    return '${token.substring(0, token.length - 3)}y';
  }
  if (token.length > 4 && RegExp(r'(s|x|z|ch|sh)es$').hasMatch(token)) {
    return token.substring(0, token.length - 2);
  }
  if (token.length > 3 && token.endsWith('s') && !token.endsWith('ss')) {
    return token.substring(0, token.length - 1);
  }
  return token;
}

/// Keyword fallback: each query word (lower-cased, plural-folded, stop
/// words dropped) scores the best field whose words start with it — any
/// name 3, a sign 2, the summary 1. A card's score is the sum over the
/// query words divided by `3 × words`, so 0..1. Cards scoring 0 are left
/// out. Ties go by English name, then id.
List<KnowledgeHit> keywordSearch(
  String query,
  List<KnowledgeCard> cards, {
  int limit = 3,
}) {
  if (limit <= 0) return const [];
  final tokens = {
    for (final word in _words(query))
      if (word.runes.length >= 2 && !_stopWords.contains(word)) _stem(word),
  }.toList();
  if (tokens.isEmpty) return const [];
  final hits = <KnowledgeHit>[];
  for (final card in cards) {
    final nameWords = _words(card.names.values.join(' '));
    final signWords = _words(card.signs.join(' '));
    final summaryWords = _words(card.summary);
    bool hit(List<String> words, String token) =>
        words.any((w) => w.startsWith(token));
    var total = 0;
    for (final token in tokens) {
      if (hit(nameWords, token)) {
        total += 3;
      } else if (hit(signWords, token)) {
        total += 2;
      } else if (hit(summaryWords, token)) {
        total += 1;
      }
    }
    if (total > 0) {
      hits.add(KnowledgeHit(card: card, score: total / (3 * tokens.length)));
    }
  }
  hits.sort(_byScore);
  return List.unmodifiable(hits.take(limit));
}
