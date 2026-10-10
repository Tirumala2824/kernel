package com.kernel.sensor_link.protocol

import java.util.UUID

/**
 * Wire codec for docs/sensor-protocol.md v1 (little-endian, packed).
 * Mirrors firmware/components/kernel_proto and lib/src/protocol.dart; all are
 * tested against firmware/reference/vectors/protocol_v1.json.
 */
object SensorProtocol {
    const val PROTO_MAJOR = 1
    const val PROTO_MINOR = 0
    const val CFG_VERSION = 1
    const val COMPANY_ID_TEST = 0xFFFF
    const val MAX_BANDS = 24

    const val ADV_MFG_LEN = 7
    const val DEVICE_INFO_LEN = 22
    const val CONFIG_LEN = 32
    const val EVENT_LEN = 30
    const val STATUS_LEN = 21
    const val BAND_FRAME_HDR_LEN = 23
    const val SNIPPET_META_LEN = 14
    const val SNIPPET_TILE_HDR_LEN = 8

    private const val UUID_SUFFIX = "-4139-44b2-877d-c537908d6290"

    fun uuid(short: Int): UUID = UUID.fromString("c778%04x$UUID_SUFFIX".format(short))

    val SERVICE: UUID = uuid(0x0001)
    val DEVICE_INFO: UUID = uuid(0x0002)
    val CONFIG: UUID = uuid(0x0003)
    val BAND_TABLE: UUID = uuid(0x0004)
    val BAND_FRAME: UUID = uuid(0x0005)
    val EVENT: UUID = uuid(0x0006)
    val STATUS: UUID = uuid(0x0007)
    val CONTROL_POINT: UUID = uuid(0x0008)
    val SNIPPET: UUID = uuid(0x0009)
    val CCCD: UUID = UUID.fromString("00002902-0000-1000-8000-00805f9b34fb")
}

object Op {
    const val SET_TIME = 0x01
    const val GET_EVENTS_SINCE = 0x02
    const val START_SURVEY = 0x03
    const val START_SESSION = 0x04
    const val STOP_SESSION = 0x05
    const val REQUEST_SNIPPET = 0x06
    const val CLEAR_BOND = 0x07
    const val AUTH_CHALLENGE = 0x10
    const val AUTH_RESPONSE = 0x11
    const val RESPONSE = 0x80
    const val EVENTS_DONE = 0x81
}

object CpStatus {
    const val OK = 0x00
    const val UNKNOWN_OPCODE = 0x01
    const val INVALID_PARAM = 0x02
    const val NOT_AUTHENTICATED = 0x03
    const val AUTH_FAILED = 0x04
    const val BUSY = 0x05
    const val NOT_AVAILABLE = 0x06
    const val STORAGE_ERROR = 0x07
}

object SensorTypes {
    const val US_AIR = 1
    const val CONTACT_PIEZO = 2
    const val CONTACT_ACCEL = 3
    const val AUDIO_AIR = 4

    fun isKnown(t: Int) = t in US_AIR..AUDIO_AIR
}

class ProtocolException(message: String) : IllegalArgumentException(message)

/** Little-endian reader with bounds checks. */
class LeReader(private val b: ByteArray, private var pos: Int = 0) {
    val remaining: Int get() = b.size - pos

    private fun need(n: Int) {
        if (pos + n > b.size) throw ProtocolException("truncated at $pos (+$n of ${b.size})")
    }

    fun u8(): Int { need(1); return b[pos++].toInt() and 0xFF }
    fun i8(): Int { need(1); return b[pos++].toInt() }
    fun u16(): Int { need(2); val v = (b[pos].toInt() and 0xFF) or ((b[pos + 1].toInt() and 0xFF) shl 8); pos += 2; return v }
    fun i16(): Int = u16().toShort().toInt()
    fun u24(): Int { val lo = u16(); return lo or (u8() shl 16) }
    fun u32(): Long { val lo = u16().toLong(); return lo or (u16().toLong() shl 16) }
    fun u64(): Long { val lo = u32(); return lo or (u32() shl 32) }
    fun bytes(n: Int): ByteArray { need(n); val out = b.copyOfRange(pos, pos + n); pos += n; return out }
    fun rest(): ByteArray = bytes(remaining)
}

/** Little-endian writer for a fixed-size buffer. */
class LeWriter(size: Int) {
    private val b = ByteArray(size)
    private var pos = 0

