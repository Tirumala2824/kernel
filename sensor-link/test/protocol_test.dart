import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:sensor_link/sensor_link.dart';

import 'vectors.dart';

void main() {
  final doc = loadJson('protocol_v1.json');
  final cases = (doc['cases'] as List).cast<Map<String, dynamic>>();

  test('UUIDs and lengths match the spec', () {
    expect(SensorUuids.service, doc['serviceUuid']);
    final ch = doc['characteristics'] as Map<String, dynamic>;
    expect(SensorUuids.deviceInfo, ch['deviceInfo']);
    expect(SensorUuids.config, ch['config']);
    expect(SensorUuids.bandTable, ch['bandTable']);
    expect(SensorUuids.bandFrame, ch['bandFrame']);
    expect(SensorUuids.event, ch['event']);
    expect(SensorUuids.status, ch['status']);
    expect(SensorUuids.controlPoint, ch['controlPoint']);
    expect(SensorUuids.snippet, ch['snippet']);
    final len = doc['lengths'] as Map<String, dynamic>;
    expect(len['event'], WireLengths.event);
    expect(len['status'], WireLengths.status);
    expect(len['config'], WireLengths.config);
    expect(len['deviceInfo'], WireLengths.deviceInfo);
    expect(len['bandFrameHeader'], WireLengths.bandFrameHeader);
    expect(len['adv'], WireLengths.adv);
  });

  group('fixtures round-trip', () {
    for (final c in cases) {
      test(c['name'], () {
        final bytes = hex(c['hex'] as String);
        final f = c['fields'] as Map<String, dynamic>;
        late final List<int> again;
        switch (c['kind']) {
          case 'adv':
            final v = WireAdv.decode(bytes);
            expect(v.toFields(), f);
            again = v.encode();
          case 'deviceInfo':
            final v = WireDeviceInfo.decode(bytes);
            expect(v.toFields(), f);
            again = v.encode();
          case 'config':
            final v = WireConfig.decode(bytes);
            expect(v.toFields(), f);
            expect(v.isValid, isTrue);
            again = v.encode();
          case 'bandTable':
            final v = WireBandTable.decode(bytes);
            expect(v.toFields(), f);
            again = v.encode();
          case 'bandFrame':
            final v = WireBandFrame.decode(bytes);
            expect(v.toFields(), f);
            again = v.encode();
          case 'event':
            final v = WireEvent.decode(bytes);
            expect(v.toFields(), f);
            again = v.encode();
          case 'status':
            final v = WireStatus.decode(bytes);
            expect(v.toFields(), f);
            again = v.encode();
          case 'cpRequest':
            again = switch (f['opcode'] as int) {
              WireOp.setTime => CpRequest.setTime(f['epochMs'] as int),
              WireOp.getEventsSince => CpRequest.getEventsSince(f['seq'] as int, maxCount: f['maxCount'] as int),
              WireOp.startSurvey => CpRequest.startSurvey(f['durationS'] as int),
              WireOp.startSession => CpRequest.startSession(f['flags'] as int),
              WireOp.stopSession => CpRequest.stopSession(),
              WireOp.requestSnippet => CpRequest.requestSnippet(f['seq'] as int),
              WireOp.clearBond => CpRequest.clearBond(),
              WireOp.authChallenge => CpRequest.authChallenge(hex(f['nonceHex'] as String)),
              WireOp.authResponse => CpRequest.authResponse(hex(f['proofHex'] as String)),
              _ => throw StateError('opcode'),
            };
          case 'cpResponse':
            final r = CpIndication.decode(bytes) as CpResponse;
            expect(r.reqOpcode, f['reqOpcode']);
            expect(r.status, f['status']);
            expect(toHex(r.payload), f['payloadHex']);
            if (r.reqOpcode == WireOp.getEventsSince && r.payload.isNotEmpty) {
              final p = EventsSincePayload.decode(r.payload);
              expect([p.count, p.firstSeq, p.lastSeq, p.oldestSeq], [f['count'], f['firstSeq'], f['lastSeq'], f['oldestSeq']]);
            }
            if (r.reqOpcode == WireOp.authChallenge) {
              final p = AuthChallengePayload.decode(r.payload);
              expect(toHex(p.nodeNonce), f['nodeNonceHex']);
              expect(toHex(p.nodeProof), f['nodeProofHex']);
            }
            if (r.reqOpcode == WireOp.requestSnippet) {
              final m = SnippetMeta.decode(r.payload).toFields();
              for (final k in m.keys) {
                expect(m[k], f[k], reason: k);
              }
            }
            again = r.encode();
          case 'eventsDone':
            final d = CpIndication.decode(bytes) as CpEventsDone;
            expect([d.count, d.lastSeq], [f['count'], f['lastSeq']]);
            again = d.encode();
          case 'snippetTile':
            final t = SnippetTile.decode(bytes);
            expect([t.eventSeq, t.tileIndex, t.tileCount, t.col0, t.nCols], [f['eventSeq'], f['tileIndex'], f['tileCount'], f['col0'], f['nCols']]);
            expect(toHex(t.data), f['dataHex']);
            again = t.encode();
          default:
            fail('unknown kind ${c['kind']}');
        }
        expect(toHex(again), c['hex']);
      });
    }
  });

  group('detector vectors decode', () {
    for (final file in detectFiles()) {
      test(file.uri.pathSegments.last, () {
        final v = loadFile(file);
        for (final e in (v['events'] as List).cast<Map<String, dynamic>>()) {
          final w = WireEvent.decode(hex(e['hex'] as String));
          final expected = Map.of(e)
            ..remove('hex')
            ..remove('className');
          expect(w.toFields(), expected);
          expect(toHex(w.encode()), e['hex']);
        }
      });
    }
  });

  test('short payloads are rejected, trailing bytes ignored', () {
    final ev = WireEvent.decode(hex(cases.firstWhere((c) => c['kind'] == 'event')['hex'] as String));
    final longer = [...ev.encode(), 1, 2, 3];
    expect(WireEvent.decode(Uint8List.fromList(longer)).toFields(), ev.toFields());
    expect(() => WireEvent.decode(ev.encode().sublist(0, 29)), throwsA(isA<ProtocolException>()));
    expect(() => WireStatus.decode(hex('00' * 20)), throwsA(isA<ProtocolException>()));
    expect(() => WireBandTable.decode(hex('0000')), throwsA(isA<ProtocolException>()));
    expect(() => CpIndication.decode(hex('42')), throwsA(isA<ProtocolException>()));
    expect(() => CpRequest.startSurvey(10), throwsArgumentError);
  });

  test('derived units', () {
    final ev = WireEvent.decode(hex(cases.firstWhere((c) => c['name'] == 'event_untimed_saturated')['hex'] as String));
    expect(ev.timeValid, isFalse);
    expect(ev.ipiCv, isNull);
    expect(ev.peakHz, 655350.0);
    expect(ev.slopeHzPerMs, -3276.7);
    expect(ev.snrDb, 127.5);
  });
}
