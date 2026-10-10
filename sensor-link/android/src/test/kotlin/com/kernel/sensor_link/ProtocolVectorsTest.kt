package com.kernel.sensor_link

import com.kernel.sensor_link.auth.hexToBytes
import com.kernel.sensor_link.auth.toHex
import com.kernel.sensor_link.protocol.AdvData
import com.kernel.sensor_link.protocol.AuthChallengePayload
import com.kernel.sensor_link.protocol.Cp
import com.kernel.sensor_link.protocol.CpIndication
import com.kernel.sensor_link.protocol.EventsSincePayload
import com.kernel.sensor_link.protocol.Op
import com.kernel.sensor_link.protocol.ProtocolException
import com.kernel.sensor_link.protocol.SensorProtocol
import com.kernel.sensor_link.protocol.SnippetMeta
import com.kernel.sensor_link.protocol.SnippetTile
import com.kernel.sensor_link.protocol.WireBandFrame
import com.kernel.sensor_link.protocol.WireBandTable
import com.kernel.sensor_link.protocol.WireConfig
import com.kernel.sensor_link.protocol.WireDeviceInfo
import com.kernel.sensor_link.protocol.WireEvent
import com.kernel.sensor_link.protocol.WireStatus
import kotlin.test.assertEquals
import kotlin.test.assertFailsWith
import kotlin.test.assertTrue
import org.json.JSONObject
import org.junit.jupiter.api.DynamicTest
import org.junit.jupiter.api.Test
import org.junit.jupiter.api.TestFactory

/** Kotlin codec vs the byte fixtures shared with C, Python and Dart. */
class ProtocolVectorsTest {
    private val doc = Vectors.json("protocol_v1.json")

    @Test
    fun uuidsAndLengthsMatchTheSpec() {
        assertEquals(doc.getString("serviceUuid"), SensorProtocol.SERVICE.toString())
        val ch = doc.getJSONObject("characteristics")
        assertEquals(ch.getString("deviceInfo"), SensorProtocol.DEVICE_INFO.toString())
        assertEquals(ch.getString("config"), SensorProtocol.CONFIG.toString())
        assertEquals(ch.getString("bandTable"), SensorProtocol.BAND_TABLE.toString())
        assertEquals(ch.getString("bandFrame"), SensorProtocol.BAND_FRAME.toString())
        assertEquals(ch.getString("event"), SensorProtocol.EVENT.toString())
        assertEquals(ch.getString("status"), SensorProtocol.STATUS.toString())
        assertEquals(ch.getString("controlPoint"), SensorProtocol.CONTROL_POINT.toString())
        assertEquals(ch.getString("snippet"), SensorProtocol.SNIPPET.toString())
        val len = doc.getJSONObject("lengths")
        assertEquals(len.getInt("adv"), SensorProtocol.ADV_MFG_LEN)
        assertEquals(len.getInt("deviceInfo"), SensorProtocol.DEVICE_INFO_LEN)
        assertEquals(len.getInt("config"), SensorProtocol.CONFIG_LEN)
        assertEquals(len.getInt("event"), SensorProtocol.EVENT_LEN)
        assertEquals(len.getInt("status"), SensorProtocol.STATUS_LEN)
        assertEquals(len.getInt("bandFrameHeader"), SensorProtocol.BAND_FRAME_HDR_LEN)
    }

    @TestFactory
    fun everyFixtureRoundTrips(): List<DynamicTest> = doc.getJSONArray("cases").objects().map { c ->
        DynamicTest.dynamicTest(c.getString("name")) { check(c) }
    }