    fun u8(v: Int) = apply { b[pos++] = v.toByte() }
    fun u16(v: Int) = apply { u8(v and 0xFF); u8((v shr 8) and 0xFF) }
    fun u24(v: Int) = apply { u16(v and 0xFFFF); u8((v shr 16) and 0xFF) }
    fun u32(v: Long) = apply { u16((v and 0xFFFF).toInt()); u16(((v shr 16) and 0xFFFF).toInt()) }
    fun u64(v: Long) = apply { u32(v and 0xFFFFFFFFL); u32((v ushr 32) and 0xFFFFFFFFL) }
    fun bytes(v: ByteArray) = apply { v.copyInto(b, pos); pos += v.size }
    fun build(): ByteArray {
        check(pos == b.size) { "wrote $pos of ${b.size}" }
        return b
    }
}

private fun checkLen(bytes: ByteArray, min: Int, what: String) {
    if (bytes.size < min) throw ProtocolException("$what: ${bytes.size} < $min bytes")
}

data class AdvData(
    val companyId: Int,
    val proto: Int,
    val sensorType: Int,
    val lastEventSeq16: Int,
    val batt: Int,
) {
    fun encode(): ByteArray = LeWriter(SensorProtocol.ADV_MFG_LEN)
        .u16(companyId).u8(proto).u8(sensorType).u16(lastEventSeq16).u8(batt).build()

    companion object {
        /** [bytes] starts at the company id (Android's manufacturer data value plus its 2-byte id). */
        fun decode(bytes: ByteArray): AdvData {
            checkLen(bytes, SensorProtocol.ADV_MFG_LEN, "adv")
            val r = LeReader(bytes)
            return AdvData(r.u16(), r.u8(), r.u8(), r.u16(), r.u8())
        }
    }
}

data class WireDeviceInfo(
    val protoMajor: Int,
    val protoMinor: Int,
    val sensorType: Int,
    val hwRev: Int,
    val fwMajor: Int,
    val fwMinor: Int,
    val fwPatch: Int,
    val nBands: Int,
    val capabilities: Int,
    val sampleRateHz: Long,
    val fftSize: Int,
    val hopSize: Int,
    val ringCapacity: Int,
    val cfgVersion: Int,
) {
    val firmwareVersion: String get() = "$fwMajor.$fwMinor.$fwPatch"

    fun encode(): ByteArray = LeWriter(SensorProtocol.DEVICE_INFO_LEN)
        .u8(protoMajor).u8(protoMinor).u8(sensorType).u8(hwRev).u8(fwMajor).u8(fwMinor).u8(fwPatch).u8(nBands)
        .u16(capabilities).u32(sampleRateHz).u16(fftSize).u16(hopSize).u16(ringCapacity).u8(cfgVersion).u8(0)
        .build()

    companion object {
        fun decode(bytes: ByteArray): WireDeviceInfo {
            checkLen(bytes, SensorProtocol.DEVICE_INFO_LEN, "deviceInfo")
            val r = LeReader(bytes)
            return WireDeviceInfo(
                r.u8(), r.u8(), r.u8(), r.u8(), r.u8(), r.u8(), r.u8(), r.u8(),
                r.u16(), r.u32(), r.u16(), r.u16(), r.u16(), r.u8(),
            )
        }
    }
}

