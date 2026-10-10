// Wire codec for docs/sensor-protocol.md v1 (little-endian, packed).
// Mirrors SensorProtocol.kt and firmware/components/kernel_proto; all are
// tested against firmware/reference/vectors/protocol_v1.json.
import 'dart:typed_data';

class ProtocolException implements Exception {
  ProtocolException(this.message);
  final String message;
  @override
  String toString() => 'ProtocolException: $message';
}

abstract final class SensorUuids {
  static const _suffix = '-4139-44b2-877d-c537908d6290';
  static String of(int short) => 'c778${short.toRadixString(16).padLeft(4, '0')}$_suffix';
  static final service = of(0x0001);
  static final deviceInfo = of(0x0002);
  static final config = of(0x0003);
  static final bandTable = of(0x0004);
  static final bandFrame = of(0x0005);
  static final event = of(0x0006);
  static final status = of(0x0007);
  static final controlPoint = of(0x0008);
  static final snippet = of(0x0009);
}

abstract final class WireLengths {
  static const protoMajor = 1;
  static const protoMinor = 0;
  static const cfgVersion = 1;
  static const adv = 7;
  static const deviceInfo = 22;
  static const config = 32;
  static const event = 30;
  static const status = 21;
  static const bandFrameHeader = 23;
  static const snippetMeta = 14;
  static const snippetTileHeader = 8;
  static const maxBands = 24;
}

abstract final class WireOp {
  static const setTime = 0x01;
  static const getEventsSince = 0x02;
  static const startSurvey = 0x03;
  static const startSession = 0x04;
  static const stopSession = 0x05;
  static const requestSnippet = 0x06;
  static const clearBond = 0x07;
  static const authChallenge = 0x10;
  static const authResponse = 0x11;
  static const response = 0x80;
  static const eventsDone = 0x81;
}

abstract final class WireCpStatus {
  static const ok = 0x00;
  static const unknownOpcode = 0x01;
  static const invalidParam = 0x02;
  static const notAuthenticated = 0x03;
  static const authFailed = 0x04;
  static const busy = 0x05;
  static const notAvailable = 0x06;
  static const storageError = 0x07;
}

/// Status.health bits (section 4.6).
abstract final class HealthBits {
  static const jammed = 1 << 0;
  static const clipped = 1 << 1;
  static const lowBattery = 1 << 2;
  static const surveyNeeded = 1 << 3;
  static const surveyActive = 1 << 4;
  static const sessionActive = 1 << 5;
  static const timeValid = 1 << 6;
  static const authenticated = 1 << 7;
  static const warmingUp = 1 << 8;
  static const sensorFault = 1 << 9;
  static const eventsOverwritten = 1 << 10;
}

abstract final class EventFlags {
  static const timeValid = 0x01;
  static const regularTrain = 0x02;
  static const truncated = 0x04;
  static const snippet = 0x08;
}

abstract final class BandFrameFlags {
  static const timeValid = 0x01;
  static const jammed = 0x02;
  static const clipped = 0x04;
  static const surveyActive = 0x08;
  static const warmingUp = 0x10;
}

class _Reader {
  _Reader(Uint8List b, String what)
      : _b = b,
        _d = ByteData.sublistView(b),
        _what = what;
  final Uint8List _b;
  final ByteData _d;
  final String _what;
  int _pos = 0;

  int get remaining => _b.length - _pos;

  void _need(int n) {
    if (_pos + n > _b.length) throw ProtocolException('$_what: truncated at $_pos');
  }

  int u8() {
    _need(1);
    return _d.getUint8(_pos++);
  }

  int i8() {
    _need(1);
    return _d.getInt8(_pos++);
  }

  int u16() {
    _need(2);
    final v = _d.getUint16(_pos, Endian.little);
    _pos += 2;
    return v;
  }

  int i16() {
    _need(2);
    final v = _d.getInt16(_pos, Endian.little);
    _pos += 2;
    return v;
  }