    private fun check(c: JSONObject) {
        val bytes = hexToBytes(c.getString("hex"))
        val f = c.getJSONObject("fields")
        val reencoded: ByteArray = when (c.getString("kind")) {
            "adv" -> AdvData.decode(bytes).also {
                assertEquals(AdvData(f.getInt("companyId"), f.getInt("proto"), f.getInt("sensorType"), f.getInt("lastEventSeq16"), f.getInt("batt")), it)
            }.encode()
            "deviceInfo" -> WireDeviceInfo.decode(bytes).also {
                assertEquals(f.getInt("protoMajor"), it.protoMajor)
                assertEquals(f.getInt("sensorType"), it.sensorType)
                assertEquals(f.getInt("nBands"), it.nBands)
                assertEquals(f.getInt("capabilities"), it.capabilities)
                assertEquals(f.getLong("sampleRateHz"), it.sampleRateHz)
                assertEquals(f.getInt("fftSize"), it.fftSize)
                assertEquals(f.getInt("hopSize"), it.hopSize)
                assertEquals(f.getInt("ringCapacity"), it.ringCapacity)
                assertEquals("${f.getInt("fwMajor")}.${f.getInt("fwMinor")}.${f.getInt("fwPatch")}", it.firmwareVersion)
            }.encode()
            "config" -> WireConfig.decode(bytes).also {
                assertEquals(f.getInt("flags"), it.flags)
                assertEquals(f.getInt("detectThreshHalfDb"), it.detectThreshHalfDb)
                assertEquals(f.getInt("jamHoldDs"), it.jamHoldDs)
                assertEquals(f.getInt("fmMinBwHz10"), it.fmMinBwHz10)
                assertEquals(f.getInt("trainMaxCvPct"), it.trainMaxCvPct)
                assertEquals(f.getInt("chirpMaxGapMs"), it.chirpMaxGapMs)
                assertTrue(it.isValid(), "defaults must pass the node's range checks")
            }.encode()
            "bandTable" -> WireBandTable.decode(bytes).also {
                assertEquals(f.getJSONArray("edgesHz10").ints(), it.edgesHz10)
                assertEquals(f.getInt("nBands"), it.nBands)
            }.encode()
            "bandFrame" -> WireBandFrame.decode(bytes).also {
                assertEquals(f.getLong("seq"), it.seq)
                assertEquals(f.getLong("tStartS"), it.tStartS)
                assertEquals(f.getInt("tStartMs"), it.tStartMs)
                assertEquals(f.getInt("frameMs"), it.frameMs)
                assertEquals(f.getInt("flags"), it.flags)
                assertEquals(f.getInt("noiseFloorDeciDbfs"), it.noiseFloorDeciDbfs)
                assertEquals(f.getInt("peakHz10"), it.peakHz10)
                assertEquals(f.getInt("peakDeciDbfs"), it.peakDeciDbfs)
                assertEquals(f.getInt("jamBandMask"), it.jamBandMask)
                assertEquals(f.getJSONArray("bandsHalfDb").ints(), it.bandsHalfDb)
            }.encode()
            "event" -> WireEvent.decode(bytes).also { assertEquals(eventOf(f), it) }.encode()
            "status" -> WireStatus.decode(bytes).also {
                assertEquals(
                    WireStatus(f.getInt("health"), f.getInt("battPct"), f.getInt("battMv"), f.getLong("lastSeq"), f.getLong("oldestSeq"),
                        f.getLong("uptimeS"), f.getInt("bootCount"), f.getInt("surveyRemainingS")),
                    it,
                )
            }.encode()
            "cpRequest" -> request(f)
            "cpResponse" -> (CpIndication.decode(bytes) as CpIndication.Response).also { r ->
                assertEquals(f.getInt("reqOpcode"), r.reqOpcode)
                assertEquals(f.getInt("status"), r.status)
                assertEquals(f.getString("payloadHex"), r.payload.toHex())
                when (r.reqOpcode) {
                    Op.GET_EVENTS_SINCE -> if (r.payload.isNotEmpty()) {
                        assertEquals(EventsSincePayload(f.getInt("count"), f.getLong("firstSeq"), f.getLong("lastSeq"), f.getLong("oldestSeq")),
                            EventsSincePayload.decode(r.payload))
                    }
                    Op.AUTH_CHALLENGE -> AuthChallengePayload.decode(r.payload).let {
                        assertEquals(f.getString("nodeNonceHex"), it.nodeNonce.toHex())
                        assertEquals(f.getString("nodeProofHex"), it.nodeProof.toHex())
                    }
                    Op.REQUEST_SNIPPET -> assertEquals(
                        SnippetMeta(f.getLong("eventSeq"), f.getInt("rows"), f.getInt("cols"), f.getInt("fLoHz10"), f.getInt("fHiHz10"),
                            f.getInt("colDeciMs"), f.getInt("tileCount"), f.getInt("colsPerTile")),
                        SnippetMeta.decode(r.payload),
                    )
                }
            }.let { CpIndication.response(it.reqOpcode, it.status, it.payload) }
            "eventsDone" -> (CpIndication.decode(bytes) as CpIndication.EventsDone).also {
                assertEquals(CpIndication.EventsDone(f.getInt("count"), f.getLong("lastSeq")), it)
            }.let { CpIndication.eventsDone(it.count, it.lastSeq) }
            "snippetTile" -> SnippetTile.decode(bytes).also {
                assertEquals(f.getLong("eventSeq"), it.eventSeq)
                assertEquals(f.getInt("tileIndex"), it.tileIndex)
                assertEquals(f.getInt("nCols"), it.nCols)
                assertEquals(f.getString("dataHex"), it.data.toHex())
                assertEquals(f.getInt("rows") * it.nCols, it.data.size)
            }.encode()
            else -> error("unknown kind ${c.getString("kind")}")
        }
        assertEquals(c.getString("hex"), reencoded.toHex(), "re-encode ${c.getString("name")}")
    }

