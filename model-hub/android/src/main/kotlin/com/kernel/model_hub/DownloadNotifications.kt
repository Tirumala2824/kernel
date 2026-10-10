package com.kernel.model_hub

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Context
import android.os.Build

/**
 * The ongoing notification a user-initiated job / foreground worker must
 * show. It carries the model name and progress only.
 */
class DownloadNotifications(private val ctx: Context) {
    fun idFor(entryId: String): Int = NOTIFICATION_BASE + (entryId.hashCode() and 0xFFF)

    fun build(title: String, done: Long, total: Long): Notification {
        ensureChannel()
        val b = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            Notification.Builder(ctx, CHANNEL_ID)
        } else {
            @Suppress("DEPRECATION")
            Notification.Builder(ctx)
        }
        val pct = if (total > 0) ((done * 100) / total).toInt().coerceIn(0, 100) else 0
        return b.setSmallIcon(android.R.drawable.stat_sys_download)
            .setContentTitle(ctx.getString(R.string.model_hub_download_title))
            .setContentText("$title · $pct%")
            .setProgress(100, pct, total <= 0)
            .setOngoing(true)
            .setOnlyAlertOnce(true)
            .build()
    }

    private fun ensureChannel() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val nm = ctx.getSystemService(NotificationManager::class.java) ?: return
        if (nm.getNotificationChannel(CHANNEL_ID) != null) return
        nm.createNotificationChannel(
            NotificationChannel(
                CHANNEL_ID,
                ctx.getString(R.string.model_hub_channel_name),
                NotificationManager.IMPORTANCE_LOW,
            ),
        )
    }

    companion object {
        const val CHANNEL_ID = "kernel_model_downloads"
        private const val NOTIFICATION_BASE = 0x4B48000
    }
}
