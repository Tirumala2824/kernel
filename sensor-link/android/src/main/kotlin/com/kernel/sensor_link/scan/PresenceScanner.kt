package com.kernel.sensor_link.scan

import android.annotation.SuppressLint
import android.app.PendingIntent
import android.bluetooth.BluetoothManager
import android.bluetooth.le.BluetoothLeScanner
import android.bluetooth.le.ScanFilter
import android.bluetooth.le.ScanResult
import android.bluetooth.le.ScanSettings
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import android.os.ParcelUuid
import com.kernel.sensor_link.link.LinkManager
import com.kernel.sensor_link.protocol.SensorProtocol

/**
 * Fallback presence detection while a session waits for its node: a low-power
 * PendingIntent scan filtered on the Kernel service UUID. BLUETOOTH_SCAN is
 * declared with neverForLocation, so results carry no location meaning.
 * On Android 11 and lower (which would need location for scans) this stays
 * off and the reconnect backoff loop is used instead.
 */
object PresenceScanner {
    private const val REQUEST = 0x4B50

    private fun scanner(context: Context): BluetoothLeScanner? =
        (context.getSystemService(Context.BLUETOOTH_SERVICE) as BluetoothManager?)?.adapter?.bluetoothLeScanner

    private fun allowed(context: Context): Boolean =
        Build.VERSION.SDK_INT >= Build.VERSION_CODES.S &&
            context.checkSelfPermission(android.Manifest.permission.BLUETOOTH_SCAN) == PackageManager.PERMISSION_GRANTED

    private fun pendingIntent(context: Context): PendingIntent = PendingIntent.getBroadcast(
        context,
        REQUEST,
        Intent(context, PresenceScanReceiver::class.java),
        PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_MUTABLE,
    )

    @SuppressLint("MissingPermission") // allowed() checks BLUETOOTH_SCAN
    fun start(context: Context, addresses: Collection<String>) {
        if (!allowed(context) || addresses.isEmpty()) return
        val filters = addresses.map {
            ScanFilter.Builder().setServiceUuid(ParcelUuid(SensorProtocol.SERVICE)).setDeviceAddress(it.uppercase()).build()
        }
        val settings = ScanSettings.Builder()
            .setScanMode(ScanSettings.SCAN_MODE_LOW_POWER)
            .setCallbackType(ScanSettings.CALLBACK_TYPE_FIRST_MATCH)
            .build()
        runCatching { scanner(context)?.startScan(filters, settings, pendingIntent(context)) }
    }

    @SuppressLint("MissingPermission")
    fun stop(context: Context) {
        if (!allowed(context)) return
        runCatching { scanner(context)?.stopScan(pendingIntent(context)) }
    }
}

class PresenceScanReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val results: List<ScanResult> = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            intent.getParcelableArrayListExtra(BluetoothLeScanner.EXTRA_LIST_SCAN_RESULT, ScanResult::class.java)
        } else {
            @Suppress("DEPRECATION")
            intent.getParcelableArrayListExtra(BluetoothLeScanner.EXTRA_LIST_SCAN_RESULT)
        } ?: return
        for (r in results) LinkManager.onPresence(context.applicationContext, r.device.address, present = true)
    }
}
