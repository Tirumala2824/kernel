package com.kernel.sensor_link.cdm

import android.annotation.TargetApi
import android.companion.AssociationInfo
import android.companion.CompanionDeviceService
import android.companion.DevicePresenceEvent
import com.kernel.sensor_link.link.LinkManager

/**
 * Bound by the system when an associated node appears or disappears
 * (startObservingDevicePresence). It only nudges [LinkManager] to reconnect a
 * node that has an active session; it never starts a foreground service, so
 * sessions still start only while the app is visible.
 */
@TargetApi(31)
class KernelCompanionService : CompanionDeviceService() {
    @Deprecated("API 31-32 path")
    @Suppress("OVERRIDE_DEPRECATION")
    override fun onDeviceAppeared(address: String) {
        LinkManager.onPresence(applicationContext, address, present = true)
    }

    @Deprecated("API 31-32 path")
    @Suppress("OVERRIDE_DEPRECATION")
    override fun onDeviceDisappeared(address: String) {
        LinkManager.onPresence(applicationContext, address, present = false)
    }

    @Deprecated("API 33-35 path")
    @Suppress("OVERRIDE_DEPRECATION")
    override fun onDeviceAppeared(associationInfo: AssociationInfo) {
        associationInfo.deviceMacAddress?.let { LinkManager.onPresence(applicationContext, it.toString(), present = true) }
    }

    @Deprecated("API 33-35 path")
    @Suppress("OVERRIDE_DEPRECATION")
    override fun onDeviceDisappeared(associationInfo: AssociationInfo) {
        associationInfo.deviceMacAddress?.let { LinkManager.onPresence(applicationContext, it.toString(), present = false) }
    }

    @TargetApi(36)
    override fun onDevicePresenceEvent(event: DevicePresenceEvent) {
        val present = when (event.event) {
            DevicePresenceEvent.EVENT_BLE_APPEARED, DevicePresenceEvent.EVENT_BT_CONNECTED -> true
            DevicePresenceEvent.EVENT_BLE_DISAPPEARED, DevicePresenceEvent.EVENT_BT_DISCONNECTED -> false
            else -> return
        }
        LinkManager.onPresenceAssociation(applicationContext, event.associationId, present)
    }
}