  int u24() => u16() | (u8() << 16);

  int u32() {
    _need(4);
    final v = _d.getUint32(_pos, Endian.little);
    _pos += 4;
    return v;
  }

  int u64() {
    final lo = u32();
    return lo | (u32() << 32);
  }

  Uint8List bytes(int n) {
    _need(n);
    final out = Uint8List.fromList(_b.sublist(_pos, _pos + n));
    _pos += n;
    return out;
  }

  Uint8List rest() => bytes(remaining);
}

class _Writer {
  _Writer(int size)
      : _b = Uint8List(size),
        _d = ByteData(0) {
    _d = ByteData.sublistView(_b);
  }
  final Uint8List _b;
  ByteData _d;
  int _pos = 0;

  void u8(int v) => _d.setUint8(_pos++, v & 0xFF);
  void u16(int v) {
    _d.setUint16(_pos, v & 0xFFFF, Endian.little);
    _pos += 2;
  }

  void u24(int v) {
    u16(v & 0xFFFF);
    u8((v >> 16) & 0xFF);
  }

  void u32(int v) {
    _d.setUint32(_pos, v & 0xFFFFFFFF, Endian.little);
    _pos += 4;
  }

  void u64(int v) {
    u32(v & 0xFFFFFFFF);
    u32((v >> 32) & 0xFFFFFFFF);
  }

  void bytes(List<int> v) {
    _b.setRange(_pos, _pos + v.length, v);
    _pos += v.length;
  }

  Uint8List build() {
    if (_pos != _b.length) throw StateError('wrote $_pos of ${_b.length}');
    return _b;
  }
}

void _min(Uint8List b, int n, String what) {
  if (b.length < n) throw ProtocolException('$what: ${b.length} < $n bytes');
}

class WireAdv {
  const WireAdv({
    required this.companyId,
    required this.proto,
    required this.sensorType,
    required this.lastEventSeq16,
    required this.batt,
  });

  final int companyId;
  final int proto;
  final int sensorType;
  final int lastEventSeq16;
  final int batt;

  /// [b] starts at the company id.
  factory WireAdv.decode(Uint8List b) {
    _min(b, WireLengths.adv, 'adv');
    final r = _Reader(b, 'adv');
    return WireAdv(companyId: r.u16(), proto: r.u8(), sensorType: r.u8(), lastEventSeq16: r.u16(), batt: r.u8());
  }

  Uint8List encode() {
    final w = _Writer(WireLengths.adv)
      ..u16(companyId)
      ..u8(proto)
      ..u8(sensorType)
      ..u16(lastEventSeq16)
      ..u8(batt);
    return w.build();
  }

  Map<String, Object> toFields() => {
        'companyId': companyId,
        'proto': proto,
        'sensorType': sensorType,
        'lastEventSeq16': lastEventSeq16,
        'batt': batt,
      };
}

class WireDeviceInfo {
  const WireDeviceInfo({
    required this.protoMajor,
    required this.protoMinor,
    required this.sensorType,
    required this.hwRev,
    required this.fwMajor,
    required this.fwMinor,
    required this.fwPatch,
    required this.nBands,
    required this.capabilities,
    required this.sampleRateHz,
    required this.fftSize,
    required this.hopSize,
    required this.ringCapacity,
    required this.cfgVersion,
  });

  final int protoMajor;
  final int protoMinor;
  final int sensorType;
  final int hwRev;
  final int fwMajor;
  final int fwMinor;
  final int fwPatch;
  final int nBands;
  final int capabilities;
  final int sampleRateHz;
  final int fftSize;
  final int hopSize;
  final int ringCapacity;
  final int cfgVersion;

  String get firmwareVersion => '$fwMajor.$fwMinor.$fwPatch';

