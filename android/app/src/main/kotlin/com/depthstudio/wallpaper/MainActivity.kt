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
import android.provider.Settings
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.depthstudio.wallpaper/wallpaper"
    private val STORAGE_PERMISSION_CODE = 1001

    private fun SharedPreferences.Editor.putFromCall(
        call: MethodCall,
        key: String,
        default: Any?
    ) {
        when (val value = call.argument<Any?>(key) ?: default) {
            is Boolean -> putBoolean(key, value)
            is Double -> putFloat(key, value.toFloat())
            is Float -> putFloat(key, value)
            is Int -> putInt(key, value)
            is Long -> putInt(key, value.toInt())
            is String -> putString(key, value)
            null -> remove(key)
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "getSdkInt" -> result.success(Build.VERSION.SDK_INT)

                "saveConfig" -> {
                    val prefs = getSharedPreferences("wallpaper_config", Context.MODE_PRIVATE)
                    prefs.edit().apply {
                        putFromCall(call, "fontSize", 0.30)
                        putFromCall(call, "horizontalPos", 0.50)
                        putFromCall(call, "verticalPos", 0.22)
                        putFromCall(call, "clockDisplay", "Horizontal")
                        putFromCall(call, "clockFormat", "HH:MM")
                        putFromCall(call, "depthLayering", "Standard")
                        putFromCall(call, "fontColor", -1)
                        putFromCall(call, "minuteColor", -1)
                        putFromCall(call, "fontFamily", "Display 1")
                        putFromCall(call, "letterSpacing", 0.0)
                        putFromCall(call, "lineSpacing", 0.04)
                        putFromCall(call, "stretch", 1.0)
                        putFromCall(call, "textOpacity", 1.0)
                        putFromCall(call, "depthMode", "Standard")
                        putFromCall(call, "blurAmount", 18.0)
                        putFromCall(call, "shadowEnabled", true)
                        putFromCall(call, "edgeStrokeEnabled", false)
                        putFromCall(call, "rimWidth", 1.8)
                        putFromCall(call, "rimOpacity", 0.85)
                        putFromCall(call, "rimBlur", 0.0)
                        putFromCall(call, "rimBrightness", 0.65)
                        putFromCall(call, "clockAnimStyle", "SlideUp")
                        putFromCall(call, "clockAnimDuration", 650.0)
                        putFromCall(call, "animateOnScreenOn", true)
                        putFromCall(call, "animateOnUnlock", true)
                        putFromCall(call, "backgroundPath", null)
                        putFromCall(call, "foregroundPath", null)
                        putFromCall(call, "showDate", true)
                        putFromCall(call, "dateFontFamily", "SF Display")
                        putFromCall(call, "dateFontSize", 0.04)
                        putFromCall(call, "dateHorizontalPos", 0.50)
                        putFromCall(call, "dateVerticalPos", 0.14)
                        putFromCall(call, "dateColor", -1)
                        putFromCall(call, "dateFormat", "EEE, MMM dd")
                        putFromCall(call, "dateAllCaps", false)
                        putFromCall(call, "dateBold", false)
                        putFromCall(call, "backgroundDim", 0.0)     // 👈 NUEVO
                        putFromCall(call, "homescreenClock", false)
                        putFromCall(call, "use24Hour", true)
                        putFromCall(call, "musicModeEnabled", true)
                        putFromCall(call, "musicTargetPackage", "all")
                        apply()
                    }
                    MusicNotificationListener.refreshNow()
                    result.success(true)
                }

                "updateGlobalSettings" -> {
                    val prefs = getSharedPreferences("wallpaper_config", Context.MODE_PRIVATE)
                    prefs.edit().apply {
                        if (call.hasArgument("homescreenClock")) {
                            putBoolean("homescreenClock", call.argument<Boolean>("homescreenClock") ?: false)
                        }
                        if (call.hasArgument("use24Hour")) {
                            putBoolean("use24Hour", call.argument<Boolean>("use24Hour") ?: true)
                        }
                        if (call.hasArgument("musicModeEnabled")) {
                            putBoolean("musicModeEnabled", call.argument<Boolean>("musicModeEnabled") ?: true)
                        }
                        if (call.hasArgument("musicTargetPackage")) {
                            putString("musicTargetPackage", call.argument<String>("musicTargetPackage") ?: "all")
                        }
                        apply()
                    }
                    MusicNotificationListener.refreshNow()
                    result.success(true)
                }

                "isStoragePermissionGranted" -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                        result.success(true)
                        return@setMethodCallHandler
                    }
                    val permission = Manifest.permission.READ_EXTERNAL_STORAGE
                    val granted = ContextCompat.checkSelfPermission(this, permission) == PackageManager.PERMISSION_GRANTED
                    result.success(granted)
                }

                "requestStoragePermission" -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                        result.success(true)
                        return@setMethodCallHandler
                    }
                    ActivityCompat.requestPermissions(
                        this,
                        arrayOf(Manifest.permission.READ_EXTERNAL_STORAGE),
                        STORAGE_PERMISSION_CODE
                    )
                    result.success(true)
                }

                "isMusicPermissionGranted" -> {
                    val flat = Settings.Secure.getString(contentResolver, "enabled_notification_listeners")
                    val componentName = ComponentName(this, MusicNotificationListener::class.java).flattenToString()
                    val isGranted = flat != null && flat.contains(componentName)
                    if (isGranted) {
                        MusicNotificationListener.refreshNow()
                    }
                    result.success(isGranted)
                }

                "openMusicPermissionSettings" -> {
                    try {
                        val intent = Intent(Settings.ACTION_NOTIFICATION_LISTENER_SETTINGS)
                        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                        startActivity(intent)
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("INTENT_ERROR", e.message, null)
                    }
                }

                "openAppInfoSettings" -> {
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

                "setWallpaper" -> {
                    try {
                        val intent = Intent(WallpaperManager.ACTION_CHANGE_LIVE_WALLPAPER).apply {
                            putExtra(
                                WallpaperManager.EXTRA_LIVE_WALLPAPER_COMPONENT,
                                ComponentName(this@MainActivity, DepthWallpaperService::class.java)
                            )
                        }
                        startActivity(intent)
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("WALLPAPER_ERROR", e.message, null)
                    }
                }

                else -> result.notImplemented()
            }
        }
    }
}