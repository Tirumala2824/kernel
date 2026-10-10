package com.kernel.model_hub

import android.app.job.JobInfo
import android.app.job.JobScheduler
import android.content.ComponentName
import android.content.Context
import android.net.NetworkCapabilities
import android.net.NetworkRequest
import android.os.Build
import android.os.PersistableBundle
import androidx.work.BackoffPolicy
import androidx.work.Constraints
import androidx.work.Data
import androidx.work.ExistingWorkPolicy
import androidx.work.NetworkType
import androidx.work.OneTimeWorkRequest
import androidx.work.WorkInfo
import androidx.work.WorkManager
import java.io.File
import java.util.concurrent.TimeUnit

/**
 * One unique job per catalog entry (KEEP: an entry already queued or running
 * is never scheduled twice).
 *
 * - API 34+: a user-initiated data-transfer job (setUserInitiated), with a
 *   NOT_METERED network requirement when Wi-Fi only, and the estimated bytes.
 * - Below 34, or if the system refuses the user-initiated job: WorkManager
 *   with a dataSync foreground worker.
 */
class DownloadScheduler(private val ctx: Context) {
    fun enqueue(spec: DownloadJobSpec): ProvisionState {
        ProvisionBus.clearCancelled(spec.entryId)
        val current = ProvisionBus.latest(spec.entryId)
        if (isPending(spec.entryId)) {
            // KEEP: the existing job runs (or resumes after its backoff).
            if (current != null && !current.phase.terminal) return current
            return waitingState(spec).also(ProvisionBus::publish)
        }

        val scheduled = Build.VERSION.SDK_INT >= 34 && scheduleUserInitiated(spec)
        if (!scheduled) scheduleWork(spec)
        return waitingState(spec).also(ProvisionBus::publish)
    }

    private fun waitingState(spec: DownloadJobSpec): ProvisionState {
        val network = DeviceProbe.network(ctx)
        val waiting = !network.connected || (spec.wifiOnly && !network.unmetered)
        val phase = if (waiting && spec.wifiOnly) ProvisionPhaseK.WAITING_FOR_WIFI else ProvisionPhaseK.QUEUED
        val have = ResumableDownloader.partFile(File(spec.targetPath)).length()
        return ProvisionState(spec.entryId, phase, have, spec.sizeBytes)
    }

    fun cancel(entryId: String) {
        ProvisionBus.markCancelled(entryId)
        if (Build.VERSION.SDK_INT >= 34) {
            findJobId(entryId)?.let { jobScheduler()?.cancel(it) }
        }
        WorkManager.getInstance(ctx).cancelUniqueWork(uniqueName(entryId))
        val last = ProvisionBus.latest(entryId)
        if (last != null && !last.phase.terminal) {
            ProvisionBus.publish(last.copy(phase = ProvisionPhaseK.PAUSED, error = "cancelled"))
        }
    }

    fun isPending(entryId: String): Boolean {
        if (Build.VERSION.SDK_INT >= 34 && findJobId(entryId) != null) return true
        return try {
            WorkManager.getInstance(ctx).getWorkInfosForUniqueWork(uniqueName(entryId)).get()
                .any { !it.state.isFinished && it.state != WorkInfo.State.CANCELLED }
        } catch (_: Exception) {
            false
        }
    }

    private fun jobScheduler(): JobScheduler? = ctx.getSystemService(JobScheduler::class.java)

    /** The pending job id holding [entryId], probing the small hash bucket. */
    private fun findJobId(entryId: String): Int? {
        val js = jobScheduler() ?: return null
        for (i in 0 until PROBE) {
            val id = jobIdFor(entryId, i)
            val job = js.getPendingJob(id) ?: continue
            if (job.extras.getString(KEY_ENTRY) == entryId) return id
        }
        return null
    }

    private fun freeJobId(entryId: String): Int? {
        val js = jobScheduler() ?: return null
        for (i in 0 until PROBE) {
            val id = jobIdFor(entryId, i)
            if (js.getPendingJob(id) == null) return id
        }
        return null
    }

