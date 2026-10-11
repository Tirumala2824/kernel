package com.kernel.sense_ai

import java.io.InputStream

/** Coordinates asynchronous picker replies and late imports across detach. */
internal class ChatMediaSession(private val store: ChatMediaStore) {
    internal class Request(val reply: (ChatMediaLease?, String?) -> Unit) {
        var importing = false
    }
    private var pending: Request? = null
    private var closed = false
    private val tokens = mutableSetOf<String>()

    @Synchronized fun begin(reply: (ChatMediaLease?, String?) -> Unit): Request? {
        if (closed || pending != null) {
            reply(null, if (closed) "picker_unavailable" else "picker_busy")
            return null
        }
        return Request(reply).also { pending = it }
    }

    @Synchronized fun current(): Request? = pending

    fun complete(request: Request, count: Int, name: String, size: Long?, open: () -> InputStream) {
        synchronized(this) {
            if (pending !== request || request.importing) return
            request.importing = true
        }
        if (count != 1) {
            finish(request, null, "select_one_wav")
            return
        }
        try {
            finish(request, store.importWav(name, size, open), null)
        } catch (_: Exception) {
            finish(request, null, "wav_import_failed")
        }
    }

    @Synchronized fun finish(request: Request, lease: ChatMediaLease?, error: String?) {
        if (pending !== request || closed) {
            if (lease != null) store.release(lease.token)
            return
        }
        pending = null
        if (lease != null) tokens.add(lease.token)
        request.reply(lease, error)
    }

    @Synchronized fun adoptImage(path: String): ChatMediaLease? {
        if (closed) return null
        return store.adoptImagePickerCopy(path)?.also { tokens.add(it.token) }
    }

    @Synchronized fun release(token: String) {
        if (token !in tokens) return
        store.release(token)
        tokens.remove(token)
    }

    @Synchronized fun cancel() {
        val request = pending ?: return
        pending = null
        request.reply(null, null)
    }

    @Synchronized fun close() {
        if (closed) return
        cancel()
        closed = true
        for (token in tokens.toList()) {
            try { release(token) } catch (_: Exception) { /* Safe startup retries. */ }
        }
    }
}
