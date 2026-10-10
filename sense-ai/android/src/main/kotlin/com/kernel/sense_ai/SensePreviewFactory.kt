package com.kernel.sense_ai

import android.content.Context
import android.view.View
import androidx.camera.view.PreviewView
import io.flutter.plugin.common.StandardMessageCodec
import io.flutter.plugin.platform.PlatformView
import io.flutter.plugin.platform.PlatformViewFactory

/**
 * Platform view behind the Dart `SenseCameraPreview` widget. The camera is
 * bound while the view exists and released when Flutter disposes it.
 * PreviewView uses a TextureView (COMPATIBLE) so it composes correctly with
 * Flutter's texture-layer platform views.
 */
class SensePreviewFactory(private val camera: CameraController) : PlatformViewFactory(StandardMessageCodec.INSTANCE) {
    override fun create(context: Context?, viewId: Int, args: Any?): PlatformView {
        val params = args as? Map<*, *>
        val lowLightBoost = params?.get("lowLightBoost") as? Boolean ?: false
        return SensePreviewView(requireNotNull(context), camera, lowLightBoost)
    }

    companion object {
        /** Must match `SenseCameraPreview.viewType` in Dart. */
        const val VIEW_TYPE = "com.kernel.sense_ai/camera_preview"
    }
}

private class SensePreviewView(context: Context, private val camera: CameraController, lowLightBoost: Boolean) : PlatformView {
    private val preview = PreviewView(context).apply {
        implementationMode = PreviewView.ImplementationMode.COMPATIBLE
        scaleType = PreviewView.ScaleType.FILL_CENTER
    }

    init {
        camera.attach(preview, lowLightBoost)
    }

    override fun getView(): View = preview

    override fun dispose() {
        camera.detach(preview)
    }
}