  factory WireDeviceInfo.decode(Uint8List b) {
    _min(b, WireLengths.deviceInfo, 'deviceInfo');
    final r = _Reader(b, 'deviceInfo');
    return WireDeviceInfo(
      protoMajor: r.u8(),
      protoMinor: r.u8(),
      sensorType: r.u8(),
      hwRev: r.u8(),
      fwMajor: r.u8(),
      fwMinor: r.u8(),
      fwPatch: r.u8(),
      nBands: r.u8(),
      capabilities: r.u16(),
      sampleRateHz: r.u32(),
      fftSize: r.u16(),
      hopSize: r.u16(),
      ringCapacity: r.u16(),
      cfgVersion: r.u8(),
    );
  }

  Uint8List encode() {
    final w = _Writer(WireLengths.deviceInfo)
      ..u8(protoMajor)
      ..u8(protoMinor)
      ..u8(sensorType)
      ..u8(hwRev)
      ..u8(fwMajor)
      ..u8(fwMinor)
      ..u8(fwPatch)
      ..u8(nBands)
      ..u16(capabilities)
      ..u32(sampleRateHz)
      ..u16(fftSize)
      ..u16(hopSize)
      ..u16(ringCapacity)
      ..u8(cfgVersion)
      ..u8(0);
    return w.build();
  }

  Map<String, Object> toFields() => {
        'protoMajor': protoMajor,
        'protoMinor': protoMinor,
        'sensorType': sensorType,
        'hwRev': hwRev,
        'fwMajor': fwMajor,
        'fwMinor': fwMinor,
        'fwPatch': fwPatch,
        'nBands': nBands,
        'capabilities': capabilities,
        'sampleRateHz': sampleRateHz,
        'fftSize': fftSize,
        'hopSize': hopSize,
        'ringCapacity': ringCapacity,
        'cfgVersion': cfgVersion,
      };
}

/// Config characteristic (section 4.2), in wire units.
class WireConfig {
  const WireConfig({
    required this.cfgVersion,
    required this.flags,
    required this.bandFrameMs,
    required this.dutyOnS,
    required this.dutyOffS,
    required this.detectThreshHalfDb,
    required this.jamThreshHalfDb,
    required this.jamHoldDs,
    required this.impulseThreshHalfDb,
    required this.minBlobMs,
    required this.maxGapMs,
    required this.flatMinMs,
    required this.contMinMs,
    required this.fmMinBwHz10,
    required this.burstMinImpulses,
    required this.trainMinPulses,
    required this.burstMaxGapMs,
    required this.impulseMinHalfMs,
    required this.impulseMaxMs,
    required this.trainMaxCvPct,
    required this.lowBattPct,
    required this.chirpMaxGapMs,
  });

  final int cfgVersion;
  final int flags;
  final int bandFrameMs;
  final int dutyOnS;
  final int dutyOffS;
  final int detectThreshHalfDb;
  final int jamThreshHalfDb;
  final int jamHoldDs;
  final int impulseThreshHalfDb;
  final int minBlobMs;
  final int maxGapMs;
  final int flatMinMs;
  final int contMinMs;
  final int fmMinBwHz10;
  final int burstMinImpulses;
  final int trainMinPulses;
  final int burstMaxGapMs;
  final int impulseMinHalfMs;
  final int impulseMaxMs;
  final int trainMaxCvPct;
  final int lowBattPct;
  final int chirpMaxGapMs;

  factory WireConfig.decode(Uint8List b) {
    _min(b, WireLengths.config, 'config');
    final r = _Reader(b, 'config');
    return WireConfig(
      cfgVersion: r.u8(),
      flags: r.u8(),
      bandFrameMs: r.u16(),
      dutyOnS: r.u16(),
      dutyOffS: r.u16(),
      detectThreshHalfDb: r.u8(),
      jamThreshHalfDb: r.u8(),
      jamHoldDs: r.u8(),
      impulseThreshHalfDb: r.u8(),
      minBlobMs: r.u8(),
      maxGapMs: r.u8(),
      flatMinMs: r.u16(),
      contMinMs: r.u16(),
      fmMinBwHz10: r.u16(),
      burstMinImpulses: r.u8(),
      trainMinPulses: r.u8(),
      burstMaxGapMs: r.u16(),
      impulseMinHalfMs: r.u8(),
      impulseMaxMs: r.u8(),
      trainMaxCvPct: r.u8(),
      lowBattPct: r.u8(),
      chirpMaxGapMs: r.u16(),
    );
  }

