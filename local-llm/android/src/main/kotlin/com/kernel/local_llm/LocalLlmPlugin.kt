package com.kernel.local_llm

import android.content.ComponentCallbacks2
import android.content.Context
import android.content.res.Configuration
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.EventChannel
import java.io.File
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.runBlocking
import kotlinx.coroutines.withContext

/**
 * Registers the pigeon LlmHostApi and the LlmEvents event channels.
 *
 * No method channel, no network code, no permissions. Grain advice is text
 * in, text out (LlmConfig); only Pest ID requests carry a validated crop or
 * clip to the on-device engine (PestIdConfig, EmbedConfig). See
 * docs/guardrails.md §8 and its amendment.
 */
class LocalLlmPlugin : FlutterPlugin, ActivityAware, LlmHostApi {
    private var context: Context? = null
    private var messenger: BinaryMessenger? = null
    private var store: ModelStore? = null
    private var resolver: ModelResolver? = null
    private var prober: ModelProber? = null
    private var host: LlmEngineHost? = null
    private var picker: DocumentPicker? = null
    private var activityBinding: ActivityPluginBinding? = null

    private val statusEvents = EngineStatusEmitter()
    private val generationEvents = GenerationProgressEmitter()
    private val importEvents = ImportProgressEmitter()

    private val memory = object : ComponentCallbacks2 {
        override fun onTrimMemory(level: Int) {
            @Suppress("DEPRECATION")
            if (level >= ComponentCallbacks2.TRIM_MEMORY_RUNNING_LOW) host?.trim()
        }

        override fun onConfigurationChanged(newConfig: Configuration) {}

        @Deprecated("Deprecated in Java")
        override fun onLowMemory() {
            host?.trim()
        }
    }

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        val ctx = binding.applicationContext
        context = ctx
        messenger = binding.binaryMessenger
        val modelProber = ModelProber()
        prober = modelProber
        val modelStore = ModelStore(ctx.getExternalFilesDir(MODEL_DIR), classify = modelProber::kindOf)
        store = modelStore
        val modelResolver = ModelResolver(
            store = modelStore,
            roots = { appStorageRoots(ctx) },
            versionDir = File(ctx.noBackupFilesDir, VERSION_DIR),
            kindOf = modelProber::kindOf,
        )
        resolver = modelResolver
        host = LlmEngineHost(
            store = modelStore,
            models = modelResolver,
            prober = modelProber,
            cacheDir = ctx.cacheDir.path,
            onStatus = statusEvents.out::emit,
            onProgress = generationEvents.out::emit,
        )
        picker = DocumentPicker(ctx.contentResolver)
        ctx.registerComponentCallbacks(memory)