    private fun scheduleUserInitiated(spec: DownloadJobSpec): Boolean {
        if (Build.VERSION.SDK_INT < 34) return false
        val js = jobScheduler() ?: return false
        val id = freeJobId(spec.entryId) ?: return false
        val network = NetworkRequest.Builder()
            .addCapability(NetworkCapabilities.NET_CAPABILITY_INTERNET)
            .removeCapability(NetworkCapabilities.NET_CAPABILITY_NOT_VPN)
            .apply { if (spec.wifiOnly) addCapability(NetworkCapabilities.NET_CAPABILITY_NOT_METERED) }
            .build()
        val remaining = (spec.sizeBytes - ResumableDownloader.partFile(File(spec.targetPath)).length())
            .coerceAtLeast(0)
        return try {
            val info = JobInfo.Builder(id, ComponentName(ctx, ModelDownloadJobService::class.java))
                .setUserInitiated(true)
                .setRequiredNetwork(network)
                .setEstimatedNetworkBytes(remaining, 0)
                .setExtras(spec.toBundle())
                .build()
            js.schedule(info) == JobScheduler.RESULT_SUCCESS
        } catch (_: RuntimeException) {
            // e.g. not allowed while the app is not visible: use WorkManager.
            false
        }
    }

    private fun scheduleWork(spec: DownloadJobSpec) {
        val constraints = Constraints.Builder()
            .setRequiredNetworkType(if (spec.wifiOnly) NetworkType.UNMETERED else NetworkType.CONNECTED)
            .build()
        val request = OneTimeWorkRequest.Builder(ModelDownloadWorker::class.java)
            .setConstraints(constraints)
            .setInputData(spec.toData())
            .setBackoffCriteria(BackoffPolicy.EXPONENTIAL, 30, TimeUnit.SECONDS)
            .addTag(TAG)
            .build()
        WorkManager.getInstance(ctx)
            .enqueueUniqueWork(uniqueName(spec.entryId), ExistingWorkPolicy.KEEP, request)
    }

    companion object {
        const val TAG = "kernel_model_hub"
        private const val KEY_ENTRY = "entryId"
        private const val KEY_TITLE = "title"
        private const val KEY_URL = "url"
        private const val KEY_SHA = "sha256"
        private const val KEY_SIZE = "sizeBytes"
        private const val KEY_TARGET = "targetPath"
        private const val KEY_WIFI = "wifiOnly"
        private const val JOB_ID_BASE = 0x4B480000
        private const val PROBE = 8

        fun uniqueName(entryId: String) = "model_hub:$entryId"

        fun jobIdFor(entryId: String, probe: Int): Int =
            JOB_ID_BASE + (((entryId.hashCode() and 0xFFFF) + probe) and 0xFFFF)

        fun DownloadJobSpec.toBundle() = PersistableBundle().apply {
            putString(KEY_ENTRY, entryId)
            putString(KEY_TITLE, title)
            putString(KEY_URL, url)
            putString(KEY_SHA, sha256)
            putLong(KEY_SIZE, sizeBytes)
            putString(KEY_TARGET, targetPath)
            putInt(KEY_WIFI, if (wifiOnly) 1 else 0)
        }

        fun fromBundle(b: PersistableBundle?): DownloadJobSpec? {
            if (b == null) return null
            return DownloadJobSpec(
                entryId = b.getString(KEY_ENTRY) ?: return null,
                title = b.getString(KEY_TITLE) ?: "",
                url = b.getString(KEY_URL) ?: return null,
                sha256 = b.getString(KEY_SHA) ?: return null,
                sizeBytes = b.getLong(KEY_SIZE, -1).takeIf { it > 0 } ?: return null,
                targetPath = b.getString(KEY_TARGET) ?: return null,
                wifiOnly = b.getInt(KEY_WIFI, 1) == 1,
            )
        }

        fun DownloadJobSpec.toData(): Data = Data.Builder()
            .putString(KEY_ENTRY, entryId)
            .putString(KEY_TITLE, title)
            .putString(KEY_URL, url)
            .putString(KEY_SHA, sha256)
            .putLong(KEY_SIZE, sizeBytes)
            .putString(KEY_TARGET, targetPath)
            .putBoolean(KEY_WIFI, wifiOnly)
            .build()

        fun fromData(d: Data): DownloadJobSpec? = DownloadJobSpec(
            entryId = d.getString(KEY_ENTRY) ?: return null,
            title = d.getString(KEY_TITLE) ?: "",
            url = d.getString(KEY_URL) ?: return null,
            sha256 = d.getString(KEY_SHA) ?: return null,
            sizeBytes = d.getLong(KEY_SIZE, -1).takeIf { it > 0 } ?: return null,
            targetPath = d.getString(KEY_TARGET) ?: return null,
            wifiOnly = d.getBoolean(KEY_WIFI, true),
        )
    }
}
