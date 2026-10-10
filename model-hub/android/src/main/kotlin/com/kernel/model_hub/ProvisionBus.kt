package com.kernel.model_hub

import java.util.concurrent.ConcurrentHashMap
import java.util.concurrent.CopyOnWriteArrayList

enum class ProvisionPhaseK {
    QUEUED, WAITING_FOR_WIFI, WAITING_FOR_SPACE, DOWNLOADING, VERIFYING, INSTALLED, PAUSED, FAILED;

    val terminal: Boolean
        get() = this == INSTALLED || this == FAILED || this == PAUSED || this == WAITING_FOR_SPACE
}

data class ProvisionState(
    val entryId: String,
    val phase: ProvisionPhaseK,
    val bytesDone: Long,
    val totalBytes: Long,
    val error: String? = null,
    val path: String? = null,
)

/** A queued download: everything a job needs, serialisable to job extras. */
data class DownloadJobSpec(
    val entryId: String,
    val title: String,
    val url: String,
    val sha256: String,
    val sizeBytes: Long,
    val targetPath: String,
    val wifiOnly: Boolean,
)

/**
 * Process-wide download state shared by the jobs and the Flutter event
 * channel (pure JVM). Holds the latest state per entry and user-cancel flags.
 */
object ProvisionBus {
    private val latest = ConcurrentHashMap<String, ProvisionState>()
    private val cancelled = ConcurrentHashMap.newKeySet<String>()
    private val listeners = CopyOnWriteArrayList<(ProvisionState) -> Unit>()

    fun publish(state: ProvisionState) {
        latest[state.entryId] = state
        for (l in listeners) {
            try {
                l(state)
            } catch (_: RuntimeException) {
                // A detached listener must not break a running download.
            }
        }
    }

    fun latest(entryId: String): ProvisionState? = latest[entryId]

    fun snapshot(): List<ProvisionState> = latest.values.sortedBy { it.entryId }

    fun addListener(l: (ProvisionState) -> Unit) {
        listeners.add(l)
    }

    fun removeListener(l: (ProvisionState) -> Unit) {
        listeners.remove(l)
    }

    fun markCancelled(entryId: String) {
        cancelled.add(entryId)
    }

    fun clearCancelled(entryId: String) {
        cancelled.remove(entryId)
    }

    fun isCancelled(entryId: String): Boolean = entryId in cancelled
}
