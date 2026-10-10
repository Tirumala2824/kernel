package com.kernel.sensor_link.link

import android.content.Context
import com.kernel.sensor_link.NativeLinkState
import com.kernel.sensor_link.SensorFlutterApi
import com.kernel.sensor_link.auth.KeyVault
import com.kernel.sensor_link.cdm.Association
import com.kernel.sensor_link.cdm.CompanionPairing
import com.kernel.sensor_link.protocol.Cp
import com.kernel.sensor_link.protocol.CpStatus
import com.kernel.sensor_link.protocol.ProtocolException
import com.kernel.sensor_link.protocol.WireEvent
import com.kernel.sensor_link.scan.PresenceScanner
import com.kernel.sensor_link.session.SensorSessionService
import java.util.concurrent.ConcurrentHashMap
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch

/**
 * Process-wide owner of node links and sessions, shared by the Flutter plugin,
 * the session foreground service and the companion presence service.
 * Everything forwarded to Dart is protocol bytes (features only).
 */
object LinkManager : LinkEvents {
    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.Main)
    private val links = ConcurrentHashMap<String, NodeLink>()
    private val sessions = ConcurrentHashMap<String, SessionStats>()
    private val reconnectJobs = ConcurrentHashMap<String, Job>()
    @Volatile private var appContext: Context? = null
    @Volatile private var vault: KeyVault? = null

    /** Set while a Flutter engine is attached; null otherwise. */
    @Volatile var flutterApi: SensorFlutterApi? = null

    /** True while the host activity is resumed (sessions may only start then). */
    @Volatile var appVisible: Boolean = false

    fun init(context: Context): KeyVault {
        appContext = context.applicationContext
        return vault ?: KeyVault(context.applicationContext).also { vault = it }
    }

    fun vault(): KeyVault = vault ?: throw IllegalStateException("LinkManager.init not called")

    fun link(nodeId: String): NodeLink {
        val ctx = appContext ?: throw IllegalStateException("LinkManager.init not called")
        val record = vault().load(nodeId) ?: throw LinkException("unknown node $nodeId")
        return links.getOrPut(nodeId) { NodeLink(ctx, record, vault(), this) }
    }

    fun existingLink(nodeId: String): NodeLink? = links[nodeId]

    fun drop(nodeId: String) {
        reconnectJobs.remove(nodeId)?.cancel()
        sessions.remove(nodeId)
        links.remove(nodeId)?.disconnect()
    }

    // ------------------------------------------------------------ sessions

    fun hasSession(nodeId: String) = sessions.containsKey(nodeId)

    suspend fun startSession(context: Context, nodeId: String) {
        if (!appVisible) throw IllegalStateException("not_visible")
        val l = link(nodeId)
        sessions.putIfAbsent(nodeId, SessionStats(System.currentTimeMillis()))
        SensorSessionService.start(context.applicationContext)
        try {
            l.ensureConnected()
            l.control(Cp.startSession(if (l.liveBands) Cp.SESSION_LIVE_BANDS else 0))
        } catch (e: Exception) {
            // The session stays up and keeps retrying; state reaches Dart via onLinkState.
            scheduleReconnect(nodeId)
        }
        updatePresenceScan()
    }

    suspend fun stopSession(context: Context, nodeId: String) {
        sessions.remove(nodeId)
        reconnectJobs.remove(nodeId)?.cancel()
        links[nodeId]?.let { l ->
            if (l.connected && l.authenticated) runCatching { l.control(Cp.stopSession()) }
        }
        if (sessions.isEmpty()) SensorSessionService.stop(context.applicationContext)
        updatePresenceScan()
    }

    fun stopAllSessions(context: Context) {
        val ids = sessions.keys.toList()
        scope.launch { ids.forEach { stopSession(context, it) } }
    }

    fun sessionSummary(nowMs: Long): String {
        val s = sessions.values.toList()
        if (s.isEmpty()) return "No active sensor session"
        val total = s.sumOf { it.events }
        val oldest = s.maxOf { it.minutes(nowMs) }
        val agg = SessionStats(nowMs - oldest * 60_000L)
        repeat(total) { agg.onEvent() }
        return (if (s.size > 1) "${s.size} nodes: " else "") + agg.summary(nowMs)
    }

    private fun scheduleReconnect(nodeId: String) {
        if (!hasSession(nodeId) || reconnectJobs[nodeId]?.isActive == true) return
        reconnectJobs[nodeId] = scope.launch {
            var attempt = 0
            while (hasSession(nodeId)) {
                delay(Backoff.delayMs(attempt++))
                val l = links[nodeId] ?: break
                if (l.connected && l.authenticated) break
                try {
                    l.ensureConnected()
                    l.control(Cp.startSession(if (l.liveBands) Cp.SESSION_LIVE_BANDS else 0))
                    break
                } catch (_: AuthFailedException) {
                    break // wrong key: do not hammer the node
                } catch (_: Exception) {
                    // keep backing off
                }
            }
            reconnectJobs.remove(nodeId)
            updatePresenceScan()
        }
    }

    private fun updatePresenceScan() {
        val ctx = appContext ?: return
        val waiting = sessions.keys.mapNotNull { id -> links[id]?.takeIf { !it.connected }?.record?.address }
        if (waiting.isEmpty()) PresenceScanner.stop(ctx) else PresenceScanner.start(ctx, waiting)
    }

    // ------------------------------------------------------------ presence

    fun onPresence(context: Context, address: String, present: Boolean) {
        init(context)
        val record = vault().byAddress(address) ?: return
        if (present && hasSession(record.nodeId)) {
            reconnectJobs.remove(record.nodeId)?.cancel()
            scope.launch {
                runCatching { link(record.nodeId).ensureConnected() }.onFailure { scheduleReconnect(record.nodeId) }
            }
        }
    }

    fun onPresenceAssociation(context: Context, associationId: Int, present: Boolean) {
        init(context)
        val record = vault().all().firstOrNull { it.associationId == associationId } ?: return
        onPresence(context, record.address, present)
    }

    fun observePresence(pairing: CompanionPairing, address: String, associationId: Int) =
        pairing.observePresence(Association(address, associationId))

    // --------------------------------------------------- LinkEvents -> Dart

    private fun post(block: suspend SensorFlutterApi.() -> Unit) {
        val api = flutterApi ?: return
        scope.launch { runCatching { api.block() } }
    }

    override fun onState(nodeId: String, state: NativeLinkState, rssi: Int?, authFailed: Boolean) {
        if (state == NativeLinkState.DISCONNECTED || state == NativeLinkState.ERROR) {
            if (!authFailed) scope.launch { scheduleReconnect(nodeId) }
            scope.launch { updatePresenceScan() }
        }
        post { onLinkState(nodeId, state, rssi?.toLong(), authFailed) }
    }

    override fun onDeviceInfo(nodeId: String, bytes: ByteArray) {
        links[nodeId]?.deviceInfo?.let { info ->
            val r = vault().load(nodeId)
            if (r != null && r.firmwareVersion != info.firmwareVersion) {
                val updated = r.copy(firmwareVersion = info.firmwareVersion, protocolVersion = info.protoMajor)
                vault().save(updated)
                links[nodeId]?.record = updated
            }
        }
        post { onDeviceInfo(nodeId, bytes) }
    }

    override fun onBandTable(nodeId: String, bytes: ByteArray) = post { onBandTable(nodeId, bytes) }

    override fun onStatus(nodeId: String, bytes: ByteArray) {
        val at = System.currentTimeMillis()
        post { onStatus(nodeId, bytes, at) }
    }

    override fun onBandFrame(nodeId: String, bytes: ByteArray) = post { onBandFrame(nodeId, bytes) }

    override fun onEvent(nodeId: String, bytes: ByteArray) {
        val at = System.currentTimeMillis()
        sessions[nodeId]?.let { stats ->
            // Count only well-formed events for the notification rate.
            try {
                WireEvent.decode(bytes)
                stats.onEvent()
            } catch (_: ProtocolException) {
            }
        }
        post { onEvent(nodeId, bytes, at) }
    }

    override suspend fun lastSeq(nodeId: String): Long {
        val api = flutterApi ?: return LinkEvents.NO_SYNC
        return try {
            api.lastSeq(nodeId) ?: 0L
        } catch (_: Exception) {
            LinkEvents.NO_SYNC
        }
    }

    /** Used by forget(): ask the node to drop this phone's bond, best effort. */
    suspend fun clearBond(nodeId: String) {
        val l = links[nodeId] ?: return
        if (l.connected && l.authenticated) {
            runCatching {
                val r = l.control(Cp.clearBond())
                r.status == CpStatus.OK
            }
        }
    }
}
