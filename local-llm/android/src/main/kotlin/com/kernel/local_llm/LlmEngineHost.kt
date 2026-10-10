package com.kernel.local_llm

import android.os.SystemClock
import android.util.Log
import com.google.ai.edge.litertlm.Content
import com.google.ai.edge.litertlm.Conversation
import com.google.ai.edge.litertlm.Engine
import com.google.ai.edge.litertlm.LogSeverity
import com.google.ai.edge.litertlm.Message
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
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import kotlinx.coroutines.withTimeoutOrNull

/**
 * Owns the LiteRT-LM [Engine] (about 2.5 GB in memory for Gemma 4 E2B).
 *
 * - Lazy: nothing loads until [load] or [generate] is called.
 * - GPU first, then CPU when GPU initialization fails. A model that failed
 *   on both is not retried until the file changes.
 * - Text only: see [LlmConfig.engineConfig]; no audio or vision backend.
 * - One generation at a time; a second request is rejected as busy.
 * - Each request gets its own short-lived [Conversation], closed afterwards.
 * - Unloads after [LlmConfig.IDLE_UNLOAD_MS] idle, on [trim] and on [close].
 * - Never logs prompts, outputs or native error messages (they can echo
 *   text). Native log severity is ERROR.
 *
 * All engine create/initialize/close calls run on one dedicated thread.
 */
