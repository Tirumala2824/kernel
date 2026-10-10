package com.kernel.audio_ai

import android.media.AudioDeviceInfo
import org.junit.jupiter.api.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertNull
import kotlin.test.assertTrue

class MicRoutingTest {
    private fun dev(id: Int, type: Int, address: String = "") = InputDevice(id, type, address)

    @Test
    fun builtInMicTypeIsTheSdkConstant() {
        assertEquals(15, MicRouting.BUILTIN_MIC_TYPE)
        assertEquals(AudioDeviceInfo.TYPE_BUILTIN_MIC, MicRouting.BUILTIN_MIC_TYPE)
    }

    @Test
    fun picksTheBuiltInMicOverHeadsetsAndBluetooth() {
        val devices = listOf(
            dev(3, AudioDeviceInfo.TYPE_BLUETOOTH_SCO, "AA:BB:CC:DD:EE:FF"),
            dev(7, AudioDeviceInfo.TYPE_WIRED_HEADSET),
            dev(9, AudioDeviceInfo.TYPE_USB_DEVICE),
            dev(12, AudioDeviceInfo.TYPE_BUILTIN_MIC, "back"),
            dev(4, AudioDeviceInfo.TYPE_BLE_HEADSET),
        )
        assertEquals(12, MicRouting.pickBuiltInMic(devices)?.id)
    }

    @Test
    fun prefersThePrimaryBottomMic() {
        val devices = listOf(
            dev(20, AudioDeviceInfo.TYPE_BUILTIN_MIC, "back"),
            dev(25, AudioDeviceInfo.TYPE_BUILTIN_MIC, "bottom"),
            dev(21, AudioDeviceInfo.TYPE_BUILTIN_MIC, "top"),
        )
        assertEquals(25, MicRouting.pickBuiltInMic(devices)?.id)
    }

    @Test
    fun withoutAPrimaryAddressTheLowestIdWins() {
        val devices = listOf(
            dev(31, AudioDeviceInfo.TYPE_BUILTIN_MIC, "back"),
            dev(30, AudioDeviceInfo.TYPE_BUILTIN_MIC, ""),
        )
        assertEquals(30, MicRouting.pickBuiltInMic(devices)?.id)
    }

    @Test
    fun noBuiltInMicMeansNoSelection() {
        assertNull(MicRouting.pickBuiltInMic(emptyList()))
        assertNull(
            MicRouting.pickBuiltInMic(
                listOf(
                    dev(1, AudioDeviceInfo.TYPE_WIRED_HEADSET),
                    dev(2, AudioDeviceInfo.TYPE_BLUETOOTH_SCO),
                    dev(3, AudioDeviceInfo.TYPE_TELEPHONY),
                ),
            ),
        )
    }

    @Test
    fun onlyAnActiveBuiltInRouteIsVerified() {
        assertTrue(MicRouting.isVerifiedBuiltIn(AudioDeviceInfo.TYPE_BUILTIN_MIC))
        assertFalse(MicRouting.isVerifiedBuiltIn(null), "an unknown route is not verified")
        assertFalse(MicRouting.isVerifiedBuiltIn(AudioDeviceInfo.TYPE_WIRED_HEADSET))
        assertFalse(MicRouting.isVerifiedBuiltIn(AudioDeviceInfo.TYPE_BLUETOOTH_SCO))
        assertFalse(MicRouting.isVerifiedBuiltIn(AudioDeviceInfo.TYPE_USB_HEADSET))
        assertFalse(MicRouting.isVerifiedBuiltIn(AudioDeviceInfo.TYPE_REMOTE_SUBMIX))
    }
}
