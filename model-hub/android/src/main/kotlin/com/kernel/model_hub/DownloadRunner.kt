package com.kernel.model_hub

import java.io.File

enum class RunDecision { DONE, RESCHEDULE, STOP }

/**
 * Runs one queued download and publishes its state (pure JVM). Shared by the
 * user-initiated JobService (API 34+) and the WorkManager fallback.
 */
class DownloadRunner(
    private val downloader: ResumableDownloader,
    private val bus: ProvisionBus = ProvisionBus,
) {
    /**
     * [stopReason] returns null while the job may run, otherwise why the
     * system stopped it: [STOP_WIFI_LOST], [STOP_USER] or [STOP_SYSTEM].
     */
    fun run(
        spec: DownloadJobSpec,
        stopReason: () -> String? = { null },
        onBytes: (Long, Long) -> Unit = { _, _ -> },
    ): RunDecision {
        val target = File(spec.targetPath)
        val have = ResumableDownloader.partFile(target).length()
        bus.publish(state(spec, ProvisionPhaseK.DOWNLOADING, have))
        val outcome = downloader.download(
            DownloadSpec(spec.entryId, spec.url, spec.sha256, spec.sizeBytes, target),
            cancelled = { bus.isCancelled(spec.entryId) || stopReason() != null },
        ) { phase, done, total ->
            val p = if (phase == TransferPhase.VERIFYING) ProvisionPhaseK.VERIFYING else ProvisionPhaseK.DOWNLOADING
            bus.publish(ProvisionState(spec.entryId, p, done, total))
            onBytes(done, total)
        }
        return when (outcome) {
            is DownloadOutcome.Installed -> {
                bus.publish(
                    ProvisionState(
                        spec.entryId, ProvisionPhaseK.INSTALLED, spec.sizeBytes, spec.sizeBytes,
                        path = outcome.file.absolutePath,
                    ),
                )
                RunDecision.DONE
            }
            is DownloadOutcome.NoSpace -> {
                bus.publish(
                    state(spec, ProvisionPhaseK.WAITING_FOR_SPACE, partBytes(target), "insufficient_space"),
                )
                RunDecision.STOP
            }
            is DownloadOutcome.Failed -> if (outcome.retryable) {
                bus.publish(state(spec, ProvisionPhaseK.PAUSED, partBytes(target), outcome.reason))
                RunDecision.RESCHEDULE
            } else {
                bus.publish(state(spec, ProvisionPhaseK.FAILED, partBytes(target), outcome.reason))
                RunDecision.STOP
            }
            DownloadOutcome.Cancelled -> {
                val reason = if (bus.isCancelled(spec.entryId)) "cancelled" else stopReason() ?: STOP_SYSTEM
                val phase = if (reason == STOP_WIFI_LOST) ProvisionPhaseK.WAITING_FOR_WIFI else ProvisionPhaseK.PAUSED
                bus.publish(state(spec, phase, partBytes(target), reason))
                if (reason == "cancelled" || reason == STOP_USER) RunDecision.STOP else RunDecision.RESCHEDULE
            }
        }
    }

    private fun partBytes(target: File) = ResumableDownloader.partFile(target).length()

    private fun state(spec: DownloadJobSpec, phase: ProvisionPhaseK, done: Long, error: String? = null) =
        ProvisionState(spec.entryId, phase, done, spec.sizeBytes, error)

    companion object {
        const val STOP_WIFI_LOST = "wifi_lost"
        const val STOP_USER = "user_stopped"
        const val STOP_SYSTEM = "system_stopped"
    }
}