class LlmEngineHost(
    private val store: ModelStore,
    private val cacheDir: String,
    private val onStatus: (NativeEngineStatus) -> Unit,
    private val onProgress: (NativeGenerationProgress) -> Unit,
) {
    private val engineThread = Executors.newSingleThreadExecutor { r ->
        Thread(r, "local-llm-engine").apply { isDaemon = true }
    }.asCoroutineDispatcher()
    private val scope = CoroutineScope(SupervisorJob() + engineThread)

    // Engine fields are only written on engineThread.
    @Volatile private var engine: Engine? = null
    @Volatile private var loadedKey: String? = null
    @Volatile private var failedKey: String? = null
    @Volatile private var backend: String = BACKEND_NONE
    @Volatile private var state: NativeEngineState = NativeEngineState.UNLOADED

    private var loadJob: Deferred<Engine?>? = null
    private var idleJob: Job? = null

    private val generating = AtomicBoolean(false)
    @Volatile private var running: Running? = null

    private class Running(val requestId: String, val job: Job) {
        @Volatile var conversation: Conversation? = null
        @Volatile var cancelled = false
    }

    fun status(): NativeEngineStatus = NativeEngineStatus(
        state = state,
        modelPresent = store.findModel() != null,
        backend = backend,
    )

    /** Loads now if needed. Returns the resulting status. */
    suspend fun load(): NativeEngineStatus {
        startLoad().await()
        scheduleIdleUnload()
        return status()
    }

    suspend fun generate(
        requestId: String,
        systemInstruction: String,
        prompt: String,
        timeoutMs: Long,
    ): NativeGenerateResult {
        val t0 = SystemClock.elapsedRealtime()
        val model = store.findModel() ?: return result(NativeGenerateStatus.NO_MODEL, t0)
        if (!generating.compareAndSet(false, true)) return result(NativeGenerateStatus.BUSY, t0)
        val run = Running(requestId, currentCoroutineContext()[Job]!!)
        running = run
        cancelIdleUnload()
        var loadMs = 0L
        var firstTokenMs = -1L
        try {
            val sidecar = withContext(Dispatchers.IO) { store.ensureSidecar(model) }
            val budget = (timeoutMs - (SystemClock.elapsedRealtime() - t0)).coerceAtLeast(1)
            val text = withTimeoutOrNull(budget) {
                val loadStart = SystemClock.elapsedRealtime()
                val wasLoaded = engine != null && loadedKey == model.key
                // The load is not part of this request's job: if the request
                // times out, the engine still finishes loading for the next one.
                val eng = startLoad().await() ?: return@withTimeoutOrNull null
                if (!wasLoaded) loadMs = SystemClock.elapsedRealtime() - loadStart
                if (run.cancelled) throw CancellationException("cancelled")
                setState(NativeEngineState.BUSY)
                val out = StringBuilder()
                withContext(engineThread) {
                    eng.createConversation(LlmConfig.conversationConfig(systemInstruction)).use { conversation ->
                        run.conversation = conversation
                        var chunks = 0L
                        var lastEmit = 0L
                        try {
                            conversation.sendMessageAsync(prompt).collect { message ->
                                val piece = textOf(message)
                                if (piece.isEmpty()) return@collect
                                val now = SystemClock.elapsedRealtime()
                                if (firstTokenMs < 0) firstTokenMs = now - t0
                                out.append(piece)
                                chunks++
                                if (now - lastEmit >= PROGRESS_INTERVAL_MS) {
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
                run.cancelled -> result(NativeGenerateStatus.CANCELLED, t0, sidecar.version)
                text == null && engine == null && failedKey == model.key ->
                    result(NativeGenerateStatus.LOAD_FAILED, t0, sidecar.version, loadMs)
                text == null -> result(NativeGenerateStatus.TIMEOUT, t0, sidecar.version, loadMs, firstTokenMs)
                else -> NativeGenerateResult(
                    status = NativeGenerateStatus.OK,
                    text = text,
                    modelVersion = sidecar.version,
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
            running = null
            generating.set(false)
            if (engine != null) setState(NativeEngineState.READY) else publish()
            scheduleIdleUnload()
        }
    }

    /** Cancels [requestId] if it is the running generation. */
    fun cancel(requestId: String) {
        val run = running ?: return
        if (run.requestId != requestId) return
        cancelRunning(run)
    }

    /** Cancels any generation, then closes the engine. */
    suspend fun unload() {
        running?.let { cancelRunning(it); it.job.join() }
        withContext(engineThread) { closeEngine() }
    }

    /** Memory pressure (onTrimMemory RUNNING_LOW and above). */
    fun trim() {
        scope.launch { unload() }
    }

    /** Model files changed (import or delete): forget a sticky load failure. */
    fun modelChanged() {
        failedKey = null
        publish()
    }

    fun close() {
        running?.let { cancelRunning(it) }
        scope.launch { closeEngine() }.invokeOnCompletion {
            scope.cancel()
            engineThread.close()
        }
    }

    private fun cancelRunning(run: Running) {
        run.cancelled = true
        runCatching { run.conversation?.cancelProcess() }
        run.job.cancel()
    }

    @Synchronized
    private fun startLoad(): Deferred<Engine?> {
        loadJob?.let { if (it.isActive) return it }
        return scope.async { loadBlocking() }.also { loadJob = it }
    }

    /** Runs on engineThread. */
    private fun loadBlocking(): Engine? {
        val model = store.findModel()
        if (model == null) {
            closeEngine()
            return null
        }
        engine?.let { current ->
            if (loadedKey == model.key) return current
            closeEngine()
        }
        if (failedKey == model.key) {
            setState(NativeEngineState.FAILED)
            return null
        }
        setState(NativeEngineState.LOADING)
        runCatching { Engine.setNativeMinLogSeverity(LogSeverity.ERROR) }
        for (choice in LlmConfig.BACKEND_ORDER) {
            var candidate: Engine? = null
            try {
                candidate = Engine(LlmConfig.engineConfig(model.file.absolutePath, choice, cacheDir))
                candidate.initialize()
                engine = candidate
                loadedKey = model.key
                backend = choice.wire
                failedKey = null
                setState(NativeEngineState.READY)
                return candidate
            } catch (e: Throwable) {
                runCatching { candidate?.close() }
                Log.w(TAG, "engine init failed on ${choice.wire}: ${e.javaClass.simpleName}")
            }
        }
        failedKey = model.key
        backend = BACKEND_NONE
        setState(NativeEngineState.FAILED)
        return null
    }

    /** Runs on engineThread. */
    private fun closeEngine() {
        val current = engine ?: run {
            if (state != NativeEngineState.FAILED) setState(NativeEngineState.UNLOADED) else publish()
            return
        }
        engine = null
        loadedKey = null
        backend = BACKEND_NONE
        runCatching { current.close() }
        setState(NativeEngineState.UNLOADED)
    }

    @Synchronized
    private fun scheduleIdleUnload() {
        idleJob?.cancel()
        idleJob = scope.launch {
            delay(LlmConfig.IDLE_UNLOAD_MS)
            if (!generating.get()) closeEngine()
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

    companion object {
        private const val TAG = "LocalLlm"
        const val BACKEND_NONE = "none"
        private const val PROGRESS_INTERVAL_MS = 100L

        /** Text parts of a streamed message; any other content is ignored. */
        fun textOf(message: Message): String =
            message.contents.contents.filterIsInstance<Content.Text>().joinToString("") { it.text }
    }
}
