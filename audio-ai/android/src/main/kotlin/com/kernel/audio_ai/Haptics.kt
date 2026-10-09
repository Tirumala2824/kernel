package com.kernel.audio_ai

import android.content.Context
import android.media.AudioAttributes
import android.os.Build
import android.os.VibrationAttributes
import android.os.VibrationEffect
import android.os.Vibrator
import android.os.VibratorManager
import android.provider.Settings
import android.util.Log

/**
 * Start / finish / retry vibration cues for a scan.
 *
 * User settings are respected. On API 33+ cues use VibrationAttributes
 * USAGE_TOUCH, so the system applies the user's touch-feedback toggle and
 * intensity itself. Below 33 nothing plays when HAPTIC_FEEDBACK_ENABLED is
 * off, and cues use sonification attributes. An in-app haptics toggle is not
 * in the contract yet.
 *
 * Failures are swallowed: haptics never affect a scan result.
 */
class Haptics(private val context: Context) {

    private val vibrator: Vibrator? = try {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            context.getSystemService(VibratorManager::class.java)?.defaultVibrator
        } else {
            @Suppress("DEPRECATION")
            context.getSystemService(Context.VIBRATOR_SERVICE) as? Vibrator
        }
    } catch (e: RuntimeException) {
        null
    }

    /** One short pulse before recording. Returns true if it played (so the caller waits it out). */
    fun start(): Boolean = play(START_PATTERN)

    /** Two short pulses: recording usable. */
    fun finish(): Boolean = play(FINISH_PATTERN)

    /** Three pulses: recording unusable, scan again. */
    fun retry(): Boolean = play(RETRY_PATTERN)

    private fun play(pattern: LongArray): Boolean {
        val v = vibrator ?: return false
        return try {
            if (!v.hasVibrator() || !systemHapticsEnabled()) return false
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                v.vibrate(
                    VibrationEffect.createWaveform(pattern, NO_REPEAT),
                    VibrationAttributes.createForUsage(VibrationAttributes.USAGE_TOUCH),
                )
            } else if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                @Suppress("DEPRECATION")
                v.vibrate(VibrationEffect.createWaveform(pattern, NO_REPEAT), SONIFICATION)
            } else {
                @Suppress("DEPRECATION")
                v.vibrate(pattern, NO_REPEAT, SONIFICATION)
            }
            true
        } catch (e: RuntimeException) {
            Log.w(TAG, "haptic cue failed: ${e.javaClass.simpleName}")
            false
        }
    }

    /**
     * API 33+: USAGE_TOUCH vibrations already follow the user's touch-feedback
     * setting, so the system decides. Older releases need the explicit check.
     */
    private fun systemHapticsEnabled(): Boolean {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) return true
        return try {
            @Suppress("DEPRECATION")
            Settings.System.getInt(context.contentResolver, Settings.System.HAPTIC_FEEDBACK_ENABLED, 1) != 0
        } catch (e: RuntimeException) {
            true
        }
    }

    companion object {
        private const val TAG = "AudioAi"
        private const val NO_REPEAT = -1

        // Waveform timings: off, on, off, on... in ms.
        private val START_PATTERN = longArrayOf(0, 40)
        private val FINISH_PATTERN = longArrayOf(0, 40, 80, 40)
        private val RETRY_PATTERN = longArrayOf(0, 60, 100, 60, 100, 60)

        /**
         * Wait after the start cue before the mic opens. The phone is pressed
         * against the sack, so motor vibration would be recorded. 40 ms pulse
         * plus about 110 ms for the motor to ring down. The capture warm-up
         * discard adds another 100 ms of margin.
         */
        const val START_SETTLE_MS = 150L

        private val SONIFICATION: AudioAttributes = AudioAttributes.Builder()
            .setUsage(AudioAttributes.USAGE_ASSISTANCE_SONIFICATION)
            .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
            .build()
    }
}
