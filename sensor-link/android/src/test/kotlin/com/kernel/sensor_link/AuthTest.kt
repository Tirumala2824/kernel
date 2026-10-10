package com.kernel.sensor_link

import com.kernel.sensor_link.auth.AuthHandshake
import com.kernel.sensor_link.auth.Hmac
import com.kernel.sensor_link.auth.MacFunction
import com.kernel.sensor_link.auth.addressBytes
import com.kernel.sensor_link.auth.constantTimeEquals
import com.kernel.sensor_link.auth.hexToBytes
import com.kernel.sensor_link.auth.keyFingerprint
import com.kernel.sensor_link.auth.toHex
import com.kernel.sensor_link.protocol.AuthChallengePayload
import com.kernel.sensor_link.protocol.Cp
import com.kernel.sensor_link.protocol.Op
import kotlin.test.assertContentEquals
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertTrue
import org.junit.jupiter.api.DynamicTest
import org.junit.jupiter.api.Test
import org.junit.jupiter.api.TestFactory

class AuthTest {
    private val doc = Vectors.json("auth_v1.json")

    /** Published RFC 4231 values, independent of the exported file. */
    private val rfc4231 = mapOf(
        "tc1" to "b0344c61d8db38535ca8afceaf0bf12b881dc200c9833da726e9376c2e32cff7",
        "tc2" to "5bdcc146bf60754e6a042426089575c75a003f089d2739839dec58b964ec3843",
        "tc3" to "773ea91e36800e46854db8ebd09181a72959098b3ef8c122d9635514ced565fe",
        "tc4" to "82558a389a443c0ea4cc819899f2083a85f0faa3e578f8077a2e3ff46729665b",
        "tc6" to "60e431591ee0b67f0d8a26aacbf5b77f8e0bc6213728c5140546040f0ee37f54",
        "tc7" to "9b09ffa71b942fcb27635fbcd5b0e944bfdc63644f0713938a7f51535c3a35e2",
    )

    @TestFactory
    fun rfc4231HmacSha256(): List<DynamicTest> = doc.getJSONArray("rfc4231").objects().map { c ->
        DynamicTest.dynamicTest(c.getString("name")) {
            val mac = Hmac.sha256(hexToBytes(c.getString("keyHex")), hexToBytes(c.getString("dataHex")))
            assertEquals(c.getString("hmacHex"), mac.toHex())
            assertEquals(rfc4231.getValue(c.getString("name")), mac.toHex())
        }
    }

    @TestFactory
    fun handshakeVectors(): List<DynamicTest> = doc.getJSONArray("handshakes").objects().map { h ->
        DynamicTest.dynamicTest(h.getString("name")) {
            val key = hexToBytes(h.getString("keyHex"))
            val hs = AuthHandshake(MacFunction { Hmac.sha256(key, it) }, h.getString("address"))
            val appNonce = hs.appNonce(h.getLong("appCounter"), h.getLong("appEpochMs"))
            assertEquals(h.getString("appNonceHex"), appNonce.toHex())
            val nodeNonce = hexToBytes(h.getString("nodeNonceHex"))
            val nodeProof = hexToBytes(h.getString("nodeProofHex"))
            assertEquals(h.getString("nodeProofHex"), hs.expectedNodeProof(appNonce, nodeNonce).toHex())
            assertTrue(hs.verifyNode(appNonce, nodeNonce, nodeProof))
            assertEquals(h.getString("appProofHex"), hs.appProof(appNonce, nodeNonce).toHex())
            assertEquals(h.getString("fingerprint"), keyFingerprint(key))

            // A node that does not hold the key, or answers a different challenge, is refused.
            val forged = nodeProof.copyOf().also { it[31] = (it[31].toInt() xor 1).toByte() }
            assertFalse(hs.verifyNode(appNonce, nodeNonce, forged))
            assertFalse(hs.verifyNode(appNonce.copyOf().also { it[0] = (it[0] + 1).toByte() }, nodeNonce, nodeProof))
            val otherKey = AuthHandshake(MacFunction { Hmac.sha256(ByteArray(32), it) }, h.getString("address"))
            assertFalse(otherKey.verifyNode(appNonce, nodeNonce, nodeProof))
            val otherAddr = AuthHandshake(MacFunction { Hmac.sha256(key, it) }, "00:11:22:33:44:55")
            assertFalse(otherAddr.verifyNode(appNonce, nodeNonce, nodeProof))
            assertFalse(hs.verifyNode(appNonce, nodeNonce, nodeProof.copyOf(31)))
        }
    }

    @Test
    fun challengeFrameMatchesFixture() {
        val proto = Vectors.json("protocol_v1.json").getJSONArray("cases").objects()
        val req = proto.first { it.getString("name") == "cp_auth_challenge" }
        val nonce = hexToBytes(req.getJSONObject("fields").getString("nonceHex"))
        assertEquals(req.getString("hex"), Cp.authChallenge(nonce).toHex())
        val resp = proto.first { it.getString("name") == "cp_resp_auth_challenge" }
        val payload = AuthChallengePayload.decode(hexToBytes(resp.getJSONObject("fields").getString("payloadHex")))
        // The exported node response was computed for TEST_KEY / C0:FF:EE:12:34:56 with this nonce.
        val key = ByteArray(32) { it.toByte() }
        val hs = AuthHandshake(MacFunction { Hmac.sha256(key, it) }, "C0:FF:EE:12:34:56")
        assertTrue(hs.verifyNode(nonce, payload.nodeNonce, payload.nodeProof))
        assertEquals(Op.AUTH_CHALLENGE, Cp.authChallenge(nonce)[0].toInt())
    }

    @Test
    fun nonceCounterNeverRepeatsAndHelpers() {
        val key = ByteArray(32) { 7 }
        val hs = AuthHandshake(MacFunction { Hmac.sha256(key, it) }, "AA:BB:CC:DD:EE:FF")
        val nonces = (1L..64L).map { hs.appNonce(it, 1_767_225_600_000L).toHex() }.toSet()
        assertEquals(64, nonces.size)
        assertContentEquals(byteArrayOf(0xAA.toByte(), 0xBB.toByte(), 0xCC.toByte(), 0xDD.toByte(), 0xEE.toByte(), 0xFF.toByte()), addressBytes("AA:BB:CC:DD:EE:FF"))
        assertTrue(constantTimeEquals(byteArrayOf(1, 2), byteArrayOf(1, 2)))
        assertFalse(constantTimeEquals(byteArrayOf(1, 2), byteArrayOf(1, 3)))
        assertEquals(8, keyFingerprint(key).length)
    }
}