        EngineStatusStreamHandler.register(binding.binaryMessenger, statusEvents)
        GenerationProgressStreamHandler.register(binding.binaryMessenger, generationEvents)
        ImportProgressStreamHandler.register(binding.binaryMessenger, importEvents)
        LlmHostApi.setUp(binding.binaryMessenger, this)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        LlmHostApi.setUp(binding.binaryMessenger, null)
        // The generated register() has no unregister counterpart, so clear the
        // handlers on the channel names it uses.
        for (name in EVENT_CHANNELS) {
            EventChannel(binding.binaryMessenger, name, LlmApiPigeonMethodCodec).setStreamHandler(null)
        }
        statusEvents.out.detach()
        generationEvents.out.detach()
        importEvents.out.detach()
        context?.unregisterComponentCallbacks(memory)
        host?.close()
        host = null
        store = null
        resolver = null
        prober = null
        picker = null
        context = null
        messenger = null
    }

    // ActivityAware: only the document picker needs an activity.

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activityBinding = binding
        picker?.activity = binding.activity
        picker?.let(binding::addActivityResultListener)
    }

    override fun onDetachedFromActivityForConfigChanges() = onDetachedFromActivity()

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) =
        onAttachedToActivity(binding)

    override fun onDetachedFromActivity() {
        picker?.let { p ->
            activityBinding?.removeActivityResultListener(p)
            p.detach()
        }
        activityBinding = null
    }

    // LlmHostApi

    override suspend fun status(): NativeEngineStatus =
        withContext(Dispatchers.IO) { requireHost().status() }

    override suspend fun modelInfo(modelPath: String?, slot: NativeRuntimeSlot): NativeModelInfo? =
        withContext(Dispatchers.IO) {
            val kind = if (slot == NativeRuntimeSlot.EMBEDDER) ModelKind.EMBEDDING else ModelKind.LLM
            val r = requireResolver()
            val model = r.resolve(modelPath, kind) ?: return@withContext null
            val identity = r.identity(model)
            NativeModelInfo(
                id = identity.id,
                version = identity.version,
                sizeBytes = identity.sizeBytes,
                backend = requireHost().status().backend,
            )
        }

    override suspend fun load(modelPath: String?): NativeEngineStatus = requireHost().load(modelPath)

    override suspend fun generate(
        requestId: String,
        modelPath: String?,
        systemInstruction: String,
        prompt: String,
        timeoutMs: Long,
    ): NativeGenerateResult = requireHost().generate(
        requestId = requestId,
        modelPath = modelPath,
        systemInstruction = systemInstruction,
        prompt = prompt,
        timeoutMs = timeoutMs.coerceIn(1, LlmConfig.GENERATION_TIMEOUT_MS),
    )

    override suspend fun pestGenerate(requestId: String, request: NativePestRequest): NativeGenerateResult =
        requireHost().pestGenerate(requestId, request)

    override suspend fun embed(requestId: String, request: NativeEmbedRequest): NativeEmbedResult =
        requireHost().embed(requestId, request)

    override suspend fun probe(absolutePath: String): NativeProbeResult? = withContext(Dispatchers.IO) {
        val ctx = context ?: return@withContext null
        val p = prober ?: return@withContext null
        val file = PathPolicy.check(absolutePath, appStorageRoots(ctx)) ?: return@withContext null
        p.probe(file)
    }

    override fun cancel(requestId: String) {
        host?.cancel(requestId)
    }

    override suspend fun unload() {
        requireHost().unload()
    }

    override suspend fun importFromUri(importId: String, contentUri: String): NativeImportProgress {
        val ctx = context ?: throw LlmApiError("detached", "plugin detached", null)
        val engineHost = requireHost()
        val importer = ModelImporter(
            resolver = ctx.contentResolver,
            store = requireStore(),
            emit = importEvents.out::emit,
            beforeInstall = { runBlocking { engineHost.unload() } },
        )
        val result = withContext(Dispatchers.IO) { importer.import(importId, contentUri) }
        engineHost.modelChanged()
        return result
    }

    override suspend fun deleteModel() {
        val engineHost = requireHost()
        engineHost.unload()
        withContext(Dispatchers.IO) { requireStore().deleteAll() }
        engineHost.modelChanged()
    }

    override suspend fun freeSpaceBytes(): Long =
        withContext(Dispatchers.IO) { requireStore().freeSpaceBytes() }

    override suspend fun pickLitertlmUri(): String? = picker?.pick()

    private fun requireHost(): LlmEngineHost = host ?: throw LlmApiError("detached", "plugin detached", null)

    private fun requireStore(): ModelStore = store ?: throw LlmApiError("detached", "plugin detached", null)

    private fun requireResolver(): ModelResolver = resolver ?: throw LlmApiError("detached", "plugin detached", null)

    private companion object {
        /** `getExternalFilesDir("llm")` = /sdcard/Android/data/<package>/files/llm/ */
        const val MODEL_DIR = "llm"

        /** Cached versions of model files outside MODEL_DIR (app-private, not backed up). */
        const val VERSION_DIR = "local-llm-versions"

        /**
         * The app's own storage: the only places a model path may point to
         * (model-hub installs, the legacy directory, caches).
         */
        fun appStorageRoots(ctx: Context): List<File> = buildList {
            add(ctx.filesDir)
            add(ctx.noBackupFilesDir)
            add(ctx.cacheDir)
            ctx.getExternalFilesDirs(null).filterNotNull().forEach(::add)
            ctx.externalCacheDirs.filterNotNull().forEach(::add)
        }

        /** Must match the names generated in LlmApi.g.kt for LlmEvents. */
        val EVENT_CHANNELS = listOf(
            "dev.flutter.pigeon.local_llm.LlmEvents.engineStatus",
            "dev.flutter.pigeon.local_llm.LlmEvents.generationProgress",
            "dev.flutter.pigeon.local_llm.LlmEvents.importProgress",
        )
    }
}
