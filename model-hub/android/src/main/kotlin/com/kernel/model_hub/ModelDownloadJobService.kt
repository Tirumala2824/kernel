package com.kernel.model_hub

import android.app.job.JobParameters
import android.app.job.JobService
import android.os.Build
import java.util.concurrent.ConcurrentHashMap
import java.util.concurrent.atomic.AtomicReference

/**
 * User-initiated data-transfer job (API 34+). The user started the download
 * from the app with consent; the system shows it in the Task Manager and
 * keeps it running while the network constraint holds.
 */
class ModelDownloadJobService : JobService() {
    private val running = ConcurrentHashMap<Int, AtomicReference<String?>>()

    override fun onStartJob(params: JobParameters): Boolean {
        val spec = DownloadScheduler.fromBundle(params.extras) ?: return false
        val stop = AtomicReference<String?>(null)
        running[params.jobId] = stop
        val notifier = DownloadNotifications(this)
        val notificationId = notifier.idFor(spec.entryId)
        if (Build.VERSION.SDK_INT >= 34) {
            setNotification(
                params, notificationId, notifier.build(spec.title, 0, spec.sizeBytes),
                JOB_END_NOTIFICATION_POLICY_REMOVE,
            )
        }
        Thread({
            var lastUpdate = 0L
            val decision = try {
                HubServices.runner(applicationContext).run(spec, stopReason = { stop.get() }) { done, total ->
                    val now = System.currentTimeMillis()
                    if (Build.VERSION.SDK_INT >= 34 && now - lastUpdate >= NOTIFY_INTERVAL_MS) {
                        lastUpdate = now
                        try {
                            setNotification(
                                params, notificationId, notifier.build(spec.title, done, total),
                                JOB_END_NOTIFICATION_POLICY_REMOVE,
                            )
                            updateTransferredNetworkBytes(params, done, 0)
                        } catch (_: RuntimeException) {
                            // The job was stopped meanwhile.
                        }
                    }
                }
            } catch (_: RuntimeException) {
                ProvisionBus.publish(
                    ProvisionState(spec.entryId, ProvisionPhaseK.FAILED, 0, spec.sizeBytes, "internal_error"),
                )
                RunDecision.STOP
            }
            running.remove(params.jobId)
            if (stop.get() == null) jobFinished(params, decision == RunDecision.RESCHEDULE)
        }, "model-hub-download").start()
        return true
    }

    override fun onStopJob(params: JobParameters): Boolean {
        val reason = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            when (params.stopReason) {
                JobParameters.STOP_REASON_CONSTRAINT_CONNECTIVITY -> DownloadRunner.STOP_WIFI_LOST
                JobParameters.STOP_REASON_USER -> DownloadRunner.STOP_USER
                else -> DownloadRunner.STOP_SYSTEM
            }
        } else {
            DownloadRunner.STOP_SYSTEM
        }
        running[params.jobId]?.set(reason)
        val entryId = params.extras.getString("entryId")
        val userCancelled = entryId != null && ProvisionBus.isCancelled(entryId)
        // Reschedule unless the user stopped it; the .part file resumes.
        return reason != DownloadRunner.STOP_USER && !userCancelled
    }

    private companion object {
        const val NOTIFY_INTERVAL_MS = 1000L
    }
}
