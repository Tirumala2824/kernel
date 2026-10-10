package com.kernel.model_hub

import android.app.ActivityManager
import android.content.Context
import android.content.pm.PackageManager
import android.net.ConnectivityManager
import android.net.NetworkCapabilities
import android.os.Build
import android.os.storage.StorageManager
import java.io.File
import java.io.IOException

/**
 * Process-wide singletons shared by the plugin, the JobService and the
 * Worker (they may run without a Flutter engine attached).
 */
object HubServices {
    @Volatile
    private var cache: HashCache? = null

    fun hashCache(ctx: Context): HashCache = cache ?: synchronized(this) {
        cache ?: HashCache(File(File(ctx.filesDir, "model_hub"), "hashes.tsv")).also { cache = it }
    }

    fun modelsDir(ctx: Context): File? =
        ctx.getExternalFilesDir(null)?.let { File(it, "models") }?.also { it.mkdirs() }

    fun legacyLlmDir(ctx: Context): File? = ctx.getExternalFilesDir("llm")

    fun storage(ctx: Context) = ModelStorage(modelsDir(ctx), legacyLlmDir(ctx))

    fun downloader(ctx: Context) = ResumableDownloader(
        space = AndroidSpaceProbe(ctx.applicationContext),
        hashCache = hashCache(ctx),
    )

    fun runner(ctx: Context) = DownloadRunner(downloader(ctx))
}

/** StorageManager.getAllocatableBytes (API 26+), else File.usableSpace. */
class AndroidSpaceProbe(private val ctx: Context) : SpaceProbe {
    override fun allocatableBytes(dir: File): Long {
        dir.mkdirs()
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            try {
                val sm = ctx.getSystemService(StorageManager::class.java)
                if (sm != null) return sm.getAllocatableBytes(sm.getUuidForPath(dir))
            } catch (_: IOException) {
                // Fall through to usableSpace.
            } catch (_: IllegalArgumentException) {
                // Fall through to usableSpace.
            }
        }
        return dir.usableSpace
    }
}

/** Device facts used to pick models (RAM, SoC, Gallery version, network). */
object DeviceProbe {
    const val GALLERY_PACKAGE = "com.google.ai.edge.gallery"

    fun info(ctx: Context): NativeDeviceInfo {
        val am = ctx.getSystemService(ActivityManager::class.java)
        val mi = ActivityManager.MemoryInfo()
        am?.getMemoryInfo(mi)
        val soc = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) Build.SOC_MODEL else null
        val socMan = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) Build.SOC_MANUFACTURER else null
        return NativeDeviceInfo(
            totalRamBytes = mi.totalMem,
            sdkInt = Build.VERSION.SDK_INT.toLong(),
            socModel = soc?.takeUnless { it.isBlank() || it == Build.UNKNOWN },
            socManufacturer = socMan?.takeUnless { it.isBlank() || it == Build.UNKNOWN },
            galleryVersionName = galleryVersion(ctx),
        )
    }

    /** Needs the `<queries>` entry for the Gallery package (Android 11+). */
    fun galleryVersion(ctx: Context): String? = try {
        val pm = ctx.packageManager
        val info = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            pm.getPackageInfo(GALLERY_PACKAGE, PackageManager.PackageInfoFlags.of(0))
        } else {
            @Suppress("DEPRECATION")
            pm.getPackageInfo(GALLERY_PACKAGE, 0)
        }
        info.versionName
    } catch (_: PackageManager.NameNotFoundException) {
        null
    }

    fun network(ctx: Context): NativeNetworkState {
        val cm = ctx.getSystemService(ConnectivityManager::class.java)
        val caps = cm?.getNetworkCapabilities(cm.activeNetwork)
        return NativeNetworkState(
            connected = caps?.hasCapability(NetworkCapabilities.NET_CAPABILITY_INTERNET) == true,
            unmetered = caps?.hasCapability(NetworkCapabilities.NET_CAPABILITY_NOT_METERED) == true,
        )
    }
}
