package com.kernel.sensor_link.auth

import java.security.MessageDigest
import javax.crypto.Mac
import javax.crypto.spec.SecretKeySpec

/**
 * HMAC-SHA256 under the node's per-device key. In production this is backed by
 * a non-exportable Android Keystore key ([KeyVault]); the raw key bytes never
 * reach this interface.
 */
fun interface MacFunction {
    fun mac(message: ByteArray): ByteArray
}

object AuthLabels {
    val NODE: ByteArray = "KRNL-AUTH-N1".toByteArray(Charsets.US_ASCII)
    val APP: ByteArray = "KRNL-AUTH-A1".toByteArray(Charsets.US_ASCII)
    val NODE_NONCE: ByteArray = "KRNL-NONCE".toByteArray(Charsets.US_ASCII)
    val APP_NONCE: ByteArray = "KRNL-APPNONCE".toByteArray(Charsets.US_ASCII)
}

object Hmac {
    /** Plain javax HMAC-SHA256 (RFC 2104). Used for vectors and as the Keystore algorithm name. */
    const val ALGORITHM = "HmacSHA256"

    fun sha256(key: ByteArray, message: ByteArray): ByteArray =
        Mac.getInstance(ALGORITHM).run {
            init(SecretKeySpec(key, ALGORITHM))
            doFinal(message)
        }
}

fun le64(v: Long): ByteArray = ByteArray(8) { i -> (v ushr (8 * i)).toByte() }

fun le32(v: Long): ByteArray = ByteArray(4) { i -> (v ushr (8 * i)).toByte() }

fun ByteArray.toHex(): String = joinToString("") { "%02x".format(it.toInt() and 0xFF) }

fun hexToBytes(hex: String): ByteArray {
    require(hex.length % 2 == 0) { "odd hex length" }
    return ByteArray(hex.length / 2) { i -> hex.substring(2 * i, 2 * i + 2).toInt(16).toByte() }
}

/** Constant-time comparison (no early exit on the first differing byte). */
fun constantTimeEquals(a: ByteArray, b: ByteArray): Boolean = MessageDigest.isEqual(a, b)

/** First 8 hex chars of sha256(key); stored instead of the key. */
fun keyFingerprint(key: ByteArray): String = MessageDigest.getInstance("SHA-256").digest(key).copyOf(4).toHex()

/** Six address bytes in printed order ("AA:BB:..." -> AA BB ...). */
fun addressBytes(address: String): ByteArray {
    val parts = address.split(':')
    require(parts.size == 6) { "address must be AA:BB:CC:DD:EE:FF" }
    return ByteArray(6) { parts[it].toInt(16).toByte() }
}

/**
 * App side of the mutual challenge-response in docs/sensor-protocol.md section 7.
 *
 *   phone -> AUTH_CHALLENGE(appNonce)
 *   node  -> nodeNonce, nodeProof = HMAC(K, "KRNL-AUTH-N1" | appNonce | nodeNonce | addr6)
 *   phone verifies, -> AUTH_RESPONSE(HMAC(K, "KRNL-AUTH-A1" | nodeNonce | appNonce | addr6))
 */
class AuthHandshake(private val key: MacFunction, address: String) {
    private val addr6 = addressBytes(address)

    /**
     * Deterministic, never-repeating nonce: HMAC(K, "KRNL-APPNONCE" | counter | epochMs)[0:16].
     * The counter is persisted, so no RNG is needed and nonces stay unpredictable without K.
     */
    fun appNonce(counter: Long, epochMs: Long): ByteArray =
        key.mac(AuthLabels.APP_NONCE + le64(counter) + le64(epochMs)).copyOf(16)

    fun expectedNodeProof(appNonce: ByteArray, nodeNonce: ByteArray): ByteArray =
        key.mac(AuthLabels.NODE + appNonce + nodeNonce + addr6)

    fun verifyNode(appNonce: ByteArray, nodeNonce: ByteArray, nodeProof: ByteArray): Boolean {
        if (appNonce.size != 16 || nodeNonce.size != 16 || nodeProof.size != 32) return false
        return constantTimeEquals(expectedNodeProof(appNonce, nodeNonce), nodeProof)
    }

    fun appProof(appNonce: ByteArray, nodeNonce: ByteArray): ByteArray =
        key.mac(AuthLabels.APP + nodeNonce + appNonce + addr6)
}
