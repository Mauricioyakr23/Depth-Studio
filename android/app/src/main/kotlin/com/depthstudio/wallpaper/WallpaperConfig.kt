package com.depthstudio.wallpaper

import android.content.Context

data class WallpaperConfig(
    val fontSize: Float = 0.30f,
    val horizontalPos: Float = 0.50f,
    val verticalPos: Float = 0.22f,

    val clockDisplay: String = "Horizontal",
    val clockFormat: String = "HH:MM",
    val depthLayering: String = "Standard",
    val fontColor: Int = -1,
    val minuteColor: Int = -1,
    val fontFamily: String = "Display 1",
    val letterSpacing: Float = 0.0f,
    val lineSpacing: Float = 0.04f,
    val stretch: Float = 1.0f,

    val depthMode: String = "Standard",
    val blurAmount: Float = 18.0f,
    val textOpacity: Float = 1.0f,
    val shadowEnabled: Boolean = true,
    val edgeStrokeEnabled: Boolean = false,
    val rimWidth: Float = 1.8f,
    val rimOpacity: Float = 0.85f,
    val rimBlur: Float = 0.0f,
    val rimBrightness: Float = 0.65f,

    val clockAnimStyle: String = "SlideUp",
    val clockAnimDuration: Float = 650.0f,
    val animateOnScreenOn: Boolean = true,
    val animateOnUnlock: Boolean = true,

    val backgroundPath: String? = null,
    val foregroundPath: String? = null,

    val showDate: Boolean = true,
    val dateFontFamily: String = "SF Display",
    val dateFontSize: Float = 0.04f,
    val dateHorizontalPos: Float = 0.50f,
    val dateVerticalPos: Float = 0.14f,
    val dateColor: Int = -1,
    val dateFormat: String = "EEE, MMM dd",
    val dateAllCaps: Boolean = false,
    val dateBold: Boolean = false,

    val backgroundDim: Float = 0.0f,             // 👈 NUEVO

    val homescreenClock: Boolean = false,
    val use24Hour: Boolean = true
) {
    companion object {
        fun fromSharedPreferences(context: Context): WallpaperConfig {
            val prefs = context.getSharedPreferences("wallpaper_config", Context.MODE_PRIVATE)
            val hrColor = prefs.getInt("fontColor", -1)
            return WallpaperConfig(
                fontSize = prefs.getFloat("fontSize", 0.30f),
                horizontalPos = prefs.getFloat("horizontalPos", 0.50f),
                verticalPos = prefs.getFloat("verticalPos", 0.22f),

                clockDisplay = prefs.getString("clockDisplay", "Horizontal") ?: "Horizontal",
                clockFormat = prefs.getString("clockFormat", "HH:MM") ?: "HH:MM",
                depthLayering = prefs.getString("depthLayering", "Standard") ?: "Standard",
                fontFamily = prefs.getString("fontFamily", "Display 1") ?: "Display 1",
                fontColor = hrColor,
                minuteColor = prefs.getInt("minuteColor", hrColor),

                letterSpacing = prefs.getFloat("letterSpacing", 0.0f),
                lineSpacing = prefs.getFloat("lineSpacing", 0.04f),
                stretch = prefs.getFloat("stretch", 1.0f),

                depthMode = prefs.getString("depthMode", "Standard") ?: "Standard",
                blurAmount = prefs.getFloat("blurAmount", 18.0f),
                textOpacity = prefs.getFloat("textOpacity", 1.0f),

                shadowEnabled = prefs.getBoolean("shadowEnabled", true),
                edgeStrokeEnabled = prefs.getBoolean("edgeStrokeEnabled", false),
                rimWidth = prefs.getFloat("rimWidth", 1.8f),
                rimOpacity = prefs.getFloat("rimOpacity", 0.85f),
                rimBlur = prefs.getFloat("rimBlur", 0.0f),
                rimBrightness = prefs.getFloat("rimBrightness", 0.65f),

                clockAnimStyle = prefs.getString("clockAnimStyle", "SlideUp") ?: "SlideUp",
                clockAnimDuration = prefs.getFloat("clockAnimDuration", 650.0f),
                animateOnScreenOn = prefs.getBoolean("animateOnScreenOn", true),
                animateOnUnlock = prefs.getBoolean("animateOnUnlock", true),

                backgroundPath = prefs.getString("backgroundPath", null),
                foregroundPath = prefs.getString("foregroundPath", null),
                showDate = prefs.getBoolean("showDate", true),
                dateFontFamily = prefs.getString("dateFontFamily", "SF Display") ?: "SF Display",
                dateFontSize = prefs.getFloat("dateFontSize", 0.04f),
                dateHorizontalPos = prefs.getFloat("dateHorizontalPos", 0.50f),
                dateVerticalPos = prefs.getFloat("dateVerticalPos", 0.14f),
                dateColor = prefs.getInt("dateColor", -1),
                dateFormat = prefs.getString("dateFormat", "EEE, MMM dd") ?: "EEE, MMM dd",
                dateAllCaps = prefs.getBoolean("dateAllCaps", false),
                dateBold = prefs.getBoolean("dateBold", false),

                backgroundDim = prefs.getFloat("backgroundDim", 0.0f),  // 👈

                homescreenClock = prefs.getBoolean("homescreenClock", false),
                use24Hour = prefs.getBoolean("use24Hour", true)
            )
        }
    }
}