  Uint8List encode() {
    final w = _Writer(WireLengths.config)
      ..u8(cfgVersion)
      ..u8(flags)
      ..u16(bandFrameMs)
      ..u16(dutyOnS)
      ..u16(dutyOffS)
      ..u8(detectThreshHalfDb)
      ..u8(jamThreshHalfDb)
      ..u8(jamHoldDs)
      ..u8(impulseThreshHalfDb)
      ..u8(minBlobMs)
      ..u8(maxGapMs)
      ..u16(flatMinMs)
      ..u16(contMinMs)
      ..u16(fmMinBwHz10)
      ..u8(burstMinImpulses)
      ..u8(trainMinPulses)
      ..u16(burstMaxGapMs)
      ..u8(impulseMinHalfMs)
      ..u8(impulseMaxMs)
      ..u8(trainMaxCvPct)
      ..u8(lowBattPct)
      ..u16(chirpMaxGapMs)
      ..u16(0);
    return w.build();
  }

  bool get isValid {
    bool r(int v, int lo, int hi) => v >= lo && v <= hi;
    return cfgVersion == WireLengths.cfgVersion &&
        flags & 0x80 == 0 &&
        r(bandFrameMs, 100, 10000) &&
        r(dutyOnS, 10, 3600) &&
        r(dutyOffS, 0, 3600) &&
        r(detectThreshHalfDb, 12, 80) &&
        r(jamThreshHalfDb, 6, 60) &&
        r(jamHoldDs, 5, 250) &&
        r(impulseThreshHalfDb, 12, 80) &&
        r(minBlobMs, 1, 100) &&
        r(maxGapMs, 0, 50) &&
        r(flatMinMs, 50, 5000) &&
        r(contMinMs, 200, 10000) &&
        r(fmMinBwHz10, 10, 5000) &&
        r(burstMinImpulses, 2, 50) &&
        r(trainMinPulses, 3, 50) &&
        r(burstMaxGapMs, 10, 2000) &&
        r(impulseMinHalfMs, 1, 40) &&
        r(impulseMaxMs, 1, 100) &&
        impulseMinHalfMs <= 2 * impulseMaxMs &&
        r(trainMaxCvPct, 1, 100) &&
        r(lowBattPct, 5, 50) &&
        r(chirpMaxGapMs, 10, 1000);
  }

  Map<String, Object> toFields() => {
        'cfgVersion': cfgVersion,
        'flags': flags,
        'bandFrameMs': bandFrameMs,
        'dutyOnS': dutyOnS,
        'dutyOffS': dutyOffS,
        'detectThreshHalfDb': detectThreshHalfDb,
        'jamThreshHalfDb': jamThreshHalfDb,
        'jamHoldDs': jamHoldDs,
        'impulseThreshHalfDb': impulseThreshHalfDb,
        'minBlobMs': minBlobMs,
        'maxGapMs': maxGapMs,
        'flatMinMs': flatMinMs,
        'contMinMs': contMinMs,
        'fmMinBwHz10': fmMinBwHz10,
        'burstMinImpulses': burstMinImpulses,
        'trainMinPulses': trainMinPulses,
        'burstMaxGapMs': burstMaxGapMs,
        'impulseMinHalfMs': impulseMinHalfMs,
        'impulseMaxMs': impulseMaxMs,
        'trainMaxCvPct': trainMaxCvPct,
        'lowBattPct': lowBattPct,
        'chirpMaxGapMs': chirpMaxGapMs,
        'reserved': 0,
      };
}