data class WireConfig(
    val cfgVersion: Int,
    val flags: Int,
    val bandFrameMs: Int,
    val dutyOnS: Int,
    val dutyOffS: Int,
    val detectThreshHalfDb: Int,
    val jamThreshHalfDb: Int,
    val jamHoldDs: Int,
    val impulseThreshHalfDb: Int,
    val minBlobMs: Int,
    val maxGapMs: Int,
    val flatMinMs: Int,
    val contMinMs: Int,
    val fmMinBwHz10: Int,
    val burstMinImpulses: Int,
    val trainMinPulses: Int,
    val burstMaxGapMs: Int,
    val impulseMinHalfMs: Int,
    val impulseMaxMs: Int,
    val trainMaxCvPct: Int,
    val lowBattPct: Int,
    val chirpMaxGapMs: Int,
) {
    fun encode(): ByteArray = LeWriter(SensorProtocol.CONFIG_LEN)
        .u8(cfgVersion).u8(flags).u16(bandFrameMs).u16(dutyOnS).u16(dutyOffS)
        .u8(detectThreshHalfDb).u8(jamThreshHalfDb).u8(jamHoldDs).u8(impulseThreshHalfDb).u8(minBlobMs).u8(maxGapMs)
        .u16(flatMinMs).u16(contMinMs).u16(fmMinBwHz10).u8(burstMinImpulses).u8(trainMinPulses).u16(burstMaxGapMs)
        .u8(impulseMinHalfMs).u8(impulseMaxMs).u8(trainMaxCvPct).u8(lowBattPct).u16(chirpMaxGapMs).u16(0)
        .build()

    /** Same ranges the node enforces (docs/sensor-protocol.md 4.2). */
    fun isValid(): Boolean =
        cfgVersion == SensorProtocol.CFG_VERSION && (flags and 0x80) == 0 && bandFrameMs in 100..10000 &&
            dutyOnS in 10..3600 && dutyOffS in 0..3600 && detectThreshHalfDb in 12..80 && jamThreshHalfDb in 6..60 &&
            jamHoldDs in 5..250 && impulseThreshHalfDb in 12..80 && minBlobMs in 1..100 && maxGapMs in 0..50 &&
            flatMinMs in 50..5000 && contMinMs in 200..10000 && fmMinBwHz10 in 10..5000 && burstMinImpulses in 2..50 &&
            trainMinPulses in 3..50 && burstMaxGapMs in 10..2000 && impulseMinHalfMs in 1..40 && impulseMaxMs in 1..100 &&
            impulseMinHalfMs <= 2 * impulseMaxMs && trainMaxCvPct in 1..100 && lowBattPct in 5..50 &&
            chirpMaxGapMs in 10..1000

    companion object {
        fun decode(bytes: ByteArray): WireConfig {
            checkLen(bytes, SensorProtocol.CONFIG_LEN, "config")
            val r = LeReader(bytes)
            return WireConfig(
                r.u8(), r.u8(), r.u16(), r.u16(), r.u16(), r.u8(), r.u8(), r.u8(), r.u8(), r.u8(), r.u8(),
                r.u16(), r.u16(), r.u16(), r.u8(), r.u8(), r.u16(), r.u8(), r.u8(), r.u8(), r.u8(), r.u16(),
            )
        }
    }
}

data class WireBandTable(val edgesHz10: List<Int>) {
    val nBands: Int get() = edgesHz10.size - 1

    fun encode(): ByteArray {
        val w = LeWriter(2 + 2 * edgesHz10.size).u8(nBands).u8(0)
        edgesHz10.forEach { w.u16(it) }
        return w.build()
    }

    companion object {
        fun decode(bytes: ByteArray): WireBandTable {
            checkLen(bytes, 2, "bandTable")
            val r = LeReader(bytes)
            val n = r.u8()
            r.u8()
            if (n !in 1..SensorProtocol.MAX_BANDS) throw ProtocolException("bandTable: nBands $n")
            val edges = List(n + 1) { r.u16() }
            if (edges.zipWithNext().any { (a, b) -> b <= a }) throw ProtocolException("bandTable: edges not ascending")
            return WireBandTable(edges)
        }
    }
}

data class WireBandFrame(
    val seq: Long,
    val tStartS: Long,
    val tStartMs: Int,
    val frameMs: Int,
    val flags: Int,
    val noiseFloorDeciDbfs: Int,
    val peakHz10: Int,
    val peakDeciDbfs: Int,
    val jamBandMask: Int,
    val bandsHalfDb: List<Int>,
) {
    val nBands: Int get() = bandsHalfDb.size

    fun encode(): ByteArray {
        val w = LeWriter(SensorProtocol.BAND_FRAME_HDR_LEN + nBands)
            .u32(seq).u32(tStartS).u16(tStartMs).u16(frameMs).u8(flags).u8(nBands)
            .u16(noiseFloorDeciDbfs and 0xFFFF).u16(peakHz10).u16(peakDeciDbfs and 0xFFFF).u24(jamBandMask)
        bandsHalfDb.forEach { w.u8(it) }
        return w.build()
    }

    companion object {
        const val FLAG_TIME_VALID = 0x01
        const val FLAG_JAMMED = 0x02
        const val FLAG_CLIPPED = 0x04
        const val FLAG_SURVEY_ACTIVE = 0x08
        const val FLAG_WARMING_UP = 0x10

        fun decode(bytes: ByteArray): WireBandFrame {
            checkLen(bytes, SensorProtocol.BAND_FRAME_HDR_LEN, "bandFrame")
            val r = LeReader(bytes)
            val seq = r.u32()
            val ts = r.u32()
            val tms = r.u16()
            val frameMs = r.u16()
            val flags = r.u8()
            val n = r.u8()
            if (n !in 1..SensorProtocol.MAX_BANDS) throw ProtocolException("bandFrame: nBands $n")
            val floor = r.i16()
            val peakHz10 = r.u16()
            val peak = r.i16()
            val mask = r.u24()
            val bands = List(n) { r.u8() }
            return WireBandFrame(seq, ts, tms, frameMs, flags, floor, peakHz10, peak, mask, bands)
        }
    }
}

