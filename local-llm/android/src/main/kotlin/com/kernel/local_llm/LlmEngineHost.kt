package com.kernel.local_llm

import android.os.SystemClock
import android.util.Log
import com.google.ai.edge.litertlm.Content
import com.google.ai.edge.litertlm.Conversation
import com.google.ai.edge.litertlm.ConversationConfig
import com.google.ai.edge.litertlm.EmbeddingEngine
import com.google.ai.edge.litertlm.Engine
import com.google.ai.edge.litertlm.LogSeverity
import com.google.ai.edge.litertlm.Message
import java.util.concurrent.ConcurrentHashMap
import java.util.concurrent.Executors
import java.util.concurrent.atomic.AtomicBoolean
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Deferred
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.asCoroutineDispatcher
import kotlinx.coroutines.async
import kotlinx.coroutines.cancel
import kotlinx.coroutines.currentCoroutineContext
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import kotlinx.coroutines.withTimeoutOrNull

/**
 * The on-device LiteRT-LM runtime. It owns the ONE engine that may be in
 * memory at a time (Gemma 4 E2B is about 2.5 GB, EmbeddingGemma several
 * hundred MB):
 *
 * - [NativeRuntimeSlot.ADVICE]: Gemma, text-only (LlmConfig). Grain advice.
 * - [NativeRuntimeSlot.PEST_ID]: Gemma with vision (GPU, CPU fallback) and
 *   audio (CPU) encoders (PestIdConfig). Pest ID mode only.
 * - [NativeRuntimeSlot.EMBEDDER]: EmbeddingGemma (EmbedConfig).
 *
 * Loading one slot closes whatever else is loaded first, so Gemma and
 * EmbeddingGemma are never in memory together. The Dart RuntimeManager also
 * serialises requests and unloads before switching; this class enforces the
 * same rule natively.
 *
 * - Lazy: nothing loads until a request (or the advice warm-up) needs it.
 * - GPU first, then CPU. A slot that failed on every backend is not retried
 *   for the same file until the model files change.
 * - One request at a time; a second one is rejected as busy.
 * - Each generation gets its own short-lived [Conversation], closed after.
 * - Unloads after [LlmConfig.IDLE_UNLOAD_MS] idle, on [trim] and on [close].
 * - Never logs prompts, outputs, media or native error messages (they can
 *   echo text). Native log severity is ERROR.
 *
 * All engine create/initialize/close calls run on one dedicated thread.
 */