class WireBandTable {
  WireBandTable(List<int> edgesHz10) : edgesHz10 = List.unmodifiable(edgesHz10);

  final List<int> edgesHz10;
  int get nBands => edgesHz10.length - 1;
  List<double> get edgesHz => [for (final e in edgesHz10) e * 10.0];

  factory WireBandTable.decode(Uint8List b) {
    _min(b, 2, 'bandTable');
    final r = _Reader(b, 'bandTable');
    final n = r.u8();
    r.u8();
    if (n < 1 || n > WireLengths.maxBands) throw ProtocolException('bandTable: nBands $n');
    final edges = [for (var i = 0; i <= n; i++) r.u16()];
    for (var i = 1; i < edges.length; i++) {
      if (edges[i] <= edges[i - 1]) throw ProtocolException('bandTable: edges not ascending');
    }
    return WireBandTable(edges);
  }

  Uint8List encode() {
    final w = _Writer(2 + 2 * edgesHz10.length)
      ..u8(nBands)
      ..u8(0);
    for (final e in edgesHz10) {
      w.u16(e);
    }
    return w.build();
  }

  Map<String, Object> toFields() => {'nBands': nBands, 'edgesHz10': edgesHz10};
}

class WireBandFrame {
  WireBandFrame({
    required this.seq,
    required this.tStartS,
    required this.tStartMs,
    required this.frameMs,
    required this.flags,
    required this.noiseFloorDeciDbfs,
    required this.peakHz10,
    required this.peakDeciDbfs,
    required this.jamBandMask,
    required List<int> bandsHalfDb,
  }) : bandsHalfDb = List.unmodifiable(bandsHalfDb);

  final int seq;
  final int tStartS;
  final int tStartMs;
  final int frameMs;
  final int flags;
  final int noiseFloorDeciDbfs;
  final int peakHz10;
  final int peakDeciDbfs;
  final int jamBandMask;
  final List<int> bandsHalfDb;

  int get nBands => bandsHalfDb.length;
  bool get timeValid => flags & BandFrameFlags.timeValid != 0;

  factory WireBandFrame.decode(Uint8List b) {
    _min(b, WireLengths.bandFrameHeader, 'bandFrame');
    final r = _Reader(b, 'bandFrame');
    final seq = r.u32();
    final ts = r.u32();
    final tms = r.u16();
    final frameMs = r.u16();
    final flags = r.u8();
    final n = r.u8();
    if (n < 1 || n > WireLengths.maxBands) throw ProtocolException('bandFrame: nBands $n');
    final floor = r.i16();
    final peakHz10 = r.u16();
    final peak = r.i16();
    final mask = r.u24();
    final bands = [for (var i = 0; i < n; i++) r.u8()];
    return WireBandFrame(
      seq: seq,
      tStartS: ts,
      tStartMs: tms,
      frameMs: frameMs,
      flags: flags,
      noiseFloorDeciDbfs: floor,
      peakHz10: peakHz10,
      peakDeciDbfs: peak,
      jamBandMask: mask,
      bandsHalfDb: bands,
    );
  }

  Uint8List encode() {
    final w = _Writer(WireLengths.bandFrameHeader + nBands)
      ..u32(seq)
      ..u32(tStartS)
      ..u16(tStartMs)
      ..u16(frameMs)
      ..u8(flags)
      ..u8(nBands)
      ..u16(noiseFloorDeciDbfs)
      ..u16(peakHz10)
      ..u16(peakDeciDbfs)
      ..u24(jamBandMask)
      ..bytes(bandsHalfDb);
    return w.build();
  }

  Map<String, Object> toFields() => {
        'seq': seq,
        'tStartS': tStartS,
        'tStartMs': tStartMs,
        'frameMs': frameMs,
        'flags': flags,
        'nBands': nBands,
        'noiseFloorDeciDbfs': noiseFloorDeciDbfs,
        'peakHz10': peakHz10,
        'peakDeciDbfs': peakDeciDbfs,
        'jamBandMask': jamBandMask,
        'bandsHalfDb': bandsHalfDb,
      };
}

