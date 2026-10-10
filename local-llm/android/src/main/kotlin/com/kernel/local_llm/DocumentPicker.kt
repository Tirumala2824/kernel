package com.kernel.local_llm

import android.app.Activity
import android.content.ActivityNotFoundException
import android.content.ContentResolver
import android.content.Intent
import io.flutter.plugin.common.PluginRegistry
import kotlin.coroutines.Continuation
import kotlin.coroutines.resume
import kotlinx.coroutines.suspendCancellableCoroutine

/**
 * System document picker (ACTION_OPEN_DOCUMENT, any type) for a `.litertlm`
 * file. SAF cannot filter by extension and the file has no registered MIME
 * type, so the picked document's display name is checked afterwards. Only
 * a content:// URI with a `.litertlm` name is returned; anything else is
 * null. No storage permission is involved.
 */
class DocumentPicker(private val resolver: ContentResolver) : PluginRegistry.ActivityResultListener {
    var activity: Activity? = null

    private var pending: Continuation<String?>? = null

    /** Main thread. Null when there is no activity or a pick is already open. */
    suspend fun pick(): String? {
        val act = activity ?: return null
        if (pending != null) return null
        return suspendCancellableCoroutine { cont ->
            val intent = Intent(Intent.ACTION_OPEN_DOCUMENT)
                .addCategory(Intent.CATEGORY_OPENABLE)
                .setType("*/*")
                // Files already on the phone only (no cloud document providers).
                .putExtra(Intent.EXTRA_LOCAL_ONLY, true)
            pending = cont
            cont.invokeOnCancellation { if (pending === cont) pending = null }
            try {
                act.startActivityForResult(intent, REQUEST_CODE)
            } catch (_: ActivityNotFoundException) {
                pending = null
                cont.resume(null)
            }
        }
    }

    /** The activity went away while the picker was open. */
    fun detach() {
        activity = null
        pending?.let { pending = null; it.resume(null) }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean {
        if (requestCode != REQUEST_CODE) return false
        val cont = pending ?: return true
        pending = null
        val uri = data?.data
        if (resultCode != Activity.RESULT_OK || uri == null || uri.scheme != ContentResolver.SCHEME_CONTENT) {
            cont.resume(null)
            return true
        }
        val name = ModelImporter.displayName(resolver, uri)
        cont.resume(if (ModelStore.sanitizeFileName(name) != null) uri.toString() else null)
        return true
    }

    private companion object {
        /** Arbitrary, unique within this app's plugins. */
        const val REQUEST_CODE = 0x4C4C
    }
}