class LlmEngineHost(
    private val store: ModelStore,
    private val models: ModelResolver,
    private val prober: ModelProber,
    private val cacheDir: String,
    private val onStatus: (NativeEngineStatus) -> Unit,
    private val onProgress: (NativeGenerationProgress) -> Unit,
) {
    private val engineThread = Executors.newSingleThreadExecutor { r ->
        Thread(r, "local-llm-engine").apply { isDaemon = true }
    }.asCoroutineDispatcher()
    private val scope = CoroutineScope(SupervisorJob() + engineThread)

    /** What a request needs loaded. [key] changes with the slot or the file. */
    private class LoadSpec(
        val slot: NativeRuntimeSlot,
        val model: ModelFile,
        val vision: Boolean = false,
        val audio: Boolean = false,
    ) {
        val key: String = "${slot.name}|${model.key}|v=$vision|a=$audio"
    }

    private sealed class Loaded(val slot: NativeRuntimeSlot, val key: String, val backend: String) {
        abstract fun close()
    }

    private class LlmLoaded(slot: NativeRuntimeSlot, key: String, backend: String, val engine: Engine) :
        Loaded(slot, key, backend) {
        override fun close() = engine.close()
    }

    private class EmbedLoaded(key: String, backend: String, val engine: EmbeddingEngine) :
        Loaded(NativeRuntimeSlot.EMBEDDER, key, backend) {
        override fun close() = engine.close()
    }

    // Written only on engineThread.
    @Volatile private var loaded: Loaded? = null
    @Volatile private var attemptSlot: NativeRuntimeSlot? = null
    @Volatile private var state: NativeEngineState = NativeEngineState.UNLOADED
    private val failed: MutableSet<String> = ConcurrentHashMap.newKeySet()

    private var loadJob: Deferred<Loaded?>? = null
    private var loadKey: String? = null
    private var idleJob: Job? = null

    private val busy = AtomicBoolean(false)
    @Volatile private var running: Running? = null

    private class Running(val requestId: String, val job: Job) {
        @Volatile var conversation: Conversation? = null
        @Volatile var cancelled = false
    }

    private val backend: String get() = loaded?.backend ?: BACKEND_NONE

    fun status(): NativeEngineStatus = NativeEngineStatus(
        state = state,
        modelPresent = store.findModel(ModelKind.LLM) != null,
        backend = backend,
        slot = loaded?.slot ?: attemptSlot.takeIf {
            state == NativeEngineState.LOADING || state == NativeEngineState.FAILED
        },
    )

    /** Advice warm-up: loads the text-only engine now if nothing is running. */
    suspend fun load(modelPath: String?): NativeEngineStatus {
        val model = withContext(Dispatchers.IO) { models.resolve(modelPath, ModelKind.LLM) } ?: return status()
        if (busy.get()) return status()
        startLoad(LoadSpec(NativeRuntimeSlot.ADVICE, model.file)).await()
        scheduleIdleUnload()
        return status()
    }

    /** Grain advice: text in, text out, on the text-only engine. */
    suspend fun generate(
        requestId: String,
        modelPath: String?,
        systemInstruction: String,
        prompt: String,
        timeoutMs: Long,
    ): NativeGenerateResult {
        val t0 = SystemClock.elapsedRealtime()
        val model = withContext(Dispatchers.IO) { models.resolve(modelPath, ModelKind.LLM) }
            ?: return result(NativeGenerateStatus.NO_MODEL, t0)
        return converse(
            requestId = requestId,
            t0 = t0,
            timeoutMs = timeoutMs,
            model = model,
            spec = LoadSpec(NativeRuntimeSlot.ADVICE, model.file),
            config = LlmConfig.conversationConfig(systemInstruction),
            streamProgress = true,
        ) { conversation -> conversation.sendMessageAsync(prompt) }
    }

    /** Pest ID: one multimodal run (images first, then the clip, then text). */
    suspend fun pestGenerate(requestId: String, request: NativePestRequest): NativeGenerateResult {
        val t0 = SystemClock.elapsedRealtime()
        val model = withContext(Dispatchers.IO) { models.resolve(request.modelPath, ModelKind.LLM) }
            ?: return result(NativeGenerateStatus.NO_MODEL, t0)
        PestIdConfig.validate(request)?.let { return result(it, t0) }
        val header = withContext(Dispatchers.IO) { prober.probe(model.file.file) }
        if (header != null) {
            if (request.images.isNotEmpty() && !header.vision) return result(NativeGenerateStatus.UNSUPPORTED, t0)
            if (request.audioWav != null && !header.audio) return result(NativeGenerateStatus.UNSUPPORTED, t0)
        }
        val format = PestIdConfig.responseFormat(request.format, request.formatSpec)
        return converse(
            requestId = requestId,
            t0 = t0,
            timeoutMs = request.timeoutMs.coerceIn(1, PestIdConfig.TIMEOUT_MS),
            model = model,
            spec = LoadSpec(NativeRuntimeSlot.PEST_ID, model.file),
            config = PestIdConfig.conversationConfig(request),
            streamProgress = false,
        ) { conversation ->
            val contents = PestIdConfig.contents(request.images, request.audioWav, request.prompt)
            if (format == null) conversation.sendMessageAsync(contents)
            else conversation.sendMessageAsync(contents, responseFormat = format)
        }
    }

    /** One EmbeddingGemma embedding (full length; Dart truncates). */
    suspend fun embed(requestId: String, request: NativeEmbedRequest): NativeEmbedResult {
        val t0 = SystemClock.elapsedRealtime()
        val model = withContext(Dispatchers.IO) { models.resolve(request.modelPath, ModelKind.EMBEDDING) }
            ?: return embedResult(NativeGenerateStatus.NO_MODEL, t0)
        val input = EmbedConfig.input(request.kind, request.text, request.bytes)
            ?: return embedResult(NativeGenerateStatus.UNSUPPORTED, t0)
        val header = withContext(Dispatchers.IO) { prober.probe(model.file.file) }
        val vision = header?.vision ?: false
        val audio = header?.audio ?: false
        if (request.kind == NativeEmbedKind.IMAGE && !vision) return embedResult(NativeGenerateStatus.UNSUPPORTED, t0)
        if (request.kind == NativeEmbedKind.AUDIO && !audio) return embedResult(NativeGenerateStatus.UNSUPPORTED, t0)
        if (!busy.compareAndSet(false, true)) return embedResult(NativeGenerateStatus.BUSY, t0)
        val run = Running(requestId, currentCoroutineContext()[Job]!!)
        running = run
        cancelIdleUnload()
        var version = ""
        val spec = LoadSpec(NativeRuntimeSlot.EMBEDDER, model.file, vision, audio)
        try {
            version = withContext(Dispatchers.IO) { models.identity(model) }.version
            val budget = (request.timeoutMs.coerceIn(1, EmbedConfig.TIMEOUT_MS) - (SystemClock.elapsedRealtime() - t0))
                .coerceAtLeast(1)
            val values = withTimeoutOrNull(budget) {
                val eng = (startLoad(spec).await() as? EmbedLoaded)?.engine ?: return@withTimeoutOrNull null
                if (run.cancelled) throw CancellationException("cancelled")
                setState(NativeEngineState.BUSY)
                withContext(engineThread) { eng.computeEmbedding(listOf(input), EmbedConfig.options()).embedding }
            }
            return when {
                run.cancelled -> embedResult(NativeGenerateStatus.CANCELLED, t0, version)
                values == null && loaded?.key != spec.key && failed.contains(spec.key) ->
                    embedResult(NativeGenerateStatus.LOAD_FAILED, t0, version)
                values == null -> embedResult(NativeGenerateStatus.TIMEOUT, t0, version)
                values.isEmpty() || values.any { !it.isFinite() } -> embedResult(NativeGenerateStatus.ERROR, t0, version)
                else -> NativeEmbedResult(
                    status = NativeGenerateStatus.OK,
                    values = DoubleArray(values.size) { values[it].toDouble() },
                    modelVersion = version,
                    backend = backend,
                    totalMs = SystemClock.elapsedRealtime() - t0,
                )
            }
        } catch (e: CancellationException) {
            return embedResult(NativeGenerateStatus.CANCELLED, t0, version)
        } catch (e: Throwable) {
            Log.w(TAG, "embedding failed: ${e.javaClass.simpleName}")
            return embedResult(NativeGenerateStatus.ERROR, t0, version)
        } finally {
            finishRequest()
        }
    }

    private suspend fun converse(
        requestId: String,
        t0: Long,
        timeoutMs: Long,
        model: ResolvedModel,
        spec: LoadSpec,
        config: ConversationConfig,
        streamProgress: Boolean,
        send: (Conversation) -> Flow<Message>,
    ): NativeGenerateResult {
        if (!busy.compareAndSet(false, true)) return result(NativeGenerateStatus.BUSY, t0)
        val run = Running(requestId, currentCoroutineContext()[Job]!!)
        running = run
        cancelIdleUnload()
        var loadMs = 0L
        var firstTokenMs = -1L
        var version = ""
        try {
            version = withContext(Dispatchers.IO) { models.identity(model) }.version
            val budget = (timeoutMs - (SystemClock.elapsedRealtime() - t0)).coerceAtLeast(1)
            val text = withTimeoutOrNull(budget) {
                val loadStart = SystemClock.elapsedRealtime()
                val wasLoaded = loaded?.key == spec.key
                // The load is not part of this request's job: if the request
                // times out, the engine still finishes loading for the next one.
                val eng = (startLoad(spec).await() as? LlmLoaded)?.engine ?: return@withTimeoutOrNull null
                if (!wasLoaded) loadMs = SystemClock.elapsedRealtime() - loadStart
                if (run.cancelled) throw CancellationException("cancelled")
                setState(NativeEngineState.BUSY)
                val out = StringBuilder()
                withContext(engineThread) {
                    eng.createConversation(config).use { conversation ->
                        run.conversation = conversation
                        var chunks = 0L
                        var lastEmit = 0L
                        try {
                            send(conversation).collect { message ->
                                val piece = textOf(message)
                                if (piece.isEmpty()) return@collect
                                val now = SystemClock.elapsedRealtime()
                                if (firstTokenMs < 0) firstTokenMs = now - t0
                                out.append(piece)
                                chunks++
                                if (streamProgress && now - lastEmit >= PROGRESS_INTERVAL_MS) {
                                    lastEmit = now
                                    onProgress(
                                        NativeGenerationProgress(
                                            requestId = requestId,
                                            chunks = chunks,
                                            chars = out.length.toLong(),
                                            elapsedMs = now - t0,
                                        ),
                                    )
                                }
                            }
                        } catch (e: CancellationException) {
                            runCatching { conversation.cancelProcess() }
                            throw e
                        } finally {
                            run.conversation = null
                        }
                    }
                }
                out.toString()
            }
            return when {
                run.cancelled -> result(NativeGenerateStatus.CANCELLED, t0, version)
                text == null && loaded?.key != spec.key && failed.contains(spec.key) ->
                    result(NativeGenerateStatus.LOAD_FAILED, t0, version, loadMs)
                text == null -> result(NativeGenerateStatus.TIMEOUT, t0, version, loadMs, firstTokenMs)
                else -> NativeGenerateResult(
                    status = NativeGenerateStatus.OK,
                    text = text,
                    modelVersion = version,
                    backend = backend,
                    loadMs = loadMs,
                    firstTokenMs = firstTokenMs,
                    totalMs = SystemClock.elapsedRealtime() - t0,
                )
            }
        } catch (e: CancellationException) {
            return result(NativeGenerateStatus.CANCELLED, t0)
        } catch (e: Throwable) {
            // LiteRtLmJniException and friends. The message is not logged:
            // native errors can quote the prompt.
            Log.w(TAG, "generation failed: ${e.javaClass.simpleName}")
            return result(NativeGenerateStatus.ERROR, t0, loadMs = loadMs)
        } finally {
            finishRequest()
        }
    }

    private fun finishRequest() {
        running = null
        busy.set(false)
        if (loaded != null) setState(NativeEngineState.READY) else publish()
        scheduleIdleUnload()
    }

    /** Cancels [requestId] if it is the running request. */
    fun cancel(requestId: String) {
        val run = running ?: return
        if (run.requestId != requestId) return
        cancelRunning(run)
    }

    /** Cancels any request, then closes whichever engine is loaded. */
    suspend fun unload() {
        running?.let { cancelRunning(it); it.job.join() }
        withContext(engineThread) { closeLoaded() }
    }

    /** Memory pressure (onTrimMemory RUNNING_LOW and above). */
    fun trim() {
        scope.launch { unload() }
    }

    /** Model files changed (import or delete): forget sticky load failures. */
    fun modelChanged() {
        failed.clear()
        if (state == NativeEngineState.FAILED) state = NativeEngineState.UNLOADED
        publish()
    }

    fun close() {
        running?.let { cancelRunning(it) }
        scope.launch { closeLoaded() }.invokeOnCompletion {
            scope.cancel()
            engineThread.close()
        }
    }

    private fun cancelRunning(run: Running) {
        run.cancelled = true
        runCatching { run.conversation?.cancelProcess() }
        run.job.cancel()
    }

    /**
     * Shares an in-flight load of the same spec. A different spec queues
     * behind it: engineThread is single-threaded and the loads block, so
     * they never overlap.
     */
    @Synchronized
    private fun startLoad(spec: LoadSpec): Deferred<Loaded?> {
        loadJob?.let { if (it.isActive && loadKey == spec.key) return it }
        loadKey = spec.key
        return scope.async { loadBlocking(spec) }.also { loadJob = it }
    }

    /** Runs on engineThread. */
    private fun loadBlocking(spec: LoadSpec): Loaded? {
        loaded?.let { current ->
            if (current.key == spec.key) return current
            // Mutual exclusion: never two engines in memory.
            closeLoaded()
        }
        if (!spec.model.file.isFile) return null
        attemptSlot = spec.slot
        if (failed.contains(spec.key)) {
            setState(NativeEngineState.FAILED)
            return null
        }
        setState(NativeEngineState.LOADING)
        runCatching { Engine.setNativeMinLogSeverity(LogSeverity.ERROR) }
        for (choice in backendOrder(spec.slot)) {
            try {
                val created = create(spec, choice)
                loaded = created
                failed.remove(spec.key)
                setState(NativeEngineState.READY)
                return created
            } catch (e: Throwable) {
                Log.w(TAG, "engine init failed on ${choice.wire} (${spec.slot.name}): ${e.javaClass.simpleName}")
            }
        }
        failed.add(spec.key)
        setState(NativeEngineState.FAILED)
        return null
    }

    /** Runs on engineThread. Throws when the backend cannot initialise. */
    private fun create(spec: LoadSpec, choice: TextBackend): Loaded {
        val path = spec.model.file.absolutePath
        return when (spec.slot) {
            NativeRuntimeSlot.ADVICE -> {
                PestIdConfig.clearVisualBudget()
                LlmLoaded(spec.slot, spec.key, choice.wire, initialized(Engine(LlmConfig.engineConfig(path, choice, cacheDir))))
            }
            NativeRuntimeSlot.PEST_ID -> {
                // Read by LiteRT-LM when the engine is created.
                PestIdConfig.applyVisualBudget()
                LlmLoaded(spec.slot, spec.key, choice.wire, initialized(Engine(PestIdConfig.engineConfig(path, choice, cacheDir))))
            }
            NativeRuntimeSlot.EMBEDDER -> {
                val engine = EmbeddingEngine(EmbedConfig.engineConfig(path, choice, spec.vision, spec.audio, cacheDir))
                try {
                    engine.initialize()
                } catch (t: Throwable) {
                    runCatching { engine.close() }
                    throw t
                }
                EmbedLoaded(spec.key, choice.wire, engine)
            }
        }
    }

    private fun initialized(engine: Engine): Engine {
        try {
            engine.initialize()
        } catch (t: Throwable) {
            runCatching { engine.close() }
            throw t
        }
        return engine
    }

    private fun backendOrder(slot: NativeRuntimeSlot): List<TextBackend> = when (slot) {
        NativeRuntimeSlot.ADVICE -> LlmConfig.BACKEND_ORDER
        NativeRuntimeSlot.PEST_ID -> PestIdConfig.BACKEND_ORDER
        NativeRuntimeSlot.EMBEDDER -> EmbedConfig.BACKEND_ORDER
    }

    /** Runs on engineThread. */
    private fun closeLoaded() {
        val current = loaded ?: run {
            if (state != NativeEngineState.FAILED) setState(NativeEngineState.UNLOADED) else publish()
            return
        }
        loaded = null
        attemptSlot = null
        runCatching { current.close() }
        setState(NativeEngineState.UNLOADED)
    }

    @Synchronized
    private fun scheduleIdleUnload() {
        idleJob?.cancel()
        idleJob = scope.launch {
            delay(LlmConfig.IDLE_UNLOAD_MS)
            if (!busy.get()) closeLoaded()
        }
    }

    @Synchronized
    private fun cancelIdleUnload() {
        idleJob?.cancel()
        idleJob = null
    }

    private fun setState(next: NativeEngineState) {
        state = next
        publish()
    }

    private fun publish() {
        onStatus(status())
    }

    private fun result(
        status: NativeGenerateStatus,
        t0: Long,
        modelVersion: String = "",
        loadMs: Long = 0,
        firstTokenMs: Long = -1,
    ) = NativeGenerateResult(
        status = status,
        text = "",
        modelVersion = modelVersion,
        backend = backend,
        loadMs = loadMs,
        firstTokenMs = firstTokenMs,
        totalMs = SystemClock.elapsedRealtime() - t0,
    )

    private fun embedResult(status: NativeGenerateStatus, t0: Long, modelVersion: String = "") = NativeEmbedResult(
        status = status,
        values = null,
        modelVersion = modelVersion,
        backend = backend,
        totalMs = SystemClock.elapsedRealtime() - t0,
    )

    companion object {
        private const val TAG = "LocalLlm"
        const val BACKEND_NONE = "none"
        private const val PROGRESS_INTERVAL_MS = 100L

        /** Text parts of a streamed message; any other content is ignored. */
        fun textOf(message: Message): String =
            message.contents.contents.filterIsInstance<Content.Text>().joinToString("") { it.text }
    }
}