class WireEvent {
  const WireEvent({
    required this.seq,
    required this.tStartS,
    required this.tStartMs,
    required this.durationMs,
    required this.eventClass,
    required this.flags,
    required this.peakHz10,
    required this.minHz10,
    required this.maxHz10,
    required this.slopeDHzPerMs,
    required this.snrHalfDb,
    required this.peakDbfs,
    required this.impulses,
    required this.harmonics,
    required this.repRateCHz,
    required this.ipiCvPct,
    required this.bootLow,
  });

  final int seq;
  final int tStartS;
  final int tStartMs;
  final int durationMs;
  final int eventClass;
  final int flags;
  final int peakHz10;
  final int minHz10;
  final int maxHz10;
  final int slopeDHzPerMs;
  final int snrHalfDb;
  final int peakDbfs;
  final int impulses;
  final int harmonics;
  final int repRateCHz;
  final int ipiCvPct;
  final int bootLow;

  bool get timeValid => flags & EventFlags.timeValid != 0;
  bool get regularTrain => flags & EventFlags.regularTrain != 0;
  double get peakHz => peakHz10 * 10.0;
  double get minHz => minHz10 * 10.0;
  double get maxHz => maxHz10 * 10.0;
  double get slopeHzPerMs => slopeDHzPerMs / 10.0;
  double get snrDb => snrHalfDb / 2.0;
  double get repRateHz => repRateCHz / 100.0;

  /// Inter-onset interval CV, or null when not applicable (wire 255).
  double? get ipiCv => ipiCvPct == 255 ? null : ipiCvPct / 100.0;

  factory WireEvent.decode(Uint8List b) {
    _min(b, WireLengths.event, 'event');
    final r = _Reader(b, 'event');
    return WireEvent(
      seq: r.u32(),
      tStartS: r.u32(),
      tStartMs: r.u16(),
      durationMs: r.u16(),
      eventClass: r.u8(),
      flags: r.u8(),
      peakHz10: r.u16(),
      minHz10: r.u16(),
      maxHz10: r.u16(),
      slopeDHzPerMs: r.i16(),
      snrHalfDb: r.u8(),
      peakDbfs: r.i8(),
      impulses: r.u8(),
      harmonics: r.u8(),
      repRateCHz: r.u16(),
      ipiCvPct: r.u8(),
      bootLow: r.u8(),
    );
  }

  Uint8List encode() {
    final w = _Writer(WireLengths.event)
      ..u32(seq)
      ..u32(tStartS)
      ..u16(tStartMs)
      ..u16(durationMs)
      ..u8(eventClass)
      ..u8(flags)
      ..u16(peakHz10)
      ..u16(minHz10)
      ..u16(maxHz10)
      ..u16(slopeDHzPerMs)
      ..u8(snrHalfDb)
      ..u8(peakDbfs)
      ..u8(impulses)
      ..u8(harmonics)
      ..u16(repRateCHz)
      ..u8(ipiCvPct)
      ..u8(bootLow);
    return w.build();
  }

  Map<String, Object> toFields() => {
        'seq': seq,
        'tStartS': tStartS,
        'tStartMs': tStartMs,
        'durationMs': durationMs,
        'eventClass': eventClass,
        'flags': flags,
        'peakHz10': peakHz10,
        'minHz10': minHz10,
        'maxHz10': maxHz10,
        'slopeDHzPerMs': slopeDHzPerMs,
        'snrHalfDb': snrHalfDb,
        'peakDbfs': peakDbfs,
        'impulses': impulses,
        'harmonics': harmonics,
        'repRateCHz': repRateCHz,
        'ipiCvPct': ipiCvPct,
        'bootLow': bootLow,
      };
}

class WireStatus {
  const WireStatus({
    required this.health,
    required this.battPct,
    required this.battMv,
    required this.lastSeq,
    required this.oldestSeq,
    required this.uptimeS,
    required this.bootCount,
    required this.surveyRemainingS,
  });

