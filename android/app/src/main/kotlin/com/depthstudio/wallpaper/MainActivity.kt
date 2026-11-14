package com.depthstudio.wallpaper

import android.Manifest
import android.app.WallpaperManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.provider.Settings
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import com.depthstudio.wallpaper.rendering.BundledFontRegistry
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterActivity() {
    companion object {
        const val PREFS_NAME = "depth_studio_engine_prefs"
        private const val ENGINE_CHANNEL = "com.depthstudio.app/live_engine"
        private const val MEDIA_PERMISSION_REQ_CODE = 1001
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        AppLogger.init(applicationContext)
        super.onCreate(savedInstanceState)
    }

    private fun SharedPreferences.Editor.writeArg(
        call: MethodCall,
        key: String,
        fallback: Any?
    ) {
        when (val value = call.argument<Any?>(key) ?: fallback) {
            is Boolean -> putBoolean(key, value)
            is Double -> putFloat(key, value.toFloat())
            is Float -> putFloat(key, value)
            is Int -> putInt(key, value)
            is Long -> putInt(key, value.toInt())
            is String -> putString(key, value)
            null -> remove(key)
        }
    }

    private fun SharedPreferences.Editor.writeAppPreferences(call: MethodCall) {
        writeArg(call, "homescreenClock", false)
        writeArg(call, "use24Hour", true)
        writeArg(call, "musicModeEnabled", true)
        writeArg(call, "musicTargetPackage", "all")
        writeArg(call, "appLanguage", "es")
        writeArg(call, "musicOverlayJson", null)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        AppLogger.init(applicationContext)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, ENGINE_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "queryAndroidSdk" -> result.success(Build.VERSION.SDK_INT)

                    "queryBuildVersion" -> {
                        try {
                            val pkgInfo = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                                packageManager.getPackageInfo(
                                    packageName,
                                    PackageManager.PackageInfoFlags.of(0)
                                )
                            } else {
                                @Suppress("DEPRECATION")
                                packageManager.getPackageInfo(packageName, 0)
                            }
                            result.success(pkgInfo.versionName ?: "1.0.0")
                        } catch (_: Exception) {
                            result.success("1.0.0")
                        }
                    }

                    "registerEmbeddedTypeface" -> {
                        val family = call.argument<String>("family")
                        val fontBytes = call.argument<ByteArray>("fontBytes")
                        if (family.isNullOrEmpty() || fontBytes == null || fontBytes.isEmpty()) {
                            result.success(false)
                            return@setMethodCallHandler
                        }
                        try {
                            val safeName = family.replace(Regex("[^a-zA-Z0-9_-]"), "_")
                            val outFile = File(cacheDir, "ds_bundled_fonts/$safeName.font")
                            outFile.parentFile?.mkdirs()
                            outFile.writeBytes(fontBytes)
                            BundledFontRegistry.register(family, outFile.absolutePath)
                            result.success(true)
                        } catch (e: Exception) {
                            AppLogger.e("MainActivity", "Error registering typeface $family", e)
                            result.success(false)
                        }
                    }

                    "syncSceneState" -> {
                        val prefs = getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
                        prefs.edit().apply {
                            writeArg(call, "sceneJson", "{}")
                            writeArg(call, "backgroundAssetPath", null)
                            writeArg(call, "subjectAssetPath", null)
                            writeArg(call, "customClockFontPath", null)
                            writeArg(call, "customDateFontPath", null)
                            writeAppPreferences(call)
                            apply()
                        }
                        MusicNotificationListener.refreshNow()
                        result.success(true)
                    }

                    "syncAppPreferences" -> {
                        val prefs = getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
                        prefs.edit().apply {
                            writeAppPreferences(call)
                            apply()
                        }
                        MusicNotificationListener.refreshNow()
                        result.success(true)
                    }

                    "checkMediaAccess" -> {
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                            result.success(true)
                            return@setMethodCallHandler
                        }
                        val granted = ContextCompat.checkSelfPermission(
                            this,
                            Manifest.permission.READ_EXTERNAL_STORAGE
                        ) == PackageManager.PERMISSION_GRANTED
                        result.success(granted)
                    }

                    "promptMediaAccess" -> {
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                            result.success(true)
                            return@setMethodCallHandler
                        }
                        ActivityCompat.requestPermissions(
                            this,
                            arrayOf(Manifest.permission.READ_EXTERNAL_STORAGE),
                            MEDIA_PERMISSION_REQ_CODE
                        )
                        result.success(true)
                    }

                    "checkNotificationListener" -> {
                        val flat = Settings.Secure.getString(
                            contentResolver,
                            "enabled_notification_listeners"
                        )
                        val componentName =
                            ComponentName(this, MusicNotificationListener::class.java)
                                .flattenToString()
                        val isGranted = flat != null && flat.contains(componentName)
                        if (isGranted) {
                            MusicNotificationListener.refreshNow()
                        }
                        result.success(isGranted)
                    }

                    "openNotificationListenerSettings" -> {
                        try {
                            val intent = Intent(Settings.ACTION_NOTIFICATION_LISTENER_SETTINGS)
                            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                            startActivity(intent)
                            result.success(true)
                        } catch (e: Exception) {
                            result.error("INTENT_ERROR", e.message, null)
                        }
                    }

                    "openSystemAppDetails" -> {
                        try {
                            val intent = Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
                                data = Uri.fromParts("package", packageName, null)
                                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                            }
                            startActivity(intent)
                            result.success(true)
                        } catch (e: Exception) {
                            result.error("INTENT_ERROR", e.message, null)
                        }
                    }

                    "launchSystemWallpaperPicker" -> {
                        try {
                            val directIntent =
                                Intent(WallpaperManager.ACTION_CHANGE_LIVE_WALLPAPER).apply {
                                    putExtra(
                                        WallpaperManager.EXTRA_LIVE_WALLPAPER_COMPONENT,
                                        ComponentName(
                                            this@MainActivity,
                                            LiveSceneWallpaperService::class.java
                                        )
                                    )
                                }
                            startActivity(directIntent)
                            result.success(true)
                        } catch (_: Exception) {
                            try {
                                val chooserIntent =
                                    Intent(WallpaperManager.ACTION_LIVE_WALLPAPER_CHOOSER)
                                startActivity(chooserIntent)
                                result.success(true)
                            } catch (e: Exception) {
                                result.error("WALLPAPER_ERROR", e.message, null)
                            }
                        }
                    }

                    else -> result.notImplemented()
                }
            }
    }
}