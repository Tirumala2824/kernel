package com.kernel.audio_ai

import android.media.AudioDeviceInfo

/**
 * The fields of an input [AudioDeviceInfo] that the routing check uses.
 * A plain value so the selection rules are unit-testable on the JVM.
 */
data class InputDevice(val id: Int, val type: Int, val address: String)

/**
 * Grain scans are pinned to the phone's built-in microphone.
 *
 * Why: the quality-gate thresholds and the log-mel model are referenced to
 * the built-in mic with the VOICE_RECOGNITION source. A Bluetooth headset,
 * wired headset, USB mic or a paired sensor node would silently change the
 * sensitivity, frequency response and noise floor, and could make a scan
 * look valid when it was not taken at the sack. So the capture asks for the
 * built-in mic, then checks that Android really routed it there; anything
 * else is a capture error (RETRY), never a result.
 */
object MicRouting {
    /** AudioDeviceInfo.TYPE_BUILTIN_MIC. */
    const val BUILTIN_MIC_TYPE: Int = AudioDeviceInfo.TYPE_BUILTIN_MIC

    /**
     * Address of the primary (voice) built-in mic on most Android phones.
     * Other built-in mics are usually "back" (camcorder) or "top".
     */
    const val PRIMARY_ADDRESS = "bottom"

    /**
     * The built-in mic to pin: the primary "bottom" one if listed, otherwise
     * the built-in mic with the lowest id. Null when the phone lists no
     * built-in mic (the scan then fails as a capture error).
     */
    fun pickBuiltInMic(devices: List<InputDevice>): InputDevice? =
        devices
            .filter { it.type == BUILTIN_MIC_TYPE }
            .sortedWith(compareBy<InputDevice>({ if (it.address == PRIMARY_ADDRESS) 0 else 1 }, { it.id }))
            .firstOrNull()

    /**
     * True only when the active recording's device type is known and is the
     * built-in mic. An unknown route (null) is treated as not verified.
     * Any built-in mic address is accepted: the HAL may pick another
     * built-in capsule, which keeps the calibration reference.
     */
    fun isVerifiedBuiltIn(activeDeviceType: Int?): Boolean = activeDeviceType == BUILTIN_MIC_TYPE

    fun from(info: AudioDeviceInfo): InputDevice =
        InputDevice(id = info.id, type = info.type, address = info.address ?: "")
}
