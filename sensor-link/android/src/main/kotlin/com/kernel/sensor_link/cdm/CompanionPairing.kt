package com.kernel.sensor_link.cdm

import android.annotation.SuppressLint
import android.app.Activity
import android.bluetooth.BluetoothDevice
import android.bluetooth.le.ScanFilter
import android.bluetooth.le.ScanResult
import android.companion.AssociationInfo
import android.companion.AssociationRequest
import android.companion.BluetoothLeDeviceFilter
import android.companion.CompanionDeviceManager
import android.companion.ObservingDevicePresenceRequest
import android.content.Context
import android.content.Intent
import android.content.IntentSender
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.os.ParcelUuid
import android.annotation.TargetApi
import com.kernel.sensor_link.protocol.SensorProtocol
import kotlinx.coroutines.CompletableDeferred

/** Result of a CompanionDeviceManager association. */
data class Association(val address: String, val associationId: Int)

/**
 * Pairs through CompanionDeviceManager (no location permission): an
 * AssociationRequest with a BluetoothLeDeviceFilter on the Kernel service UUID
 * and the QR label's address, single device.
 */
class CompanionPairing(private val context: Context) {
    private var pending: CompletableDeferred<Association?>? = null

    private val cdm: CompanionDeviceManager?
        get() = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            context.getSystemService(CompanionDeviceManager::class.java)
        } else {
            null
        }

    /** Null when the user cancels the system chooser. */
    suspend fun associate(activity: Activity, address: String): Association? {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) throw IllegalStateException("CompanionDeviceManager needs Android 8")
        val manager = cdm ?: throw IllegalStateException("CompanionDeviceManager unavailable")
        val scan = ScanFilter.Builder()
            .setServiceUuid(ParcelUuid(SensorProtocol.SERVICE))
            .setDeviceAddress(address.uppercase())
            .build()
        val filter = BluetoothLeDeviceFilter.Builder().setScanFilter(scan).build()
        val request = AssociationRequest.Builder().addDeviceFilter(filter).setSingleDevice(true).build()
        val result = CompletableDeferred<Association?>()
        pending = result
        val callback = object : CompanionDeviceManager.Callback() {
            override fun onAssociationPending(intentSender: IntentSender) = launch(activity, intentSender)

            @Deprecated("API < 33 path")
            @Suppress("OVERRIDE_DEPRECATION")
            override fun onDeviceFound(intentSender: IntentSender) {
                if (Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU) launch(activity, intentSender)
            }

            override fun onAssociationCreated(associationInfo: AssociationInfo) {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                    val mac = associationInfo.deviceMacAddress?.toString()?.uppercase() ?: address.uppercase()
                    result.complete(Association(mac, associationInfo.id))
                }
            }

            override fun onFailure(error: CharSequence?) {
                // "Canceled" by the user is reported here too; both mean no association.
                result.complete(null)
            }
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            manager.associate(request, context.mainExecutor, callback)
        } else {
            @Suppress("DEPRECATION")
            manager.associate(request, callback, Handler(Looper.getMainLooper()))
        }
        return try {
            result.await()
        } finally {
            pending = null
        }
    }

    private fun launch(activity: Activity, sender: IntentSender) {
        try {
            activity.startIntentSenderForResult(sender, REQUEST_CODE, null, 0, 0, 0)
        } catch (_: IntentSender.SendIntentException) {
            pending?.complete(null)
        }
    }

    /** Forwarded from the plugin's ActivityResultListener. */
    fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean {
        if (requestCode != REQUEST_CODE) return false
        val p = pending ?: return true
        if (resultCode != Activity.RESULT_OK) {
            p.complete(null)
            return true
        }
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU) {
            // API 26-32: the chosen device comes back in the result (a ScanResult for LE filters).
            @Suppress("DEPRECATION")
            val extra = data?.getParcelableExtra<android.os.Parcelable>(CompanionDeviceManager.EXTRA_DEVICE)
            val mac = when (extra) {
                is ScanResult -> extra.device.address
                is BluetoothDevice -> extra.address
                else -> null
            }
            p.complete(mac?.let { Association(it.uppercase(), -1) })
        }
        // API 33+: onAssociationCreated completes the deferred.
        return true
    }

    /** Wakes the app (KernelCompanionService) when the node comes into range. */
    @SuppressLint("MissingPermission") // REQUEST_OBSERVE_COMPANION_DEVICE_PRESENCE is a normal permission
    fun observePresence(association: Association) {
        val manager = cdm ?: return
        runCatching {
            when {
                Build.VERSION.SDK_INT >= 36 && association.associationId >= 0 -> observe36(manager, association.associationId)
                Build.VERSION.SDK_INT >= Build.VERSION_CODES.S -> {
                    @Suppress("DEPRECATION")
                    manager.startObservingDevicePresence(association.address)
                }
            }
        }
    }

    @SuppressLint("MissingPermission")
    fun stopObserving(association: Association) {
        val manager = cdm ?: return
        runCatching {
            when {
                Build.VERSION.SDK_INT >= 36 && association.associationId >= 0 -> stop36(manager, association.associationId)
                Build.VERSION.SDK_INT >= Build.VERSION_CODES.S -> {
                    @Suppress("DEPRECATION")
                    manager.stopObservingDevicePresence(association.address)
                }
            }
        }
    }

    /** Removes the CDM association (forget). */
    fun disassociate(association: Association) {
        val manager = cdm ?: return
        runCatching {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU && association.associationId >= 0) {
                manager.disassociate(association.associationId)
            } else if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                @Suppress("DEPRECATION")
                manager.disassociate(association.address)
            }
        }
    }

    @TargetApi(36)
    @SuppressLint("MissingPermission")
    private fun observe36(manager: CompanionDeviceManager, id: Int) {
        manager.startObservingDevicePresence(ObservingDevicePresenceRequest.Builder().setAssociationId(id).build())
    }

    @TargetApi(36)
    @SuppressLint("MissingPermission")
    private fun stop36(manager: CompanionDeviceManager, id: Int) {
        manager.stopObservingDevicePresence(ObservingDevicePresenceRequest.Builder().setAssociationId(id).build())
    }

    private companion object {
        const val REQUEST_CODE = 0x4B53 // "KS"
    }
}
