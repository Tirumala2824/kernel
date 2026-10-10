package com.kernel.sensor_link

import android.app.Activity
import android.content.Context
import com.kernel.sensor_link.auth.NodeRecord
import com.kernel.sensor_link.auth.keyFingerprint
import com.kernel.sensor_link.cdm.Association
import com.kernel.sensor_link.cdm.CompanionPairing
import com.kernel.sensor_link.link.AuthFailedException
import com.kernel.sensor_link.link.LinkException
import com.kernel.sensor_link.link.LinkManager
import com.kernel.sensor_link.protocol.Cp
import com.kernel.sensor_link.protocol.CpStatus
import java.util.UUID
import kotlinx.coroutines.withTimeoutOrNull

/**
 * Pigeon host implementation. Radio failures surface as SensorApiError with a
 * stable code; the Dart side maps them to SensorStatus and never shows them as
 * "nothing detected".
 */
class SensorHostApiImpl(
    private val context: Context,
    private val pairing: CompanionPairing,
    private val activity: () -> Activity?,
) : SensorHostApi {
    private val vault = LinkManager.init(context)

    private fun info(r: NodeRecord) = NativeNodeInfo(
        nodeId = r.nodeId,
        address = r.address,
        name = r.name,
        sensorType = r.sensorType.toLong(),
        keyFingerprint = r.keyFingerprint,
        protocolVersion = r.protocolVersion.toLong(),
        firmwareVersion = r.firmwareVersion,
    )

    private inline fun <T> radio(block: () -> T): T = try {
        block()
    } catch (e: SensorApiError) {
        throw e
    } catch (e: AuthFailedException) {
        throw SensorApiError("auth_failed", e.message)
    } catch (e: LinkException) {
        throw SensorApiError("link", e.message)
    } catch (e: IllegalStateException) {
        throw SensorApiError(e.message ?: "state", e.message)
    } catch (e: kotlinx.coroutines.TimeoutCancellationException) {
        throw SensorApiError("timeout", e.message)
    }

    override suspend fun associate(qrPayload: String): NativeNodeInfo? {
        val label = try {
            QrLabel.parse(qrPayload)
        } catch (e: QrFormatException) {
            throw SensorApiError("invalid_qr", e.reason)
        }
        try {
            val act = activity() ?: throw SensorApiError("no_activity", "association needs a visible activity")
            val assoc = radio { pairing.associate(act, label.address) } ?: return null
            val nodeId = UUID.nameUUIDFromBytes("kernel-sensor:${label.address}".toByteArray()).toString()
            val fingerprint = keyFingerprint(label.key)
            LinkManager.drop(nodeId)
            vault.importKey(nodeId, label.key) // zeroes label.key
            val record = NodeRecord(
                nodeId = nodeId,
                address = label.address,
                name = "Kernel-" + label.address.takeLast(5).replace(":", ""),
                sensorType = label.sensorType,
                keyFingerprint = fingerprint,
                protocolVersion = 1,
                firmwareVersion = null,
                associationId = assoc.associationId,
            )
            vault.save(record)
            LinkManager.observePresence(pairing, assoc.address, assoc.associationId)
            // Verify the key and read DeviceInfo now; a failure here is not fatal
            // (the node may be out of range), the link retries on demand.
            withTimeoutOrNull(FIRST_CONNECT_MS) { runCatching { LinkManager.link(nodeId).ensureConnected() } }
            return info(vault.load(nodeId) ?: record)
        } finally {
            label.wipe()
        }
    }

    override suspend fun forget(nodeId: String) {
        val r = vault.load(nodeId)
        LinkManager.stopSession(context, nodeId)
        LinkManager.clearBond(nodeId)
        LinkManager.drop(nodeId)
        if (r != null) {
            val a = Association(r.address, r.associationId)
            pairing.stopObserving(a)
            pairing.disassociate(a)
        }
        vault.deleteKey(nodeId)
        vault.remove(nodeId)
    }

    override fun knownNodes(): List<NativeNodeInfo> = vault.all().map(::info)

    override suspend fun connect(nodeId: String) = radio { LinkManager.link(nodeId).ensureConnected() }

    override suspend fun disconnect(nodeId: String) {
        if (LinkManager.hasSession(nodeId)) return // the session owns the link
        LinkManager.existingLink(nodeId)?.disconnect()
    }

    override suspend fun syncEvents(nodeId: String, sinceSeq: Long): NativeSyncResult = radio {
        val l = LinkManager.link(nodeId)
        l.ensureConnected()
        l.syncSince(sinceSeq)
    }

    override suspend fun startSurvey(nodeId: String, durationS: Long) = radio {
        val l = LinkManager.link(nodeId)
        l.ensureConnected()
        val r = l.control(Cp.startSurvey(durationS.toInt()))
        if (r.status != CpStatus.OK) throw SensorApiError("refused", "START_SURVEY status ${r.status}")
    }

    override suspend fun startSession(nodeId: String) = radio { LinkManager.startSession(context, nodeId) }

    override suspend fun stopSession(nodeId: String) = radio { LinkManager.stopSession(context, nodeId) }

    override suspend fun setLiveBands(nodeId: String, enabled: Boolean) = radio {
        val l = LinkManager.link(nodeId)
        if (enabled) {
            l.setLiveBands(true)
            l.ensureConnected()
        } else {
            l.setLiveBands(false)
        }
    }

    override suspend fun requestSnippet(nodeId: String, eventSeq: Long): NativeSnippet? = radio {
        val l = LinkManager.link(nodeId)
        l.ensureConnected()
        l.requestSnippet(eventSeq)
    }

    private companion object {
        const val FIRST_CONNECT_MS = 60_000L
    }
}
