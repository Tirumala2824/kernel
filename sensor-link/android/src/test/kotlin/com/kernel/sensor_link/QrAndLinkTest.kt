package com.kernel.sensor_link

import com.kernel.sensor_link.auth.keyFingerprint
import com.kernel.sensor_link.auth.toHex
import com.kernel.sensor_link.link.Backoff
import com.kernel.sensor_link.link.HealthBits
import com.kernel.sensor_link.link.LinkStep
import com.kernel.sensor_link.link.ReconnectPlan
import com.kernel.sensor_link.link.SessionStats
import com.kernel.sensor_link.protocol.SensorTypes
import kotlin.test.assertEquals
import kotlin.test.assertFailsWith
import kotlin.test.assertFalse
import kotlin.test.assertNull
import kotlin.test.assertTrue
import org.junit.jupiter.api.DynamicTest
import org.junit.jupiter.api.Test
import org.junit.jupiter.api.TestFactory

class QrAndLinkTest {
    private val qr = Vectors.json("qr_v1.json")
    private val types = mapOf(
        "usAir" to SensorTypes.US_AIR,
        "contactPiezo" to SensorTypes.CONTACT_PIEZO,
        "contactAccel" to SensorTypes.CONTACT_ACCEL,
        "audioAir" to SensorTypes.AUDIO_AIR,
    )

    @TestFactory
    fun validLabels(): List<DynamicTest> = qr.getJSONArray("valid").objects().map { v ->
        DynamicTest.dynamicTest(v.getString("payload").take(40)) {
            val l = QrLabel.parse(v.getString("payload"))
            assertEquals(v.getString("address"), l.address)
            assertEquals(v.getString("keyHex"), l.key.toHex())
            assertEquals(types.getValue(v.getString("sensorType")), l.sensorType)
            assertEquals(v.getString("fingerprint"), keyFingerprint(l.key))
            l.wipe()
            assertTrue(l.key.all { it.toInt() == 0 })
        }
    }

    @TestFactory
    fun invalidLabels(): List<DynamicTest> = qr.getJSONArray("invalid").objects().map { v ->
        DynamicTest.dynamicTest(v.getString("reason") + ": " + v.getString("payload").take(30)) {
            val e = assertFailsWith<QrFormatException> { QrLabel.parse(v.getString("payload")) }
            assertEquals(v.getString("reason"), e.reason)
        }
    }

    @Test
    fun base64UrlRejectsNonCanonical() {
        assertNull(Base64Url.decode("A"))
        assertNull(Base64Url.decode("AB")) // leftover bits set
        assertEquals("00", Base64Url.decode("AA")!!.toHex())
        assertEquals("fbff", Base64Url.decode("-_8")!!.toHex())
    }

    @Test
    fun reconnectSequenceAuthenticatesThenSetsTimeThenSyncs() {
        val s = ReconnectPlan.steps(alreadyBonded = false, supports2mPhy = true, liveBands = false)
        assertEquals(LinkStep.CONNECT, s.first())
        assertEquals(LinkStep.GET_EVENTS_SINCE, s.last())
        assertTrue(s.indexOf(LinkStep.BOND) < s.indexOf(LinkStep.REQUEST_MTU))
        assertTrue(s.indexOf(LinkStep.REQUEST_MTU) < s.indexOf(LinkStep.DISCOVER))
        assertTrue(s.indexOf(LinkStep.PREFER_2M_PHY) in 0 until s.indexOf(LinkStep.DISCOVER))
        assertTrue(s.indexOf(LinkStep.AUTHENTICATE) < s.indexOf(LinkStep.READ_BAND_TABLE))
        assertTrue(s.indexOf(LinkStep.AUTHENTICATE) < s.indexOf(LinkStep.SET_TIME))
        assertEquals(s.indexOf(LinkStep.SET_TIME) + 1, s.indexOf(LinkStep.GET_EVENTS_SINCE))
        assertTrue(s.indexOf(LinkStep.SUBSCRIBE_EVENT) < s.indexOf(LinkStep.GET_EVENTS_SINCE))
        assertFalse(LinkStep.SUBSCRIBE_BAND_FRAME in s)
        assertEquals(517, ReconnectPlan.MTU)

        val bonded = ReconnectPlan.steps(alreadyBonded = true, supports2mPhy = false, liveBands = true)
        assertFalse(LinkStep.BOND in bonded)
        assertFalse(LinkStep.PREFER_2M_PHY in bonded)
        assertTrue(LinkStep.SUBSCRIBE_BAND_FRAME in bonded)
    }

    @Test
    fun healthBitsMeanNotEvaluated() {
        assertTrue(HealthBits.isEvaluated(0))
        assertTrue(HealthBits.isEvaluated(HealthBits.LOW_BATTERY or HealthBits.SESSION_ACTIVE or HealthBits.TIME_VALID))
        for (b in listOf(HealthBits.JAMMED, HealthBits.CLIPPED, HealthBits.SURVEY_NEEDED, HealthBits.SURVEY_ACTIVE, HealthBits.SENSOR_FAULT)) {
            assertFalse(HealthBits.isEvaluated(b), "bit $b")
        }
    }

    @Test
    fun backoffAndSessionRate() {
        assertEquals(2_000L, Backoff.delayMs(0))
        assertEquals(4_000L, Backoff.delayMs(1))
        assertEquals(300_000L, Backoff.delayMs(20))
        val s = SessionStats(startedAtMs = 0)
        assertEquals("0 signals in 0 minutes (experimental)", s.summary(30_000))
        s.onEvent()
        assertEquals("1 signal in 1 minute (experimental)", s.summary(60_000))
        repeat(4) { s.onEvent() }
        assertEquals("5 signals in 12 minutes (experimental)", s.summary(12 * 60_000 + 5))
    }
}
