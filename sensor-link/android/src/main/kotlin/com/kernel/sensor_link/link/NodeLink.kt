package com.kernel.sensor_link.link

import android.annotation.SuppressLint
import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothDevice
import android.bluetooth.BluetoothGatt
import android.bluetooth.BluetoothGattCallback
import android.bluetooth.BluetoothGattCharacteristic
import android.bluetooth.BluetoothGattDescriptor
import android.bluetooth.BluetoothManager
import android.bluetooth.BluetoothProfile
import android.bluetooth.BluetoothStatusCodes
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.pm.PackageManager
import android.os.Build
import com.kernel.sensor_link.NativeLinkState
import com.kernel.sensor_link.NativeSnippet
import com.kernel.sensor_link.NativeSyncResult
import com.kernel.sensor_link.auth.AuthHandshake
import com.kernel.sensor_link.auth.KeyVault
import com.kernel.sensor_link.auth.NodeRecord
import com.kernel.sensor_link.protocol.AuthChallengePayload
import com.kernel.sensor_link.protocol.Cp
import com.kernel.sensor_link.protocol.CpIndication
import com.kernel.sensor_link.protocol.CpStatus
import com.kernel.sensor_link.protocol.EventsSincePayload
import com.kernel.sensor_link.protocol.ProtocolException
import com.kernel.sensor_link.protocol.SensorProtocol
import com.kernel.sensor_link.protocol.SnippetMeta
import com.kernel.sensor_link.protocol.SnippetTile
import com.kernel.sensor_link.protocol.WireDeviceInfo
import java.util.UUID
import kotlinx.coroutines.CompletableDeferred
import kotlinx.coroutines.TimeoutCancellationException
import kotlinx.coroutines.channels.Channel
import kotlinx.coroutines.delay
import kotlinx.coroutines.sync.Mutex
import kotlinx.coroutines.sync.withLock
import kotlinx.coroutines.withTimeout

open class LinkException(message: String) : Exception(message)

class AuthFailedException(message: String) : LinkException(message)

/** Callbacks from one node link (invoked on Binder threads; the manager re-posts to main). */
interface LinkEvents {
    fun onState(nodeId: String, state: NativeLinkState, rssi: Int?, authFailed: Boolean)
    fun onDeviceInfo(nodeId: String, bytes: ByteArray)
    fun onBandTable(nodeId: String, bytes: ByteArray)
    fun onStatus(nodeId: String, bytes: ByteArray)
    fun onBandFrame(nodeId: String, bytes: ByteArray)
    fun onEvent(nodeId: String, bytes: ByteArray)

    /** Persisted lastSeq for GET_EVENTS_SINCE, or [NO_SYNC] when nobody can persist events. */
    suspend fun lastSeq(nodeId: String): Long

    companion object {
        const val NO_SYNC = -1L
    }
}

/**
 * One GATT client link to a node: connect, LE Secure Connections bond, MTU,
 * 2M PHY, discovery, subscriptions, HMAC auth, then the reconnect sequence.
 * GATT operations are serialised; ControlPoint procedures are serialised.
 * Only feature bytes pass through here (no audio exists on the wire).
 */