  final int health;
  final int battPct;
  final int battMv;
  final int lastSeq;
  final int oldestSeq;
  final int uptimeS;
  final int bootCount;
  final int surveyRemainingS;

  /// Battery percent, or null when the node reports 0xFF (unknown).
  int? get batteryPercent => battPct <= 100 ? battPct : null;

  factory WireStatus.decode(Uint8List b) {
    _min(b, WireLengths.status, 'status');
    final r = _Reader(b, 'status');
    return WireStatus(
      health: r.u16(),
      battPct: r.u8(),
      battMv: r.u16(),
      lastSeq: r.u32(),
      oldestSeq: r.u32(),
      uptimeS: r.u32(),
      bootCount: r.u16(),
      surveyRemainingS: r.u16(),
    );
  }

  Uint8List encode() {
    final w = _Writer(WireLengths.status)
      ..u16(health)
      ..u8(battPct)
      ..u16(battMv)
      ..u32(lastSeq)
      ..u32(oldestSeq)
      ..u32(uptimeS)
      ..u16(bootCount)
      ..u16(surveyRemainingS);
    return w.build();
  }

  Map<String, Object> toFields() => {
        'health': health,
        'battPct': battPct,
        'battMv': battMv,
        'lastSeq': lastSeq,
        'oldestSeq': oldestSeq,
        'uptimeS': uptimeS,
        'bootCount': bootCount,
        'surveyRemainingS': surveyRemainingS,
      };
}

/// ControlPoint request builders (section 4.7).
abstract final class CpRequest {
  static Uint8List setTime(int epochMs) => (_Writer(9)
        ..u8(WireOp.setTime)
        ..u64(epochMs))
      .build();

  static Uint8List getEventsSince(int seq, {int maxCount = 0}) => (_Writer(7)
        ..u8(WireOp.getEventsSince)
        ..u32(seq)
        ..u16(maxCount))
      .build();

  static Uint8List startSurvey(int durationS) {
    if (durationS < 30 || durationS > 3600) {
      throw ArgumentError.value(durationS, 'durationS', 'survey must be 30..3600 s');
    }
    return (_Writer(3)
          ..u8(WireOp.startSurvey)
          ..u16(durationS))
        .build();
  }

  static Uint8List startSession(int flags) => Uint8List.fromList([WireOp.startSession, flags & 0xFF]);
  static Uint8List stopSession() => Uint8List.fromList([WireOp.stopSession]);
  static Uint8List requestSnippet(int seq) => (_Writer(5)
        ..u8(WireOp.requestSnippet)
        ..u32(seq))
      .build();
  static Uint8List clearBond() => Uint8List.fromList([WireOp.clearBond]);

  static Uint8List authChallenge(Uint8List nonce) {
    if (nonce.length != 16) throw ArgumentError('nonce must be 16 bytes');
    return Uint8List.fromList([WireOp.authChallenge, ...nonce]);
  }

  static Uint8List authResponse(Uint8List proof) {
    if (proof.length != 32) throw ArgumentError('proof must be 32 bytes');
    return Uint8List.fromList([WireOp.authResponse, ...proof]);
  }

  static const sessionLiveBands = 0x01;
}

sealed class CpIndication {
  const CpIndication();

  factory CpIndication.decode(Uint8List b) {
    _min(b, 1, 'controlPoint');
    final r = _Reader(b, 'controlPoint');
    final op = r.u8();
    switch (op) {
      case WireOp.response:
        return CpResponse(reqOpcode: r.u8(), status: r.u8(), payload: r.rest());
      case WireOp.eventsDone:
        return CpEventsDone(count: r.u16(), lastSeq: r.u32());
      default:
        throw ProtocolException('controlPoint: unknown indication 0x${op.toRadixString(16)}');
    }
  }

  Uint8List encode();
}

