package com.kernel.model_hub

import android.content.Context
import android.os.Handler
import android.os.Looper
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.EventChannel
import java.io.File
import java.net.URL
import java.util.concurrent.ExecutorService
import java.util.concurrent.Executors
import kotlinx.coroutines.CoroutineDispatcher
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.asCoroutineDispatcher
import kotlinx.coroutines.withContext

/**
 * Registers the pigeon ModelHubHostApi and the provision-progress channel.
 *
 * Network (guardrails §7) happens only inside the download jobs, only for a
 * pinned model file on an allow-listed https host, and only after the Dart
 * side checked consent, licence, gating and sha256.
 */
class ModelHubPlugin : FlutterPlugin, ModelHubHostApi {
    private var context: Context? = null
    private var hashExecutor: ExecutorService? = null
    private var hashDispatcher: CoroutineDispatcher? = null
    private val events = ProgressEmitter()
    private val listener: (ProvisionState) -> Unit = { events.emit(it.toNative()) }

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        context = binding.applicationContext
        val exec = Executors.newSingleThreadExecutor { r -> Thread(r, "model-hub-hash") }
        hashExecutor = exec
        hashDispatcher = exec.asCoroutineDispatcher()
        ProvisionBus.addListener(listener)
        ProvisionProgressStreamHandler.register(binding.binaryMessenger, events)
        ModelHubHostApi.setUp(binding.binaryMessenger, this)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        ModelHubHostApi.setUp(binding.binaryMessenger, null)
        EventChannel(binding.binaryMessenger, PROGRESS_CHANNEL, HubApiPigeonMethodCodec).setStreamHandler(null)
        ProvisionBus.removeListener(listener)
        events.detach()
        hashExecutor?.shutdownNow()
        hashExecutor = null
        hashDispatcher = null
        context = null
    }

    private fun ctx(): Context = context ?: throw HubApiError("detached", "plugin detached", null)

    override fun deviceInfo(): NativeDeviceInfo = DeviceProbe.info(ctx())

    override fun networkState(): NativeNetworkState = DeviceProbe.network(ctx())

    override fun paths(): NativePaths {
        val c = ctx()
        return NativePaths(
            filesDir = c.filesDir.absolutePath,
            modelsDir = HubServices.modelsDir(c)?.absolutePath,
            legacyLlmDir = HubServices.legacyLlmDir(c)?.absolutePath,
        )
    }

    override suspend fun listModelFiles(): List<NativeModelFile> = withContext(Dispatchers.IO) {
        HubServices.storage(ctx()).list().map { NativeModelFile(it.path, it.sizeBytes, it.modifiedMs) }
    }

    override suspend fun sha256Of(path: String): String? {
        val c = ctx()
        val dispatcher = hashDispatcher ?: return null
        return withContext(dispatcher) {
            val f = File(path)
            if (!f.isFile || !HubServices.storage(c).isManaged(f)) null else HubServices.hashCache(c).sha256(f)
        }
    }

    override suspend fun freeSpaceBytes(): Long = withContext(Dispatchers.IO) {
        val c = ctx()
        val dir = HubServices.modelsDir(c) ?: c.filesDir
        AndroidSpaceProbe(c).allocatableBytes(dir)
    }

    override suspend fun enqueue(request: NativeDownloadRequest): NativeProvisionProgress =
        withContext(Dispatchers.IO) {
            val c = ctx()
            val modelsDir = HubServices.modelsDir(c)
                ?: return@withContext failed(request, "storage_unavailable")
            val target = ModelPaths.targetFile(modelsDir, request.repoId, request.revision, request.fileName)
                ?: return@withContext failed(request, "invalid_request")
            val url = try {
                URL(request.url)
            } catch (_: Exception) {
                return@withContext failed(request, "invalid_url")
            }
            if (!HostPolicy.MODEL_HOSTS.allows(url)) return@withContext failed(request, "host_not_allowed")
            if (!ModelPaths.SHA256.matches(request.sha256.lowercase())) {
                return@withContext failed(request, "sha256_unknown")
            }
            if (request.sizeBytes <= 0) return@withContext failed(request, "size_unknown")
            val spec = DownloadJobSpec(
                entryId = request.entryId,
                title = request.title,
                url = request.url,
                sha256 = request.sha256.lowercase(),
                sizeBytes = request.sizeBytes,
                targetPath = target.absolutePath,
                wifiOnly = request.wifiOnly,
            )
            DownloadScheduler(c).enqueue(spec).toNative()
        }

    override fun cancel(entryId: String) {
        DownloadScheduler(ctx()).cancel(entryId)
    }

    override suspend fun remove(path: String): Boolean = withContext(Dispatchers.IO) {
        val c = ctx()
        val ok = HubServices.storage(c).remove(path)
        if (ok) HubServices.hashCache(c).forget(File(path).path)
        ok
    }

    override fun activeDownloads(): List<NativeProvisionProgress> =
        ProvisionBus.snapshot().map { it.toNative() }

    private fun failed(r: NativeDownloadRequest, reason: String) =
        NativeProvisionProgress(r.entryId, NativeProvisionPhase.FAILED, 0, r.sizeBytes, reason, null)

    private companion object {
        const val PROGRESS_CHANNEL = "dev.flutter.pigeon.model_hub.ModelHubEvents.provisionProgress"
    }
}

internal fun ProvisionState.toNative() = NativeProvisionProgress(
    entryId = entryId,
    phase = when (phase) {
        ProvisionPhaseK.QUEUED -> NativeProvisionPhase.QUEUED
        ProvisionPhaseK.WAITING_FOR_WIFI -> NativeProvisionPhase.WAITING_FOR_WIFI
        ProvisionPhaseK.WAITING_FOR_SPACE -> NativeProvisionPhase.WAITING_FOR_SPACE
        ProvisionPhaseK.DOWNLOADING -> NativeProvisionPhase.DOWNLOADING
        ProvisionPhaseK.VERIFYING -> NativeProvisionPhase.VERIFYING
        ProvisionPhaseK.INSTALLED -> NativeProvisionPhase.INSTALLED
        ProvisionPhaseK.PAUSED -> NativeProvisionPhase.PAUSED
        ProvisionPhaseK.FAILED -> NativeProvisionPhase.FAILED
    },
    bytesDone = bytesDone,
    totalBytes = totalBytes,
    error = error,
    path = path,
)

/** Posts every event to the main thread; drops events with no listener. */
class ProgressEmitter : ProvisionProgressStreamHandler() {
    private val main = Handler(Looper.getMainLooper())

    @Volatile
    private var sink: PigeonEventSink<NativeProvisionProgress>? = null

    fun emit(value: NativeProvisionProgress) {
        if (sink == null) return
        main.post {
            try {
                sink?.success(value)
            } catch (_: RuntimeException) {
                // Engine detached between post and delivery.
            }
        }
    }

    fun detach() {
        main.removeCallbacksAndMessages(null)
        sink = null
    }

    override fun onListen(p0: Any?, sink: PigeonEventSink<NativeProvisionProgress>) {
        this.sink = sink
    }

    override fun onCancel(p0: Any?) {
        sink = null
    }
}