data class WireEvent(
    val seq: Long,
    val tStartS: Long,
    val tStartMs: Int,
    val durationMs: Int,
    val eventClass: Int,
    val flags: Int,
    val peakHz10: Int,
    val minHz10: Int,
    val maxHz10: Int,
    val slopeDHzPerMs: Int,
    val snrHalfDb: Int,
    val peakDbfs: Int,
    val impulses: Int,
    val harmonics: Int,
    val repRateCHz: Int,
    val ipiCvPct: Int,
    val bootLow: Int,
) {
    val timeValid: Boolean get() = (flags and FLAG_TIME_VALID) != 0

    fun encode(): ByteArray = LeWriter(SensorProtocol.EVENT_LEN)
        .u32(seq).u32(tStartS).u16(tStartMs).u16(durationMs).u8(eventClass).u8(flags)
        .u16(peakHz10).u16(minHz10).u16(maxHz10).u16(slopeDHzPerMs and 0xFFFF).u8(snrHalfDb).u8(peakDbfs and 0xFF)
        .u8(impulses).u8(harmonics).u16(repRateCHz).u8(ipiCvPct).u8(bootLow)
        .build()

    companion object {
        const val FLAG_TIME_VALID = 0x01
        const val FLAG_REGULAR_TRAIN = 0x02
        const val FLAG_TRUNCATED = 0x04
        const val FLAG_SNIPPET = 0x08

        fun decode(bytes: ByteArray): WireEvent {
            checkLen(bytes, SensorProtocol.EVENT_LEN, "event")
            val r = LeReader(bytes)
            return WireEvent(
                r.u32(), r.u32(), r.u16(), r.u16(), r.u8(), r.u8(), r.u16(), r.u16(), r.u16(), r.i16(),
                r.u8(), r.i8(), r.u8(), r.u8(), r.u16(), r.u8(), r.u8(),
            )
        }
    }
}

data class WireStatus(
    val health: Int,
    val battPct: Int,
    val battMv: Int,
    val lastSeq: Long,
    val oldestSeq: Long,
    val uptimeS: Long,
    val bootCount: Int,
    val surveyRemainingS: Int,
) {
    fun encode(): ByteArray = LeWriter(SensorProtocol.STATUS_LEN)
        .u16(health).u8(battPct).u16(battMv).u32(lastSeq).u32(oldestSeq).u32(uptimeS).u16(bootCount)
        .u16(surveyRemainingS).build()

    companion object {
        fun decode(bytes: ByteArray): WireStatus {
            checkLen(bytes, SensorProtocol.STATUS_LEN, "status")
            val r = LeReader(bytes)
            return WireStatus(r.u16(), r.u8(), r.u16(), r.u32(), r.u32(), r.u32(), r.u16(), r.u16())
        }
    }
}

/** ControlPoint request builders (section 4.7). */
object Cp {
    fun setTime(epochMs: Long): ByteArray = LeWriter(9).u8(Op.SET_TIME).u64(epochMs).build()
    fun getEventsSince(seq: Long, maxCount: Int = 0): ByteArray =
        LeWriter(7).u8(Op.GET_EVENTS_SINCE).u32(seq).u16(maxCount).build()
    fun startSurvey(durationS: Int): ByteArray {
        require(durationS in 30..3600) { "survey duration $durationS s outside 30..3600" }
        return LeWriter(3).u8(Op.START_SURVEY).u16(durationS).build()
    }
    fun startSession(flags: Int): ByteArray = LeWriter(2).u8(Op.START_SESSION).u8(flags).build()
    fun stopSession(): ByteArray = byteArrayOf(Op.STOP_SESSION.toByte())
    fun requestSnippet(seq: Long): ByteArray = LeWriter(5).u8(Op.REQUEST_SNIPPET).u32(seq).build()
    fun clearBond(): ByteArray = byteArrayOf(Op.CLEAR_BOND.toByte())
    fun authChallenge(appNonce: ByteArray): ByteArray {
        require(appNonce.size == 16)
        return LeWriter(17).u8(Op.AUTH_CHALLENGE).bytes(appNonce).build()
    }
    fun authResponse(appProof: ByteArray): ByteArray {
        require(appProof.size == 32)
        return LeWriter(33).u8(Op.AUTH_RESPONSE).bytes(appProof).build()
    }