class CpResponse extends CpIndication {
  const CpResponse({required this.reqOpcode, required this.status, required this.payload});
  final int reqOpcode;
  final int status;
  final Uint8List payload;

  @override
  Uint8List encode() => Uint8List.fromList([WireOp.response, reqOpcode, status, ...payload]);
}

class CpEventsDone extends CpIndication {
  const CpEventsDone({required this.count, required this.lastSeq});
  final int count;
  final int lastSeq;

  @override
  Uint8List encode() => (_Writer(7)
        ..u8(WireOp.eventsDone)
        ..u16(count)
        ..u32(lastSeq))
      .build();
}

class EventsSincePayload {
  const EventsSincePayload({required this.count, required this.firstSeq, required this.lastSeq, required this.oldestSeq});
  final int count;
  final int firstSeq;
  final int lastSeq;
  final int oldestSeq;

  factory EventsSincePayload.decode(Uint8List b) {
    _min(b, 14, 'eventsSince');
    final r = _Reader(b, 'eventsSince');
    return EventsSincePayload(count: r.u16(), firstSeq: r.u32(), lastSeq: r.u32(), oldestSeq: r.u32());
  }
}

class AuthChallengePayload {
  const AuthChallengePayload({required this.nodeNonce, required this.nodeProof});
  final Uint8List nodeNonce;
  final Uint8List nodeProof;

  factory AuthChallengePayload.decode(Uint8List b) {
    _min(b, 48, 'authChallenge');
    return AuthChallengePayload(nodeNonce: Uint8List.fromList(b.sublist(0, 16)), nodeProof: Uint8List.fromList(b.sublist(16, 48)));
  }
}

class SnippetMeta {
  const SnippetMeta({
    required this.eventSeq,
    required this.rows,
    required this.cols,
    required this.fLoHz10,
    required this.fHiHz10,
    required this.colDeciMs,
    required this.tileCount,
    required this.colsPerTile,
  });

  final int eventSeq;
  final int rows;
  final int cols;
  final int fLoHz10;
  final int fHiHz10;
  final int colDeciMs;
  final int tileCount;
  final int colsPerTile;

  factory SnippetMeta.decode(Uint8List b) {
    _min(b, WireLengths.snippetMeta, 'snippetMeta');
    final r = _Reader(b, 'snippetMeta');
    return SnippetMeta(
      eventSeq: r.u32(),
      rows: r.u8(),
      cols: r.u8(),
      fLoHz10: r.u16(),
      fHiHz10: r.u16(),
      colDeciMs: r.u16(),
      tileCount: r.u8(),
      colsPerTile: r.u8(),
    );
  }

  Map<String, Object> toFields() => {
        'eventSeq': eventSeq,
        'rows': rows,
        'cols': cols,
        'fLoHz10': fLoHz10,
        'fHiHz10': fHiHz10,
        'colDeciMs': colDeciMs,
        'tileCount': tileCount,
        'colsPerTile': colsPerTile,
      };
}

class SnippetTile {
  const SnippetTile({
    required this.eventSeq,
    required this.tileIndex,
    required this.tileCount,
    required this.col0,
    required this.nCols,
    required this.data,
  });

  final int eventSeq;
  final int tileIndex;
  final int tileCount;
  final int col0;
  final int nCols;
  final Uint8List data;

  factory SnippetTile.decode(Uint8List b) {
    _min(b, WireLengths.snippetTileHeader, 'snippetTile');
    final r = _Reader(b, 'snippetTile');
    return SnippetTile(eventSeq: r.u32(), tileIndex: r.u8(), tileCount: r.u8(), col0: r.u8(), nCols: r.u8(), data: r.rest());
  }

  Uint8List encode() => (_Writer(WireLengths.snippetTileHeader + data.length)
        ..u32(eventSeq)
        ..u8(tileIndex)
        ..u8(tileCount)
        ..u8(col0)
        ..u8(nCols)
        ..bytes(data))
      .build();
}
