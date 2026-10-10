package com.kernel.sense_ai

import android.content.Context
import android.hardware.Sensor
import android.hardware.SensorEvent
import android.hardware.SensorEventListener
import android.hardware.SensorManager
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.os.PowerManager
import android.os.SystemClock
import kotlin.math.max
import kotlin.math.sqrt

/** Peak gyroscope rotation rate (rad/s) between Stage-0 frames. */
class GyroMonitor(context: Context) : SensorEventListener {
    private val manager = context.getSystemService(SensorManager::class.java)
    private val sensor: Sensor? = manager?.getDefaultSensor(Sensor.TYPE_GYROSCOPE)
    private val lock = Any()
    private var peak = 0.0
    private var latest = 0.0
    private var running = false

    val available: Boolean get() = sensor != null

    fun start() {
        val s = sensor ?: return
        if (running) return
        running = manager?.registerListener(this, s, SensorManager.SENSOR_DELAY_GAME) == true
    }

    fun stop() {
        if (!running) return
        manager?.unregisterListener(this)
        running = false
        synchronized(lock) {
            peak = 0.0
            latest = 0.0
        }
    }

    /** Peak since the last call; null without a gyroscope (no gating). */
    fun takePeak(): Double? {
        if (sensor == null) return null
        synchronized(lock) {
            val p = max(peak, latest)
            peak = 0.0
            return p
        }
    }

    override fun onSensorChanged(event: SensorEvent) {
        val v = event.values
        val m = sqrt((v[0] * v[0] + v[1] * v[1] + v[2] * v[2]).toDouble())
        synchronized(lock) {
            latest = m
            if (m > peak) peak = m
        }
    }

    override fun onAccuracyChanged(sensor: Sensor?, accuracy: Int) = Unit
}

/**
 * Polls PowerManager.getThermalHeadroom (API 30+) at most every
 * [ThermalPolicy.POLL_INTERVAL_MS] on the main thread while started.
 */
class ThermalMonitor(context: Context, private val onReading: (Double?) -> Unit) {
    private val power = context.getSystemService(PowerManager::class.java)
    private val main = Handler(Looper.getMainLooper())
    private var running = false
    private var lastPollAt = Long.MIN_VALUE / 2

    @Volatile
    var lastHeadroom: Double? = null
        private set

    private val tick = object : Runnable {
        override fun run() {
            if (!running) return
            lastPollAt = SystemClock.elapsedRealtime()
            val h = read()
            lastHeadroom = h
            onReading(h)
            main.postDelayed(this, ThermalPolicy.POLL_INTERVAL_MS)
        }
    }

    fun start() {
        if (running) return
        running = true
        val wait = ThermalPolicy.POLL_INTERVAL_MS - (SystemClock.elapsedRealtime() - lastPollAt)
        main.postDelayed(tick, wait.coerceAtLeast(0))
    }

    fun stop() {
        running = false
        main.removeCallbacks(tick)
    }

    private fun read(): Double? {
        if (Build.VERSION.SDK_INT < 30) return null
        return try {
            power?.getThermalHeadroom(10)?.toDouble()?.takeUnless { it.isNaN() }
        } catch (_: RuntimeException) {
            null
        }
    }
}
