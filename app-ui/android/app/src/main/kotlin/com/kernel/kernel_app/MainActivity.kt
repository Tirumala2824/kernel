package com.kernel.kernel_app

import android.content.pm.PackageManager
import android.content.pm.Signature
import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.security.MessageDigest

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // Maps config for the Routes API headers: the Android-restricted key
        // from the manifest meta-data (empty when not configured), plus the
        // package name and signing-certificate SHA-1 the key is bound to.
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, MAPS_CONFIG_CHANNEL)
            .setMethodCallHandler { call, result ->
                if (call.method == "read") {
                    result.success(
                        mapOf(
                            "apiKey" to metaDataString(MAPS_KEY_META),
                            "packageName" to packageName,
                            "certSha1" to signingCertSha1(),
                        ),
                    )
                } else {
                    result.notImplemented()
                }
            }
    }

    private fun metaDataString(name: String): String = try {
        val info = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            packageManager.getApplicationInfo(
                packageName,
                PackageManager.ApplicationInfoFlags.of(PackageManager.GET_META_DATA.toLong()),
            )
        } else {
            @Suppress("DEPRECATION")
            packageManager.getApplicationInfo(packageName, PackageManager.GET_META_DATA)
        }
        info.metaData?.getString(name)?.trim().orEmpty()
    } catch (e: Exception) {
        ""
    }

    private fun signingCertSha1(): String = try {
        val signatures: Array<Signature>? =
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
                val info = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                    packageManager.getPackageInfo(
                        packageName,
                        PackageManager.PackageInfoFlags.of(
                            PackageManager.GET_SIGNING_CERTIFICATES.toLong(),
                        ),
                    )
                } else {
                    packageManager.getPackageInfo(
                        packageName,
                        PackageManager.GET_SIGNING_CERTIFICATES,
                    )
                }
                info.signingInfo?.apkContentsSigners
            } else {
                @Suppress("DEPRECATION")
                packageManager.getPackageInfo(packageName, PackageManager.GET_SIGNATURES).signatures
            }
        val cert = signatures?.firstOrNull()
        if (cert == null) {
            ""
        } else {
            MessageDigest.getInstance("SHA-1").digest(cert.toByteArray())
                .joinToString("") { "%02X".format(it) }
        }
    } catch (e: Exception) {
        ""
    }

    private companion object {
        const val MAPS_CONFIG_CHANNEL = "com.kernel.kernel_app/maps_config"
        const val MAPS_KEY_META = "com.google.android.geo.API_KEY"
    }
}
