package com.kernel.sensor_link.session

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.pm.ServiceInfo
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import com.kernel.sensor_link.R
import com.kernel.sensor_link.link.LinkManager

/**
 * `connectedDevice` foreground service that keeps sensor sessions alive (overnight
 * allowed). [start] refuses unless the app is visible; the service never starts
 * itself from the background. The notification reports a rate only
 * ("N signals in M minutes (experimental)"), never a verdict.
 */
class SensorSessionService : Service() {
    private val handler = Handler(Looper.getMainLooper())
    private val tick = object : Runnable {
        override fun run() {
            refresh()
            handler.postDelayed(this, REFRESH_MS)
        }
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (intent?.action == ACTION_STOP) {
            LinkManager.stopAllSessions(applicationContext)
            stopSelf()
            return START_NOT_STICKY
        }
        ensureChannel()
        val n = build()
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            startForeground(NOTIFICATION_ID, n, ServiceInfo.FOREGROUND_SERVICE_TYPE_CONNECTED_DEVICE)
        } else {
            startForeground(NOTIFICATION_ID, n)
        }
        handler.removeCallbacks(tick)
        handler.postDelayed(tick, REFRESH_MS)
        // Not sticky: after a kill the user restarts the session from the app.
        return START_NOT_STICKY
    }

    override fun onDestroy() {
        handler.removeCallbacks(tick)
        super.onDestroy()
    }

    private fun refresh() {
        val nm = getSystemService(NotificationManager::class.java) ?: return
        nm.notify(NOTIFICATION_ID, build())
    }

    private fun ensureChannel() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val nm = getSystemService(NotificationManager::class.java) ?: return
        if (nm.getNotificationChannel(CHANNEL_ID) == null) {
            nm.createNotificationChannel(
                NotificationChannel(CHANNEL_ID, "Sensor sessions", NotificationManager.IMPORTANCE_LOW).apply {
                    description = "Shown while Kernel listens to a paired sensor node"
                    setShowBadge(false)
                },
            )
        }
    }

    private fun build(): Notification {
        val stop = PendingIntent.getService(
            this,
            1,
            Intent(this, SensorSessionService::class.java).setAction(ACTION_STOP),
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT,
        )
        val open = packageManager.getLaunchIntentForPackage(packageName)?.let {
            PendingIntent.getActivity(this, 2, it, PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT)
        }
        val builder = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            Notification.Builder(this, CHANNEL_ID)
        } else {
            @Suppress("DEPRECATION")
            Notification.Builder(this)
        }
        return builder
            .setSmallIcon(R.drawable.ic_stat_kernel_sensor)
            .setContentTitle("Sensor session")
            .setContentText(LinkManager.sessionSummary(System.currentTimeMillis()))
            .setOngoing(true)
            .setOnlyAlertOnce(true)
            .setContentIntent(open)
            .addAction(Notification.Action.Builder(null, "Stop", stop).build())
            .build()
    }

    companion object {
        private const val CHANNEL_ID = "kernel_sensor_sessions"
        private const val NOTIFICATION_ID = 0x4B53
        private const val REFRESH_MS = 60_000L
        private const val ACTION_STOP = "com.kernel.sensor_link.STOP_SESSIONS"

        /** Starts the service; the caller must have checked that the app is visible. */
        fun start(context: Context) {
            val i = Intent(context, SensorSessionService::class.java)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) context.startForegroundService(i) else context.startService(i)
        }

        fun stop(context: Context) {
            context.stopService(Intent(context, SensorSessionService::class.java))
        }
    }
}