    const val SESSION_LIVE_BANDS = 0x01
}

/** Any ControlPoint indication. */
sealed class CpIndication {
    data class Response(val reqOpcode: Int, val status: Int, val payload: ByteArray) : CpIndication() {
        override fun equals(other: Any?) = other is Response && other.reqOpcode == reqOpcode &&
            other.status == status && other.payload.contentEquals(payload)
        override fun hashCode() = (reqOpcode * 31 + status) * 31 + payload.contentHashCode()
    }

    data class EventsDone(val count: Int, val lastSeq: Long) : CpIndication()

    companion object {
        fun decode(bytes: ByteArray): CpIndication {
            checkLen(bytes, 1, "controlPoint")
            val r = LeReader(bytes)
            return when (val op = r.u8()) {
                Op.RESPONSE -> Response(r.u8(), r.u8(), r.rest())
                Op.EVENTS_DONE -> EventsDone(r.u16(), r.u32())
                else -> throw ProtocolException("controlPoint: unknown indication 0x%02x".format(op))
            }
        }

        fun response(reqOpcode: Int, status: Int, payload: ByteArray = ByteArray(0)): ByteArray =
            LeWriter(3 + payload.size).u8(Op.RESPONSE).u8(reqOpcode).u8(status).bytes(payload).build()

        fun eventsDone(count: Int, lastSeq: Long): ByteArray = LeWriter(7).u8(Op.EVENTS_DONE).u16(count).u32(lastSeq).build()
    }
}

data class EventsSincePayload(val count: Int, val firstSeq: Long, val lastSeq: Long, val oldestSeq: Long) {
    fun encode(): ByteArray = LeWriter(14).u16(count).u32(firstSeq).u32(lastSeq).u32(oldestSeq).build()

    companion object {
        fun decode(bytes: ByteArray): EventsSincePayload {
            checkLen(bytes, 14, "eventsSince")
            val r = LeReader(bytes)
            return EventsSincePayload(r.u16(), r.u32(), r.u32(), r.u32())
        }
    }
}

class AuthChallengePayload(val nodeNonce: ByteArray, val nodeProof: ByteArray) {
    fun encode(): ByteArray = nodeNonce + nodeProof

    companion object {
        fun decode(bytes: ByteArray): AuthChallengePayload {
            checkLen(bytes, 48, "authChallenge")
            return AuthChallengePayload(bytes.copyOfRange(0, 16), bytes.copyOfRange(16, 48))
        }
    }
}

data class SnippetMeta(
    val eventSeq: Long,
    val rows: Int,
    val cols: Int,
    val fLoHz10: Int,
    val fHiHz10: Int,
    val colDeciMs: Int,
    val tileCount: Int,
    val colsPerTile: Int,
) {
    fun encode(): ByteArray = LeWriter(SensorProtocol.SNIPPET_META_LEN)
        .u32(eventSeq).u8(rows).u8(cols).u16(fLoHz10).u16(fHiHz10).u16(colDeciMs).u8(tileCount).u8(colsPerTile)
        .build()

    companion object {
        fun decode(bytes: ByteArray): SnippetMeta {
            checkLen(bytes, SensorProtocol.SNIPPET_META_LEN, "snippetMeta")
            val r = LeReader(bytes)
            return SnippetMeta(r.u32(), r.u8(), r.u8(), r.u16(), r.u16(), r.u16(), r.u8(), r.u8())
        }
    }
}

class SnippetTile(val eventSeq: Long, val tileIndex: Int, val tileCount: Int, val col0: Int, val nCols: Int, val data: ByteArray) {
    fun encode(): ByteArray = LeWriter(SensorProtocol.SNIPPET_TILE_HDR_LEN + data.size)
        .u32(eventSeq).u8(tileIndex).u8(tileCount).u8(col0).u8(nCols).bytes(data).build()

    companion object {
        fun decode(bytes: ByteArray): SnippetTile {
            checkLen(bytes, SensorProtocol.SNIPPET_TILE_HDR_LEN, "snippetTile")
            val r = LeReader(bytes)
            return SnippetTile(r.u32(), r.u8(), r.u8(), r.u8(), r.u8(), r.rest())
        }
    }
}
