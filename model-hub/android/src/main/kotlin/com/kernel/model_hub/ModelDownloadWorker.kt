package com.kernel.model_hub

import android.content.Context
import android.content.pm.ServiceInfo
import android.os.Build
import androidx.work.ForegroundInfo
import androidx.work.Worker
import androidx.work.WorkerParameters

/**
 * Fallback below API 34: a WorkManager worker promoted to a dataSync
 * foreground service while it downloads.
 */
class ModelDownloadWorker(ctx: Context, params: WorkerParameters) : Worker(ctx, params) {
    override fun doWork(): Result {
        val spec = DownloadScheduler.fromData(inputData) ?: return Result.failure()
        val notifier = DownloadNotifications(applicationContext)
        val id = notifier.idFor(spec.entryId)
        try {
            setForegroundAsync(foregroundInfo(id, notifier, spec, 0, spec.sizeBytes)).get()
        } catch (_: Exception) {
            // Foreground start can be refused (background start limits); the
            // download still runs while the worker is allowed to.
        }
        var lastUpdate = 0L
        val decision = try {
            HubServices.runner(applicationContext).run(
                spec,
                stopReason = { if (isStopped) DownloadRunner.STOP_SYSTEM else null },
            ) { done, total ->
                val now = System.currentTimeMillis()
                if (now - lastUpdate >= 1000) {
                    lastUpdate = now
                    setForegroundAsync(foregroundInfo(id, notifier, spec, done, total))
                }
            }
        } catch (_: RuntimeException) {
            ProvisionBus.publish(
                ProvisionState(spec.entryId, ProvisionPhaseK.FAILED, 0, spec.sizeBytes, "internal_error"),
            )
            RunDecision.STOP
        }
        return when (decision) {
            RunDecision.DONE -> Result.success()
            RunDecision.RESCHEDULE -> Result.retry()
            RunDecision.STOP -> Result.failure()
        }
    }

    private fun foregroundInfo(
        id: Int,
        notifier: DownloadNotifications,
        spec: DownloadJobSpec,
        done: Long,
        total: Long,
    ): ForegroundInfo {
        val n = notifier.build(spec.title, done, total)
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            ForegroundInfo(id, n, ServiceInfo.FOREGROUND_SERVICE_TYPE_DATA_SYNC)
        } else {
            ForegroundInfo(id, n)
        }
    }
}
