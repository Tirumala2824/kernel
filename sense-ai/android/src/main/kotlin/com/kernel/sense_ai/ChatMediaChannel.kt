package com.kernel.sense_ai

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.os.Handler
import android.os.Looper
import android.provider.OpenableColumns
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.StandardMethodCodec
import java.io.IOException
import java.util.concurrent.Executors

/** Private UI transport, independent of the classifier/domain contract. */
internal class ChatMediaChannel(messenger: BinaryMessenger, private val context: Context) {
    private val session = ChatMediaSession(ChatMediaStore.shared(context.cacheDir))
    private val main = Handler(Looper.getMainLooper())
    private val imports = Executors.newSingleThreadExecutor()
    private val channel = MethodChannel(messenger, "com.kernel.sense_ai/chat_media",
        StandardMethodCodec.INSTANCE, messenger.makeBackgroundTaskQueue())
    @Volatile private var activity: Activity? = null
    // Read/written only on main. Different codes prevent a stale activity result
    // from satisfying a new selection after an activity detach/cancellation.
    private var nextCode = FIRST_REQUEST
    private var launched: Pair<Int, ChatMediaSession.Request>? = null

    init {
        channel.setMethodCallHandler { call, result ->
            try {
                when (call.method) {
                    "pickWav" -> {
                        val request = session.begin { lease, error ->
                            if (error == null) result.success(lease?.asMap())
                            else result.error(error, "Could not import the selected WAV", null)
                        }
                        if (request != null) main.post { launch(request) }
                    }
                    "release" -> {
                        call.argument<String>("token")?.let { session.release(it) }
                        result.success(null)
                    }
                    "adoptImagePickerCopy" -> {
                        val path = call.argument<String>("path")
                        result.success(path?.let { session.adoptImage(it)?.asMap() })
                    }
                    else -> result.notImplemented()
                }
            } catch (_: Exception) {
                // No raw paths, filenames or provider exception details in errors.
                result.error("media_operation_failed", "Media operation failed", null)
            }
        }
    }

    fun attach(activity: Activity) { this.activity = activity }

    fun detachActivity(forConfigurationChange: Boolean) {
        activity = null
        if (!forConfigurationChange) {
            launched = null
            session.cancel()
        }
    }

    private fun launch(request: ChatMediaSession.Request) {
        if (session.current() !== request) return
        val host = activity
        if (host == null) {
            session.finish(request, null, "picker_unavailable")
            return
        }
        val code = nextCode++
        if (nextCode > LAST_REQUEST) nextCode = FIRST_REQUEST
        launched = code to request
        try {
            host.startActivityForResult(Intent(Intent.ACTION_OPEN_DOCUMENT).apply {
                addCategory(Intent.CATEGORY_OPENABLE)
                type = "audio/*"
                putExtra(Intent.EXTRA_ALLOW_MULTIPLE, false)
                addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
            }, code)
        } catch (_: Exception) {
            launched = null
            session.finish(request, null, "picker_unavailable")
        }
    }

    fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean {
        if (requestCode !in FIRST_REQUEST..LAST_REQUEST) return false
        val selection = launched ?: return true
        if (selection.first != requestCode) return true
        launched = null
        val request = selection.second
        if (resultCode != Activity.RESULT_OK) {
            session.finish(request, null, null)
            return true
        }
        val uris = buildSet {
            data?.data?.let { add(it) }
            data?.clipData?.let { clips ->
                for (index in 0 until clips.itemCount) add(clips.getItemAt(index).uri)
            }
        }
        if (uris.size != 1 || (data?.clipData?.itemCount ?: 0) > 1) {
            session.finish(request, null, "select_one_wav")
            return true
        }
        val uri = uris.single()
        if (uri == null || uri.scheme != "content") {
            session.finish(request, null, "wav_import_failed")
            return true
        }
        imports.execute {
            if (session.current() !== request) return@execute
            try {
                var name = "recording.wav"
                var size: Long? = null
                context.contentResolver.query(uri, arrayOf(OpenableColumns.DISPLAY_NAME, OpenableColumns.SIZE),
                    null, null, null)?.use { cursor ->
                    if (cursor.moveToFirst()) {
                        val n = cursor.getColumnIndex(OpenableColumns.DISPLAY_NAME)
                        val s = cursor.getColumnIndex(OpenableColumns.SIZE)
                        if (n >= 0 && !cursor.isNull(n)) name = cursor.getString(n)
                        if (s >= 0 && !cursor.isNull(s)) size = cursor.getLong(s)
                    }
                }
                session.complete(request, 1, name, size) {
                    context.contentResolver.openInputStream(uri) ?: throw IOException("unreadable_wav")
                }
            } catch (_: Exception) {
                session.finish(request, null, "wav_import_failed")
            }
        }
        return true
    }

    fun detach() {
        channel.setMethodCallHandler(null)
        detachActivity(false)
        session.close()
        // Finish any current bounded import: the closed session deletes its
        // late copy. Interrupting a provider stream is not reliably supported.
        imports.shutdown()
    }

    private companion object {
        const val FIRST_REQUEST = 0x6E00
        const val LAST_REQUEST = 0x6EFF
    }
}