    private fun request(f: JSONObject): ByteArray = when (f.getInt("opcode")) {
        Op.SET_TIME -> Cp.setTime(f.getLong("epochMs"))
        Op.GET_EVENTS_SINCE -> Cp.getEventsSince(f.getLong("seq"), f.getInt("maxCount"))
        Op.START_SURVEY -> Cp.startSurvey(f.getInt("durationS"))
        Op.START_SESSION -> Cp.startSession(f.getInt("flags"))
        Op.STOP_SESSION -> Cp.stopSession()
        Op.REQUEST_SNIPPET -> Cp.requestSnippet(f.getLong("seq"))
        Op.CLEAR_BOND -> Cp.clearBond()
        Op.AUTH_CHALLENGE -> Cp.authChallenge(hexToBytes(f.getString("nonceHex")))
        Op.AUTH_RESPONSE -> Cp.authResponse(hexToBytes(f.getString("proofHex")))
        else -> error("opcode")
    }

    @TestFactory
    fun detectorVectorEventsDecode(): List<DynamicTest> = Vectors.detectFiles().map { file ->
        DynamicTest.dynamicTest(file.name) {
            val v = Vectors.detect(file)
            for (e in v.getJSONArray("events").objects()) {
                val decoded = WireEvent.decode(hexToBytes(e.getString("hex")))
                assertEquals(eventOf(e), decoded)
                assertEquals(e.getString("hex"), decoded.encode().toHex())
            }
        }
    }

    @Test
    fun shortPayloadsAreRejectedAndTrailingBytesIgnored() {
        val ev = WireEvent(1, 2, 3, 4, 1, 1, 5, 6, 7, -8, 9, -10, 11, 12, 13, 255, 7)
        val b = ev.encode()
        assertEquals(ev, WireEvent.decode(b + byteArrayOf(1, 2, 3)))
        assertFailsWith<ProtocolException> { WireEvent.decode(b.copyOf(29)) }
        assertFailsWith<ProtocolException> { WireStatus.decode(ByteArray(20)) }
        assertFailsWith<ProtocolException> { WireBandTable.decode(byteArrayOf(0, 0)) }
        assertFailsWith<ProtocolException> { CpIndication.decode(byteArrayOf(0x42)) }
        assertFailsWith<IllegalArgumentException> { Cp.startSurvey(10) }
    }

    @Test
    fun configRangesMatchTheNode() {
        val base = WireConfig.decode(hexToBytes(doc.getJSONArray("cases").objects().first { it.getString("name") == "config_default_usAir" }.getString("hex")))
        assertTrue(base.isValid())
        assertTrue(!base.copy(cfgVersion = 2).isValid())
        assertTrue(!base.copy(bandFrameMs = 50).isValid())
        assertTrue(!base.copy(jamHoldDs = 1).isValid())
        assertTrue(!base.copy(flags = 0x80).isValid())
    }

    companion object {
        fun eventOf(f: JSONObject) = WireEvent(
            f.getLong("seq"), f.getLong("tStartS"), f.getInt("tStartMs"), f.getInt("durationMs"), f.getInt("eventClass"),
            f.getInt("flags"), f.getInt("peakHz10"), f.getInt("minHz10"), f.getInt("maxHz10"), f.getInt("slopeDHzPerMs"),
            f.getInt("snrHalfDb"), f.getInt("peakDbfs"), f.getInt("impulses"), f.getInt("harmonics"), f.getInt("repRateCHz"),
            f.getInt("ipiCvPct"), f.getInt("bootLow"),
        )
    }
}