@SuppressLint("MissingPermission") // every entry point checks BLUETOOTH_CONNECT via requirePermission()
class NodeLink(
    private val context: Context,
    @Volatile var record: NodeRecord,
    private val vault: KeyVault,
    private val events: LinkEvents,
) {
    private val manager = context.getSystemService(Context.BLUETOOTH_SERVICE) as BluetoothManager?
    private val adapter: BluetoothAdapter? get() = manager?.adapter

    @Volatile private var gatt: BluetoothGatt? = null
    @Volatile private var pendingOp: CompletableDeferred<OpResult>? = null
    @Volatile private var connectWaiter: CompletableDeferred<Boolean>? = null
    private val gattMutex = Mutex()
    private val procedureMutex = Mutex()
    private val connectMutex = Mutex()
    private val responses = Channel<CpIndication.Response>(Channel.UNLIMITED)
    private val eventsDone = Channel<CpIndication.EventsDone>(Channel.UNLIMITED)
    private val snippetTiles = Channel<ByteArray>(Channel.UNLIMITED)

    @Volatile var connected = false
        private set
    @Volatile var authenticated = false
        private set
    @Volatile var liveBands = false
        private set
    @Volatile var deviceInfo: WireDeviceInfo? = null
        private set
    @Volatile var mtu = 23
        private set

    private class OpResult(val status: Int, val value: ByteArray?)

    private val nodeId get() = record.nodeId

    // ------------------------------------------------------------ callback

    private val callback = object : BluetoothGattCallback() {
        override fun onConnectionStateChange(g: BluetoothGatt, status: Int, newState: Int) {
            if (newState == BluetoothProfile.STATE_CONNECTED && status == BluetoothGatt.GATT_SUCCESS) {
                connected = true
                connectWaiter?.complete(true)
            } else if (newState == BluetoothProfile.STATE_DISCONNECTED) {
                val wasUp = connected
                connected = false
                authenticated = false
                connectWaiter?.complete(false)
                pendingOp?.completeExceptionally(LinkException("link lost (status $status)"))
                g.close()
                if (gatt === g) gatt = null
                if (wasUp) events.onState(nodeId, NativeLinkState.DISCONNECTED, null, false)
            }
        }

        override fun onServicesDiscovered(g: BluetoothGatt, status: Int) = finish(status, null)

        override fun onMtuChanged(g: BluetoothGatt, newMtu: Int, status: Int) {
            if (status == BluetoothGatt.GATT_SUCCESS) mtu = newMtu
            finish(status, null)
        }

        override fun onPhyUpdate(g: BluetoothGatt, txPhy: Int, rxPhy: Int, status: Int) = finish(status, null)

        override fun onCharacteristicRead(g: BluetoothGatt, c: BluetoothGattCharacteristic, value: ByteArray, status: Int) =
            finish(status, value)

        @Deprecated("API < 33 path")
        @Suppress("DEPRECATION")
        override fun onCharacteristicRead(g: BluetoothGatt, c: BluetoothGattCharacteristic, status: Int) {
            if (Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU) finish(status, c.value)
        }

        override fun onCharacteristicWrite(g: BluetoothGatt, c: BluetoothGattCharacteristic, status: Int) =
            finish(status, null)

        override fun onDescriptorWrite(g: BluetoothGatt, d: BluetoothGattDescriptor, status: Int) = finish(status, null)

        override fun onReadRemoteRssi(g: BluetoothGatt, rssi: Int, status: Int) {
            if (status == BluetoothGatt.GATT_SUCCESS) events.onState(nodeId, currentState(), rssi, false)
        }

        override fun onCharacteristicChanged(g: BluetoothGatt, c: BluetoothGattCharacteristic, value: ByteArray) =
            route(c.uuid, value)

        @Deprecated("API < 33 path")
        @Suppress("DEPRECATION")
        override fun onCharacteristicChanged(g: BluetoothGatt, c: BluetoothGattCharacteristic) {
            if (Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU) route(c.uuid, c.value ?: return)
        }
    }

    private fun finish(status: Int, value: ByteArray?) {
        pendingOp?.complete(OpResult(status, value))
    }

    private fun route(uuid: UUID, value: ByteArray) {
        when (uuid) {
            SensorProtocol.STATUS -> events.onStatus(nodeId, value)
            SensorProtocol.EVENT -> events.onEvent(nodeId, value)
            SensorProtocol.BAND_FRAME -> events.onBandFrame(nodeId, value)
            SensorProtocol.SNIPPET -> snippetTiles.trySend(value)
            SensorProtocol.CONTROL_POINT -> try {
                when (val ind = CpIndication.decode(value)) {
                    is CpIndication.Response -> responses.trySend(ind)
                    is CpIndication.EventsDone -> eventsDone.trySend(ind)
                }
            } catch (_: ProtocolException) {
                // Malformed indication: ignored; the waiting procedure times out.
            }
        }
    }

    private fun currentState(): NativeLinkState = when {
        authenticated -> NativeLinkState.AUTHENTICATED
        connected -> NativeLinkState.CONNECTED
        else -> NativeLinkState.DISCONNECTED
    }

    // ------------------------------------------------------------ helpers

    private fun requirePermission() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S &&
            context.checkSelfPermission(android.Manifest.permission.BLUETOOTH_CONNECT) != PackageManager.PERMISSION_GRANTED
        ) {
            throw LinkException("BLUETOOTH_CONNECT not granted")
        }
        if (adapter?.isEnabled != true) throw LinkException("Bluetooth is off")
    }

    private suspend fun op(timeoutMs: Long = OP_TIMEOUT_MS, start: (BluetoothGatt) -> Boolean): OpResult =
        gattMutex.withLock {
            val g = gatt ?: throw LinkException("not connected")
            val d = CompletableDeferred<OpResult>()
            pendingOp = d
            try {
                if (!start(g)) throw LinkException("GATT operation rejected")
                withTimeout(timeoutMs) { d.await() }
            } finally {
                pendingOp = null
            }
        }

    private fun characteristic(uuid: UUID): BluetoothGattCharacteristic =
        gatt?.getService(SensorProtocol.SERVICE)?.getCharacteristic(uuid)
            ?: throw LinkException("characteristic $uuid missing")

    private suspend fun read(uuid: UUID): ByteArray {
        val c = characteristic(uuid)
        val r = op { it.readCharacteristic(c) }
        if (r.status != BluetoothGatt.GATT_SUCCESS) throw LinkException("read $uuid failed (${r.status})")
        return r.value ?: ByteArray(0)
    }

    @Suppress("DEPRECATION")
    private suspend fun write(uuid: UUID, value: ByteArray) {
        val c = characteristic(uuid)
        val r = op {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                it.writeCharacteristic(c, value, BluetoothGattCharacteristic.WRITE_TYPE_DEFAULT) == BluetoothStatusCodes.SUCCESS
            } else {
                c.writeType = BluetoothGattCharacteristic.WRITE_TYPE_DEFAULT
                c.value = value
                it.writeCharacteristic(c)
            }
        }
        if (r.status != BluetoothGatt.GATT_SUCCESS) throw LinkException("write $uuid failed (${r.status})")
    }

    @Suppress("DEPRECATION")
    private suspend fun subscribe(uuid: UUID, enable: Boolean) {
        val c = characteristic(uuid)
        val g = gatt ?: throw LinkException("not connected")
        if (!g.setCharacteristicNotification(c, enable)) throw LinkException("subscribe $uuid rejected")
        val d = c.getDescriptor(SensorProtocol.CCCD) ?: throw LinkException("CCCD missing on $uuid")
        val indicate = (c.properties and BluetoothGattCharacteristic.PROPERTY_INDICATE) != 0
        val value = when {
            !enable -> BluetoothGattDescriptor.DISABLE_NOTIFICATION_VALUE
            indicate -> BluetoothGattDescriptor.ENABLE_INDICATION_VALUE
            else -> BluetoothGattDescriptor.ENABLE_NOTIFICATION_VALUE
        }
        val r = op {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                it.writeDescriptor(d, value) == BluetoothStatusCodes.SUCCESS
            } else {
                d.value = value
                it.writeDescriptor(d)
            }
        }
        if (r.status != BluetoothGatt.GATT_SUCCESS) throw LinkException("CCCD $uuid failed (${r.status})")
    }

    /** Writes a ControlPoint request and waits for its RESPONSE indication. Caller holds procedureMutex. */
    private suspend fun cp(request: ByteArray, timeoutMs: Long = OP_TIMEOUT_MS): CpIndication.Response {
        while (responses.tryReceive().isSuccess) Unit
        write(SensorProtocol.CONTROL_POINT, request)
        val op = request[0].toInt() and 0xFF
        return withTimeout(timeoutMs) {
            var r: CpIndication.Response
            do {
                r = responses.receive()
            } while (r.reqOpcode != op)
            r
        }
    }

    suspend fun control(request: ByteArray): CpIndication.Response = procedureMutex.withLock { cp(request) }

    // ------------------------------------------------------------ bonding

    private suspend fun bond(device: BluetoothDevice) {
        if (device.bondState == BluetoothDevice.BOND_BONDED) return
        val done = CompletableDeferred<Boolean>()
        val receiver = object : BroadcastReceiver() {
            override fun onReceive(ctx: Context, intent: Intent) {
                val d: BluetoothDevice? = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                    intent.getParcelableExtra(BluetoothDevice.EXTRA_DEVICE, BluetoothDevice::class.java)
                } else {
                    @Suppress("DEPRECATION")
                    intent.getParcelableExtra(BluetoothDevice.EXTRA_DEVICE)
                }
                if (d?.address != device.address) return
                when (intent.getIntExtra(BluetoothDevice.EXTRA_BOND_STATE, BluetoothDevice.ERROR)) {
                    BluetoothDevice.BOND_BONDED -> done.complete(true)
                    BluetoothDevice.BOND_NONE -> done.complete(false)
                }
            }
        }
        val filter = IntentFilter(BluetoothDevice.ACTION_BOND_STATE_CHANGED)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            context.registerReceiver(receiver, filter, Context.RECEIVER_NOT_EXPORTED)
        } else {
            context.registerReceiver(receiver, filter)
        }
        try {
            events.onState(nodeId, NativeLinkState.PAIRING, null, false)
            if (device.bondState != BluetoothDevice.BOND_BONDING && !device.createBond()) {
                throw LinkException("createBond rejected")
            }
            if (!withTimeout(BOND_TIMEOUT_MS) { done.await() }) throw LinkException("bonding failed")
        } finally {
            context.unregisterReceiver(receiver)
        }
    }

    // --------------------------------------------------------- sequence

    /** Runs [ReconnectPlan] unless the link is already authenticated. */
    suspend fun ensureConnected() = connectMutex.withLock {
        if (connected && authenticated) return@withLock
        requirePermission()
        try {
            runPlan()
        } catch (e: AuthFailedException) {
            events.onState(nodeId, NativeLinkState.ERROR, null, true)
            closeGatt()
            throw e
        } catch (e: Exception) {
            events.onState(nodeId, NativeLinkState.ERROR, null, false)
            closeGatt()
            throw if (e is LinkException) e else LinkException(e.message ?: e.javaClass.simpleName)
        }
    }

    private suspend fun runPlan() {
        val a = adapter ?: throw LinkException("no Bluetooth adapter")
        val device = a.getRemoteDevice(record.address)
        val plan = ReconnectPlan.steps(
            alreadyBonded = device.bondState == BluetoothDevice.BOND_BONDED,
            supports2mPhy = Build.VERSION.SDK_INT >= Build.VERSION_CODES.O && a.isLe2MPhySupported,
            liveBands = liveBands,
        )
        for (step in plan) {
            when (step) {
                LinkStep.CONNECT -> connectGatt(device)
                LinkStep.BOND -> bond(device)
                LinkStep.REQUEST_MTU -> runCatching { op { it.requestMtu(ReconnectPlan.MTU) } }
                LinkStep.PREFER_2M_PHY -> if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    // Some stacks never call back when the PHY is unchanged: best effort.
                    runCatching {
                        op(PHY_TIMEOUT_MS) {
                            it.setPreferredPhy(BluetoothDevice.PHY_LE_2M_MASK, BluetoothDevice.PHY_LE_2M_MASK, BluetoothDevice.PHY_OPTION_NO_PREFERRED)
                            true
                        }
                    }
                }
                LinkStep.DISCOVER -> {
                    val r = op(DISCOVER_TIMEOUT_MS) { it.discoverServices() }
                    if (r.status != BluetoothGatt.GATT_SUCCESS || gatt?.getService(SensorProtocol.SERVICE) == null) {
                        throw LinkException("Kernel sensor service not found")
                    }
                }
                LinkStep.SUBSCRIBE_STATUS -> subscribe(SensorProtocol.STATUS, true)
                LinkStep.SUBSCRIBE_CONTROL_POINT -> subscribe(SensorProtocol.CONTROL_POINT, true)
                LinkStep.SUBSCRIBE_EVENT -> subscribe(SensorProtocol.EVENT, true)
                LinkStep.SUBSCRIBE_SNIPPET -> subscribe(SensorProtocol.SNIPPET, true)
                LinkStep.SUBSCRIBE_BAND_FRAME -> subscribe(SensorProtocol.BAND_FRAME, true)
                LinkStep.READ_DEVICE_INFO -> {
                    val bytes = read(SensorProtocol.DEVICE_INFO)
                    val info = WireDeviceInfo.decode(bytes)
                    if (info.protoMajor != SensorProtocol.PROTO_MAJOR) {
                        throw LinkException("protocol ${info.protoMajor} not supported: update needed")
                    }
                    deviceInfo = info
                    events.onDeviceInfo(nodeId, bytes)
                }
                LinkStep.AUTHENTICATE -> {
                    authenticate()
                    authenticated = true
                    events.onState(nodeId, NativeLinkState.AUTHENTICATED, null, false)
                }
                LinkStep.READ_STATUS -> events.onStatus(nodeId, read(SensorProtocol.STATUS))
                LinkStep.READ_BAND_TABLE -> events.onBandTable(nodeId, read(SensorProtocol.BAND_TABLE))
                LinkStep.SET_TIME -> {
                    val r = control(Cp.setTime(System.currentTimeMillis()))
                    if (r.status != CpStatus.OK) throw LinkException("SET_TIME status ${r.status}")
                }
                LinkStep.GET_EVENTS_SINCE -> {
                    val since = events.lastSeq(nodeId)
                    if (since != LinkEvents.NO_SYNC) syncSince(since)
                }
            }
        }
    }

    private suspend fun connectGatt(device: BluetoothDevice) {
        closeGatt()
        events.onState(nodeId, NativeLinkState.CONNECTING, null, false)
        val waiter = CompletableDeferred<Boolean>()
        connectWaiter = waiter
        gatt = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            device.connectGatt(context, false, callback, BluetoothDevice.TRANSPORT_LE)
        } else {
            device.connectGatt(context, false, callback)
        }
        val ok = try {
            withTimeout(CONNECT_TIMEOUT_MS) { waiter.await() }
        } catch (_: TimeoutCancellationException) {
            false
        } finally {
            connectWaiter = null
        }
        if (!ok) throw LinkException("connect failed")
        events.onState(nodeId, NativeLinkState.CONNECTED, null, false)
        // Let the link settle before the first ATT request (bond/encryption may follow).
        delay(SETTLE_MS)
    }

    private suspend fun authenticate() {
        val mac = vault.macFor(nodeId) ?: throw AuthFailedException("no key for node")
        val hs = AuthHandshake(mac, record.address)
        val appNonce = hs.appNonce(vault.nextNonceCounter(nodeId), System.currentTimeMillis())
        val r1 = control(Cp.authChallenge(appNonce))
        if (r1.status != CpStatus.OK) throw AuthFailedException("challenge refused (${r1.status})")
        val p = AuthChallengePayload.decode(r1.payload)
        if (!hs.verifyNode(appNonce, p.nodeNonce, p.nodeProof)) throw AuthFailedException("node proof mismatch")
        val r2 = control(Cp.authResponse(hs.appProof(appNonce, p.nodeNonce)))
        if (r2.status != CpStatus.OK) throw AuthFailedException("app proof rejected (${r2.status})")
    }

    // --------------------------------------------------------- procedures

    suspend fun syncSince(since: Long): NativeSyncResult = procedureMutex.withLock {
        while (eventsDone.tryReceive().isSuccess) Unit
        val r = cp(Cp.getEventsSince(since))
        if (r.status != CpStatus.OK) throw LinkException("GET_EVENTS_SINCE status ${r.status}")
        val p = EventsSincePayload.decode(r.payload)
        val timeout = (OP_TIMEOUT_MS + p.count * PER_EVENT_MS).coerceAtMost(MAX_SYNC_MS)
        val done = withTimeout(timeout) { eventsDone.receive() }
        NativeSyncResult(count = done.count.toLong(), lastSeq = done.lastSeq, oldestSeq = p.oldestSeq)
    }

    suspend fun requestSnippet(seq: Long): NativeSnippet? = procedureMutex.withLock {
        while (snippetTiles.tryReceive().isSuccess) Unit
        val r = cp(Cp.requestSnippet(seq))
        if (r.status == CpStatus.NOT_AVAILABLE) return@withLock null
        if (r.status != CpStatus.OK) throw LinkException("REQUEST_SNIPPET status ${r.status}")
        val meta = SnippetMeta.decode(r.payload)
        val tiles = ArrayList<ByteArray>(meta.tileCount)
        withTimeout(SNIPPET_TIMEOUT_MS) {
            while (tiles.size < meta.tileCount) {
                val t = snippetTiles.receive()
                if (SnippetTile.decode(t).eventSeq == seq) tiles.add(t)
            }
        }
        NativeSnippet(meta = r.payload, tiles = tiles)
    }

    suspend fun setLiveBands(enabled: Boolean) {
        liveBands = enabled
        if (connected && authenticated) subscribe(SensorProtocol.BAND_FRAME, enabled)
    }

    fun readRssi() {
        runCatching { gatt?.readRemoteRssi() }
    }

    fun closeGatt() {
        val g = gatt ?: return
        gatt = null
        connected = false
        authenticated = false
        runCatching {
            g.disconnect()
            g.close()
        }
    }

    fun disconnect() {
        closeGatt()
        events.onState(nodeId, NativeLinkState.DISCONNECTED, null, false)
    }

    private companion object {
        const val OP_TIMEOUT_MS = 10_000L
        const val PHY_TIMEOUT_MS = 2_000L
        const val DISCOVER_TIMEOUT_MS = 15_000L
        const val CONNECT_TIMEOUT_MS = 20_000L
        const val BOND_TIMEOUT_MS = 45_000L
        const val SNIPPET_TIMEOUT_MS = 20_000L
        const val PER_EVENT_MS = 150L
        const val MAX_SYNC_MS = 600_000L
        const val SETTLE_MS = 300L
    }
}
