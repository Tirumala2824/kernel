import 'package:flutter_test/flutter_test.dart';
import 'package:kernel_contracts/kernel_contracts.dart';

import 'support/harness.dart';

void main() {
  late Harness h;

  setUp(() async => h = await Harness.create());
  tearDown(() => h.dispose());

  test('activeRole is null until set, then streams changes', () async {
    final stream = h.ops.settings.watchActiveRole();
    expect(await stream.first, isNull);

    await h.ops.settings.setActiveRole(Role.storageFpo);
    expect(await firstWhere(stream, (r) => r != null), Role.storageFpo);

    await h.ops.settings.setActiveRole(Role.buyer);
    expect(await firstWhere(stream, (r) => r == Role.buyer), Role.buyer);
  });

  test(
    'v2 settings have their defaults on a fresh install, with no rows',
    () async {
      final s = h.ops.settings;
      expect(await s.watchResearchModeOptIn().first, isFalse);
      expect(await s.watchLanguageTag().first, isNull);
      expect(await s.watchHaptics().first, isTrue);
      expect(await s.watchVoicePrompts().first, isFalse);
      expect(await s.watchOnboardingDone().first, isFalse);
      expect(await s.watchRetainAudioOptIn().first, isFalse);
      expect(await s.watchActiveRole().first, isNull);
    },
  );

  test(
    'v2 settings can be changed and are independent of each other',
    () async {
      final s = h.ops.settings;
      final research = s.watchResearchModeOptIn();
      await s.setResearchModeOptIn(true);
      expect(await firstWhere(research, (v) => v), isTrue);
      expect(
        await s.watchRetainAudioOptIn().first,
        isFalse,
        reason: 'research mode is a separate opt-in',
      );

      final haptics = s.watchHaptics();
      await s.setHaptics(false);
      expect(await firstWhere(haptics, (v) => !v), isFalse);
      await s.setHaptics(true);
      expect(await firstWhere(haptics, (v) => v), isTrue);

      await s.setVoicePrompts(true);
      expect(await s.watchVoicePrompts().first, isTrue);
      await s.setOnboardingDone(true);
      expect(await s.watchOnboardingDone().first, isTrue);

      final language = s.watchLanguageTag();
      await s.setLanguageTag(' hi ');
      expect(await firstWhere(language, (v) => v != null), 'hi');
      await s.setLanguageTag('ta');
      expect(await firstWhere(language, (v) => v == 'ta'), 'ta');
      // Null or blank goes back to following the device.
      await s.setLanguageTag(null);
      expect(await firstWhere(language, (v) => v == null), isNull);
      await s.setLanguageTag('bn');
      await s.setLanguageTag('  ');
      expect(await s.watchLanguageTag().first, isNull);

      expect(await s.watchResearchModeOptIn().first, isTrue);
      await s.setResearchModeOptIn(false);
      expect(await s.watchResearchModeOptIn().first, isFalse);
    },
  );

  test('retainAudioOptIn defaults to false and can be toggled', () async {
    final stream = h.ops.settings.watchRetainAudioOptIn();
    expect(await stream.first, isFalse);

    await h.ops.settings.setRetainAudioOptIn(true);
    expect(await firstWhere(stream, (v) => v), isTrue);

    await h.ops.settings.setRetainAudioOptIn(false);
    expect(await firstWhere(stream, (v) => !v), isFalse);
  });

  test('switching role never deletes records', () async {
    await h.ops.settings.setActiveRole(Role.farmer);
    final sack = await h.addItem(role: Role.farmer, label: 'Sack');
    final bag = await h.addItem(role: Role.buyer, label: 'Sample bag');
    final tin = await h.addItem(role: Role.household, label: 'Tin');
    await h.recordScan(sack.id);
    await h.recordScan(bag.id);
    await h.ops.inspections.create(
      InspectionDraft(
        itemId: bag.id,
        inspectedAt: DateTime.utc(2026, 10, 1),
        inspector: 'Buyer QA',
        observations: '',
        verifiedFinding: VerifiedFinding.noneFound,
      ),
    );
    await h.ops.reminders.schedule(
      tin.id,
      h.clock.now.add(const Duration(days: 7)),
    );

    for (final role in [
      Role.buyer,
      Role.household,
      Role.storageFpo,
      Role.farmer,
    ]) {
      await h.ops.settings.setActiveRole(role);
    }

    expect(await h.ops.settings.watchActiveRole().first, Role.farmer);
    expect(
      (await h.ops.items.watchByRole(Role.farmer).first).single.id,
      sack.id,
    );
    expect((await h.ops.items.watchByRole(Role.buyer).first).single.id, bag.id);
    expect(
      (await h.ops.items.watchByRole(Role.household).first).single.id,
      tin.id,
    );
    expect(await h.ops.scans.watchRecent().first, hasLength(2));
    expect(await h.ops.inspections.watchForItem(bag.id).first, hasLength(1));
    expect(await h.ops.reminders.watchUpcoming().first, hasLength(1));
  });
}
