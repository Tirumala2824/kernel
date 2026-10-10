package com.kernel.sensor_link.auth

import android.content.Context
import android.security.keystore.KeyProperties
import android.security.keystore.KeyProtection
import java.security.KeyStore
import javax.crypto.Mac
import javax.crypto.SecretKey
import javax.crypto.spec.SecretKeySpec

/** What the phone keeps about a paired node. Never the key itself. */
data class NodeRecord(
    val nodeId: String,
    val address: String,
    val name: String,
    val sensorType: Int,
    val keyFingerprint: String,
    val protocolVersion: Int,
    val firmwareVersion: String?,
    val associationId: Int,
)

/**
 * Per-device keys live in Android Keystore as non-exportable HmacSHA256 keys
 * (imported with [KeyProtection], PURPOSE_SIGN). App preferences hold only
 * node metadata, the key fingerprint and the app-nonce counter.
 */
class KeyVault(context: Context) {
    private val prefs = context.applicationContext.getSharedPreferences(PREFS, Context.MODE_PRIVATE)

    private fun keystore(): KeyStore = KeyStore.getInstance(ANDROID_KEYSTORE).apply { load(null) }

    private fun alias(nodeId: String) = "kernel.sensor.$nodeId"

    /** Imports [key] and zeroes the caller's copy. */
    fun importKey(nodeId: String, key: ByteArray) {
        try {
            val entry = KeyStore.SecretKeyEntry(SecretKeySpec(key, Hmac.ALGORITHM))
            val protection = KeyProtection.Builder(KeyProperties.PURPOSE_SIGN or KeyProperties.PURPOSE_VERIFY).build()
            keystore().setEntry(alias(nodeId), entry, protection)
        } finally {
            key.fill(0)
        }
    }

    fun macFor(nodeId: String): MacFunction? {
        val key = keystore().getKey(alias(nodeId), null) as? SecretKey ?: return null
        return MacFunction { message ->
            Mac.getInstance(Hmac.ALGORITHM).run {
                init(key)
                doFinal(message)
            }
        }
    }

    fun deleteKey(nodeId: String) {
        val ks = keystore()
        if (ks.containsAlias(alias(nodeId))) ks.deleteEntry(alias(nodeId))
    }

    /** Monotonic per-node counter for app nonces (never repeats, survives restarts). */
    @Synchronized
    fun nextNonceCounter(nodeId: String): Long {
        val k = "ctr.$nodeId"
        val next = prefs.getLong(k, 0L) + 1
        prefs.edit().putLong(k, next).commit()
        return next
    }

    @Synchronized
    fun save(r: NodeRecord) {
        val ids = ids() + r.nodeId
        prefs.edit()
            .putStringSet(IDS, ids)
            .putString("addr.${r.nodeId}", r.address)
            .putString("name.${r.nodeId}", r.name)
            .putInt("type.${r.nodeId}", r.sensorType)
            .putString("fp.${r.nodeId}", r.keyFingerprint)
            .putInt("proto.${r.nodeId}", r.protocolVersion)
            .putString("fw.${r.nodeId}", r.firmwareVersion)
            .putInt("assoc.${r.nodeId}", r.associationId)
            .apply()
    }

    fun load(nodeId: String): NodeRecord? {
        val addr = prefs.getString("addr.$nodeId", null) ?: return null
        return NodeRecord(
            nodeId = nodeId,
            address = addr,
            name = prefs.getString("name.$nodeId", null) ?: "Kernel sensor",
            sensorType = prefs.getInt("type.$nodeId", 0),
            keyFingerprint = prefs.getString("fp.$nodeId", null) ?: "",
            protocolVersion = prefs.getInt("proto.$nodeId", 1),
            firmwareVersion = prefs.getString("fw.$nodeId", null),
            associationId = prefs.getInt("assoc.$nodeId", -1),
        )
    }

    fun all(): List<NodeRecord> = ids().mapNotNull { load(it) }.sortedBy { it.name }

    fun byAddress(address: String): NodeRecord? = all().firstOrNull { it.address.equals(address, ignoreCase = true) }

    @Synchronized
    fun remove(nodeId: String) {
        val e = prefs.edit().putStringSet(IDS, ids() - nodeId)
        for (p in listOf("addr", "name", "type", "fp", "proto", "fw", "assoc", "ctr")) e.remove("$p.$nodeId")
        e.apply()
    }

    private fun ids(): Set<String> = prefs.getStringSet(IDS, emptySet())?.toSet() ?: emptySet()

    private companion object {
        const val ANDROID_KEYSTORE = "AndroidKeyStore"
        const val PREFS = "kernel_sensor_link"
        const val IDS = "node_ids"
    }
}
