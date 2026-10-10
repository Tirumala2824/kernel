import 'package:data_operations/src/services/ranking_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kernel_contracts/kernel_contracts.dart';

import 'support/harness.dart';

void main() {
  late Harness h;
  late DateTime now;

  setUp(() async {
    h = await Harness.create();
    now = h.clock.now;
  });
  tearDown(() => h.dispose());

  Future<InspectionQueue> queue({Classification? result, Duration? maxAge}) =>
      h.ops.ranking.watchQueue(result: result, maxAge: maxAge).first;

  DateTime ago({int days = 0, int hours = 0}) =>
      now.subtract(Duration(days: days, hours: hours));

  test('ageDays is the whole days since the latest valid scan', () async {
    final a = await h.addItem(label: 'A');
    final b = await h.addItem(label: 'B');
    await h.recordScanAt(
      a.id,
      ago(days: 3, hours: 2),
      classification: Classification.clean,
    );
    await h.recordScanAt(
      b.id,
      ago(hours: 1),
      classification: Classification.clean,
    );
    final q = await queue();
    expect(
      [for (final e in q.ranked) (e.item.id, e.ageDays)],
      [(a.id, 3), (b.id, 0)],
    );
    expect(q.ranked.first.reason, RankReason.clean);
  });

  test('result keeps only ranked entries of that class; the model version '
      'and needsScan are unchanged', () async {
    final infested = await h.addItem(label: 'I');
    final uncertain = await h.addItem(label: 'U');
    final clean = await h.addItem(label: 'C');
    final unscanned = await h.addItem(label: 'N');
    final otherModel = await h.addItem(label: 'O');
    await h.recordModelScan(infested.id, Classification.infested);
    await h.recordModelScan(uncertain.id, Classification.uncertain);
    await h.recordModelScan(clean.id, Classification.clean);
    await h.recordModelScan(
      otherModel.id,
      Classification.infested,
      modelVersion: 'test-model-0',
    );

    final all = await queue();
    expect(all.ranked.map((e) => e.item.id), [
      infested.id,
      uncertain.id,
      clean.id,
    ]);
    final onlyInfested = await queue(result: Classification.infested);
    expect(onlyInfested.ranked.map((e) => e.item.id), [infested.id]);
    expect(onlyInfested.ranked.single.reason, RankReason.infested);
    expect(onlyInfested.modelVersion, 'test-model-1');
    // The other model's infested scan is still not comparable.
    expect(onlyInfested.needsScan.map((i) => i.id), [
      unscanned.id,
      otherModel.id,
    ]);
    expect(
      (await queue(result: Classification.uncertain)).ranked.single.item.id,
      uncertain.id,
    );

    final none = await queue(result: Classification.notEvaluated);
    expect(none.ranked, isEmpty);
    expect(none.modelVersion, isNull);
    expect(none.needsScan, hasLength(2));
  });

  test('maxAge moves items whose latest valid scan is older into needsScan, '
      'in input order', () async {
    final a = await h.addItem(label: 'A');
    final b = await h.addItem(label: 'B');
    final c = await h.addItem(label: 'C');
    await h.recordScanAt(
      a.id,
      ago(days: 10),
      classification: Classification.infested,
    );
    await h.recordScanAt(
      b.id,
      ago(days: 1),
      classification: Classification.clean,
    );
    await h.recordScanAt(
      c.id,
      ago(days: 7),
      classification: Classification.uncertain,
    );

    final q = await queue(maxAge: const Duration(days: 7));
    expect(q.ranked.map((e) => e.item.id), [c.id, b.id]);
    expect(q.needsScan.map((i) => i.id), [a.id]);

    final combined = await queue(
      maxAge: const Duration(days: 7),
      result: Classification.clean,
    );
    expect(combined.ranked.map((e) => e.item.id), [b.id]);
    expect(combined.needsScan.map((i) => i.id), [a.id]);

    // Measured from the injected clock.
    h.clock.advance(const Duration(days: 1));
    final later = await queue(maxAge: const Duration(days: 7));
    expect(later.ranked.map((e) => e.item.id), [b.id]);
    expect(later.needsScan.map((i) => i.id), [a.id, c.id]);
    expect(later.ranked.single.ageDays, 2);
  });

  test(
    'with maxAge only fresh scans choose the common model version',
    () async {
      final a = await h.addItem(label: 'A');
      final b = await h.addItem(label: 'B');
      final c = await h.addItem(label: 'C');
      for (final item in [a, b]) {
        await h.recordScanAt(
          item.id,
          ago(days: 20),
          classification: Classification.clean,
          modelVersion: 'model-v1',
        );
      }
      await h.recordScanAt(
        c.id,
        ago(days: 1),
        classification: Classification.clean,
        modelVersion: 'model-v2',
      );

      final all = await queue();
      expect(all.modelVersion, 'model-v1');
      expect(all.needsScan.map((i) => i.id), [c.id]);

      final fresh = await queue(maxAge: const Duration(days: 14));
      expect(fresh.modelVersion, 'model-v2');
      expect(fresh.ranked.single.item.id, c.id);
      expect(fresh.needsScan.map((i) => i.id), [a.id, b.id]);
    },
  );

  test('the pure rule needs now for maxAge and leaves ageDays null without '
      'it', () async {
    final item = await h.addItem();
    final scan = await h.recordModelScan(item.id, Classification.clean);
    expect(
      () => rankQueue([item], {item.id: scan}, maxAge: const Duration(days: 1)),
      throwsArgumentError,
    );
    final q = rankQueue([item], {item.id: scan});
    expect(q.ranked.single.ageDays, isNull);
    expect(wholeDaysBetween(now.add(const Duration(hours: 5)), now), 0);
  });
}
