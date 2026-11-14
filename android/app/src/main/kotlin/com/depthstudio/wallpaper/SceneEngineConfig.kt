package com.depthstudio.wallpaper

import android.content.Context
import org.json.JSONObject

data class SceneEngineConfig(
    val fontSize: Float = 0.30f,
    val horizontalPos: Float = 0.50f,
    val verticalPos: Float = 0.22f,
    val clockDisplay: String = "Horizontal",
    val clockFormat: String = "HH:MM",
    val depthLayering: String = "Standard",
    val fontColor: Int = -1,
    val minuteColor: Int = -1,
    val fontFamily: String = "Display 1",
    val customFontPath: String? = null,
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
    val dateFontFamily: String = "Sans-Serif",
    val customDateFontPath: String? = null,
    val dateFontSize: Float = 0.04f,
    val dateHorizontalPos: Float = 0.50f,
    val dateVerticalPos: Float = 0.14f,
    val dateColor: Int = -1,
    val dateFormat: String = "EEE, MMM dd",
    val dateAllCaps: Boolean = false,
    val dateBold: Boolean = false,
    val dateDepthMode: String = "Standard",
    val dateBlurAmount: Float = 18.0f,
    val dateOpacity: Float = 1.0f,
    val dateShadowEnabled: Boolean = true,
    val dateRimBrightness: Float = 0.65f,
    val backgroundDim: Float = 0.0f,
    val homescreenClock: Boolean = false,
    val use24Hour: Boolean = true
) {
    companion object {
        private const val TAG = "SceneEngineConfig"

        fun loadFromStorage(context: Context): SceneEngineConfig {
            val prefs = context.getSharedPreferences(MainActivity.PREFS_NAME, Context.MODE_PRIVATE)
            val rawSceneJson = prefs.getString("sceneJson", "{}") ?: "{}"
            val bgPath = prefs.getString("backgroundAssetPath", null)
            val fgPath = prefs.getString("subjectAssetPath", null)
            val customClockFont = prefs.getString("customClockFontPath", null)
            val customDateFont = prefs.getString("customDateFontPath", null)
            val homescreenClock = prefs.getBoolean("homescreenClock", false)
            val use24Hour = prefs.getBoolean("use24Hour", true)

            return try {
                val root = JSONObject(rawSceneJson)
                val sceneObj = root.optJSONObject("scene") ?: JSONObject()
                val clockObj = root.optJSONObject("clock") ?: JSONObject()
                val opticalObj = root.optJSONObject("optical") ?: JSONObject()
                val dateObj = root.optJSONObject("date") ?: JSONObject()

                fun JSONObject.floatOr(key: String, default: Float): Float =
                    if (has(key) && !isNull(key)) optDouble(key, default.toDouble()).toFloat() else default

                fun JSONObject.strOr(key: String, default: String): String =
                    if (has(key) && !isNull(key)) optString(key, default) else default

                val hrColor = clockObj.optInt("hourArgb", -1)

                SceneEngineConfig(
                    fontSize = clockObj.floatOr("scale", 0.30f),
                    horizontalPos = clockObj.floatOr("x", 0.50f),
                    verticalPos = clockObj.floatOr("y", 0.22f),
                    clockDisplay = clockObj.strOr("display", "Horizontal"),
                    clockFormat = clockObj.strOr("format", "HH:MM"),
                    depthLayering = sceneObj.strOr("depthLayering", "Standard"),
                    fontColor = hrColor,
                    minuteColor = clockObj.optInt("minuteArgb", hrColor),
                    fontFamily = clockObj.strOr("typeface", "Display 1"),
                    customFontPath = customClockFont,
                    letterSpacing = clockObj.floatOr("letterSpacing", 0.0f),
                    lineSpacing = clockObj.floatOr("lineSpacing", 0.04f),
                    stretch = clockObj.floatOr("stretch", 1.0f),
                    depthMode = opticalObj.strOr("material", "Standard"),
                    blurAmount = opticalObj.floatOr("blur", 18.0f),
                    textOpacity = clockObj.floatOr("opacity", 1.0f),
                    shadowEnabled = opticalObj.optBoolean("shadow", true),
                    edgeStrokeEnabled = opticalObj.optBoolean("rimEnabled", false),
                    rimWidth = opticalObj.floatOr("rimWidth", 1.8f),
                    rimOpacity = opticalObj.floatOr("rimOpacity", 0.85f),
                    rimBlur = opticalObj.floatOr("rimBlur", 0.0f),
                    rimBrightness = opticalObj.floatOr("rimBrightness", 0.65f),
                    clockAnimStyle = clockObj.strOr("animStyle", "SlideUp"),
                    clockAnimDuration = clockObj.floatOr("animDurationMs", 650.0f),
                    animateOnScreenOn = clockObj.optBoolean("animOnWake", true),
                    animateOnUnlock = clockObj.optBoolean("animOnUnlock", true),
                    backgroundPath = bgPath,
                    foregroundPath = fgPath,
                    showDate = dateObj.optBoolean("enabled", true),
                    dateFontFamily = dateObj.strOr("typeface", "Sans-Serif"),
                    customDateFontPath = customDateFont,
                    dateFontSize = dateObj.floatOr("scale", 0.04f),
                    dateHorizontalPos = dateObj.floatOr("x", 0.50f),
                    dateVerticalPos = dateObj.floatOr("y", 0.14f),
                    dateColor = dateObj.optInt("argb", -1),
                    dateFormat = dateObj.strOr("format", "EEE, MMM dd"),
                    dateAllCaps = dateObj.optBoolean("uppercase", false),
                    dateBold = dateObj.optBoolean("bold", false),
                    dateDepthMode = dateObj.strOr("material", "Standard"),
                    dateBlurAmount = dateObj.floatOr("blur", 18.0f),
                    dateOpacity = dateObj.floatOr("opacity", 1.0f),
                    dateShadowEnabled = dateObj.optBoolean("shadow", true),
                    dateRimBrightness = dateObj.floatOr("rimBrightness", 0.65f),
                    backgroundDim = sceneObj.floatOr("backgroundDim", 0.0f),
                    homescreenClock = homescreenClock,
                    use24Hour = use24Hour
                )
            } catch (e: Exception) {
                AppLogger.e(TAG, "Error parsing sceneJson", e)
                SceneEngineConfig(
                    backgroundPath = bgPath,
                    foregroundPath = fgPath,
                    customFontPath = customClockFont,
                    customDateFontPath = customDateFont,
                    homescreenClock = homescreenClock,
                    use24Hour = use24Hour
                )
            }
        }
    }
}