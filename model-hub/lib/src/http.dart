import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'store.dart';

class HubHttpResponse {
  HubHttpResponse({
    required this.status,
    required Map<String, String> headers,
    required this.body,
  }) : headers = {
         for (final e in headers.entries) e.key.toLowerCase(): e.value,
       };

  final int status;

  /// Lower-case header names.
  final Map<String, String> headers;
  final String body;

  String? header(String name) => headers[name.toLowerCase()];
}

/// GET-only transport for catalog metadata. Model files are downloaded by
/// the Kotlin jobs, never through this.
abstract interface class HubHttp {
  Future<HubHttpResponse> get(Uri uri, {Map<String, String> headers});
}

class HubHttpRefused implements Exception {
  HubHttpRefused(this.uri);

  final Uri uri;

  @override
  String toString() => 'HubHttpRefused(${uri.host})';
}

/// dart:io transport, restricted to the catalog hosts of guardrails §7:
/// raw.githubusercontent.com (Gallery allowlist) and huggingface.co (API).
/// https only, no redirects, bounded body size and time.
class IoHubHttp implements HubHttp {
  IoHubHttp({HttpClient? client})
    : _client = client ?? HttpClient()
        ..connectionTimeout = const Duration(seconds: 15)
        ..idleTimeout = const Duration(seconds: 10)
        ..userAgent = userAgent;

  static const userAgent = 'kernel-model-hub/0.1';
  static const allowedHosts = {'raw.githubusercontent.com', 'huggingface.co'};
  static const maxBodyBytes = 4 * 1024 * 1024;
  static const timeout = Duration(seconds: 30);

  final HttpClient _client;

  static bool allows(Uri uri) =>
      uri.scheme == 'https' && allowedHosts.contains(uri.host.toLowerCase());

  @override
  Future<HubHttpResponse> get(
    Uri uri, {
    Map<String, String> headers = const {},
  }) async {
    if (!allows(uri)) throw HubHttpRefused(uri);
    return _get(uri, headers).timeout(timeout);
  }

  Future<HubHttpResponse> _get(Uri uri, Map<String, String> headers) async {
    final req = await _client.getUrl(uri);
    req.followRedirects = false;
    req.headers.set(HttpHeaders.acceptHeader, 'application/json');
    headers.forEach(req.headers.set);
    final res = await req.close();
    final out = <String, String>{};
    res.headers.forEach((name, values) => out[name] = values.join(', '));
    final bytes = <int>[];
    await for (final chunk in res) {
      bytes.addAll(chunk);
      if (bytes.length > maxBodyBytes) {
        throw const HttpException('catalog response too large');
      }
    }
    return HubHttpResponse(
      status: res.statusCode,
      headers: out,
      body: utf8.decode(bytes, allowMalformed: true),
    );
  }

  void close() => _client.close(force: true);
}

/// Respects the anonymous HF limits (about 500 API calls per 5 minutes per
/// IP): a local budget well below that, and a persisted back-off after any
/// 429 (Retry-After, else the RateLimit `t=` reset, else 5 minutes).
class RateGate {
  RateGate(
    this._store, {
    DateTime Function()? clock,
    this.budgetPerWindow = 100,
    this.window = const Duration(minutes: 5),
  }) : _clock = clock ?? DateTime.now;

  static const _file = 'rate_gate.json';

  final HubStore _store;
  final DateTime Function() _clock;
  final int budgetPerWindow;
  final Duration window;
  final Map<String, List<DateTime>> _calls = {};
  Map<String, DateTime>? _blockedUntil;

  Future<Map<String, DateTime>> _blocked() async {
    final cached = _blockedUntil;
    if (cached != null) return cached;
    final json = await _store.readJson(_file);
    final out = <String, DateTime>{};
    if (json != null) {
      json.forEach((host, v) {
        final t = v is int ? DateTime.fromMillisecondsSinceEpoch(v) : null;
        if (t != null) out[host] = t;
      });
    }
    return _blockedUntil = out;
  }

  Future<bool> allows(String host) async {
    final now = _clock();
    final until = (await _blocked())[host];
    if (until != null && now.isBefore(until)) return false;
    final calls = _calls[host] ?? const [];
    final recent = calls.where((t) => now.difference(t) < window).length;
    return recent < budgetPerWindow;
  }

  void record(String host) {
    final now = _clock();
    final list = _calls.putIfAbsent(host, () => []);
    list.removeWhere((t) => now.difference(t) >= window);
    list.add(now);
  }

  Future<void> onResponse(String host, HubHttpResponse r) async {
    if (r.status != 429) return;
    final wait = _retryAfter(r) ?? const Duration(minutes: 5);
    final clamped = wait < const Duration(minutes: 1)
        ? const Duration(minutes: 1)
        : wait;
    final blocked = await _blocked();
    blocked[host] = _clock().add(clamped);
    await _store.writeJson(_file, {
      for (final e in blocked.entries) e.key: e.value.millisecondsSinceEpoch,
    });
  }

  static Duration? _retryAfter(HubHttpResponse r) {
    final ra = int.tryParse(r.header('retry-after')?.trim() ?? '');
    if (ra != null) return Duration(seconds: ra);
    final rl = r.header('ratelimit');
    if (rl != null) {
      final m = RegExp(r't=(\d+)').firstMatch(rl);
      final t = int.tryParse(m?.group(1) ?? '');
      if (t != null) return Duration(seconds: t);
    }
    return null;
  }
}

/// Catalog network access: the transport plus the rate gate. Callers decide
/// beforehand whether network is allowed at all (consent and Wi-Fi rule).
class CatalogNetwork {
  CatalogNetwork(this._http, this.gate);

  final HubHttp _http;
  final RateGate gate;

  /// Null when refused, rate-limited or failed (callers fall back to cache).
  Future<HubHttpResponse?> get(
    Uri uri, {
    Map<String, String> headers = const {},
  }) async {
    if (!await gate.allows(uri.host)) return null;
    gate.record(uri.host);
    try {
      final r = await _http.get(uri, headers: headers);
      await gate.onResponse(uri.host, r);
      return r;
    } on Object {
      return null;
    }
  }
}
