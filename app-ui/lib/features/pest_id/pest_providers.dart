import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kernel_contracts/kernel_contracts.dart';

import '../../app/providers.dart';

// Reactive read models for Pest & Animal ID. Every list on screen comes
// from these; nothing is hard-coded.

/// Live Stage-0/1 camera candidates while the preview runs.
final cameraCandidatesProvider =
    StreamProvider.autoDispose<List<SignalCandidate>>(
      (ref) => ref.watch(pestSenseEngineProvider).cameraCandidates(),
      name: 'cameraCandidatesProvider',
    );

/// Every curated knowledge card, read fresh (never a stale cache). An
/// unavailable service reads as "no cards" so the flow still works.
Future<List<KnowledgeCard>> loadKnowledgeCards(KnowledgeService service) async {
  try {
    return await service.all();
  } on Object catch (error) {
    debugPrint('Kernel: knowledge cards unavailable: $error');
    return const [];
  }
}

/// Every curated knowledge card, for display (names, pickers).
final knowledgeCardsProvider = FutureProvider.autoDispose<List<KnowledgeCard>>(
  (ref) => loadKnowledgeCards(ref.watch(knowledgeServiceProvider)),
  name: 'knowledgeCardsProvider',
);

final knowledgeCardProvider = FutureProvider.autoDispose
    .family<KnowledgeCard?, String>((ref, id) async {
      final cards = await ref.watch(knowledgeCardsProvider.future);
      for (final card in cards) {
        if (card.id == id) return card;
      }
      try {
        return await ref.watch(knowledgeServiceProvider).get(id);
      } on Object {
        return null;
      }
    });

/// Distance support on this phone (ARCore depth or AF focus distance).
final distanceCapabilityProvider =
    FutureProvider.autoDispose<DistanceCapability>((ref) async {
      try {
        return await ref.watch(pestSenseEngineProvider).distanceCapability();
      } on Object {
        return const DistanceCapability(
          arcoreDepth: false,
          focusDistance: false,
        );
      }
    }, name: 'distanceCapabilityProvider');

/// Newest first for one role (all roles when null).
final recentSightingsProvider = StreamProvider.autoDispose
    .family<List<Sighting>, Role?>(
      (ref, role) =>
          ref.watch(sightingRepositoryProvider).watchRecent(role: role),
    );

/// One sighting; re-read whenever the recent list changes (e.g. after the
/// verified finding is recorded).
final sightingProvider = FutureProvider.autoDispose.family<Sighting?, String>((
  ref,
  id,
) async {
  final recent = await ref.watch(recentSightingsProvider(null).future);
  for (final s in recent) {
    if (s.id == id) return s;
  }
  return ref.watch(sightingRepositoryProvider).get(id);
});

final mapsConsentProvider = StreamProvider<bool>(
  (ref) => ref.watch(settingsRepositoryProvider).watchMapsConsent(),
  name: 'mapsConsentProvider',
);

final keepSightingMediaProvider = StreamProvider<bool>(
  (ref) => ref.watch(settingsRepositoryProvider).watchKeepSightingMedia(),
  name: 'keepSightingMediaProvider',
);
