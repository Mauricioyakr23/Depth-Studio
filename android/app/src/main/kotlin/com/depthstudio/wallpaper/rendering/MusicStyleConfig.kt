package com.depthstudio.wallpaper.rendering

import android.content.Context
import android.content.SharedPreferences
import android.graphics.Typeface
import com.depthstudio.wallpaper.AppLogger
import com.depthstudio.wallpaper.MainActivity
import org.json.JSONObject

data class MusicStyleConfig(
    val coverX: Float = 0.50f,
    val coverY: Float = 0.20f,
    val coverScale: Float = 1.0f,
    val cardX: Float = 0.50f,
    val cardY: Float = 0.65f,
    val cardScale: Float = 1.0f,
    val clockX: Float = 0.50f,
    val clockY: Float = 0.14f,
    val clockScale: Float = 1.0f,
    val clockMaterial: String = "Standard",
    val clockBlur: Float = 18.0f,
    val clockBrightness: Float = 0.65f,
    val clockOpacity: Float = 1.0f,
    val clockShadowEnabled: Boolean = true,
    val clockEdgeStrokeEnabled: Boolean = false,
    val clockRimWidth: Float = 1.8f,
    val clockRimBlur: Float = 0.0f,
    val cardMaterial: String = "Liquid",
    val cardBlur: Float = 18.0f,
    val cardBrightness: Float = 0.65f,
    val cardOpacity: Float = 1.0f,
    val cardShadowEnabled: Boolean = true,
    val cardEdgeStrokeEnabled: Boolean = false,
    val cardRimWidth: Float = 1.8f,
    val cardRimBlur: Float = 0.0f,
    val clockTypeface: Typeface = Typeface.DEFAULT,
    val dateTypeface: Typeface = Typeface.DEFAULT,
    val cardTypeface: Typeface = Typeface.DEFAULT
) {
    companion object {
        private const val TAG = "MusicStyleConfig"

        fun fromPreferences(
            context: Context,
            clockAndDateRenderer: ClockAndDateRenderer
        ): MusicStyleConfig {
            val prefs = context.getSharedPreferences(MainActivity.PREFS_NAME, Context.MODE_PRIVATE)
            val rawJson = prefs.getString("musicOverlayJson", null)
            if (!rawJson.isNullOrEmpty()) {
                try {
                    return fromJson(JSONObject(rawJson), clockAndDateRenderer)
                } catch (e: Exception) {
                    AppLogger.e(TAG, "Error parsing musicOverlayJson, falling back to legacy prefs", e)
                }
            }
            return fromLegacyPreferences(prefs, clockAndDateRenderer)
        }

        fun fromJson(
            json: JSONObject,
            clockAndDateRenderer: ClockAndDateRenderer
        ): MusicStyleConfig {
            fun optFloat(key: String, default: Float): Float =
                if (json.has(key) && !json.isNull(key)) json.optDouble(key, default.toDouble()).toFloat() else default

            fun optStr(key: String, default: String): String =
                if (json.has(key) && !json.isNull(key)) json.optString(key, default) else default

            fun optNullableStr(key: String): String? =
                if (json.has(key) && !json.isNull(key)) json.optString(key).takeIf { it.isNotEmpty() } else null

            val clockFont = optStr("musicClockFont", "Sans-Serif")
            val clockFontPath = optNullableStr("musicClockFontPath")
            val dateFont = optStr("musicDateFont", "Sans-Serif")
            val dateFontPath = optNullableStr("musicDateFontPath")
            val cardFont = optStr("musicCardFont", "Sans-Serif")
            val cardFontPath = optNullableStr("musicCardFontPath")

            return MusicStyleConfig(
                coverX = optFloat("musicCoverX", 0.50f),
                coverY = optFloat("musicCoverY", 0.20f),
                coverScale = optFloat("musicCoverScale", 1.0f),
                cardX = optFloat("musicCardX", 0.50f),
                cardY = optFloat("musicCardY", 0.65f),
                cardScale = optFloat("musicCardScale", 1.0f),
                clockX = optFloat("musicClockX", 0.50f),
                clockY = optFloat("musicClockY", 0.14f),
                clockScale = optFloat("musicClockScale", 1.0f),
                clockMaterial = optStr("musicClockMaterial", "Standard"),
                clockBlur = optFloat("musicClockBlur", 18.0f),
                clockBrightness = optFloat("musicClockBrightness", 0.65f),
                clockOpacity = optFloat("musicClockOpacity", 1.0f),
                clockShadowEnabled = json.optBoolean("musicClockShadowEnabled", true),
                clockEdgeStrokeEnabled = json.optBoolean("musicClockEdgeStrokeEnabled", false),
                clockRimWidth = optFloat("musicClockRimWidth", 1.8f),
                clockRimBlur = optFloat("musicClockRimBlur", 0.0f),
                cardMaterial = optStr("musicCardMaterial", "Liquid"),
                cardBlur = optFloat("musicCardBlur", 18.0f),
                cardBrightness = optFloat("musicCardBrightness", 0.65f),
                cardOpacity = optFloat("musicCardOpacity", 1.0f),
                cardShadowEnabled = json.optBoolean("musicCardShadowEnabled", true),
                cardEdgeStrokeEnabled = json.optBoolean("musicCardEdgeStrokeEnabled", false),
                cardRimWidth = optFloat("musicCardRimWidth", 1.8f),
                cardRimBlur = optFloat("musicCardRimBlur", 0.0f),
                clockTypeface = clockAndDateRenderer.getTypefaceForFont(clockFont, clockFontPath),
                dateTypeface = clockAndDateRenderer.getTypefaceForFont(dateFont, dateFontPath),
                cardTypeface = clockAndDateRenderer.getTypefaceForFont(cardFont, cardFontPath)
            )
        }

        private fun fromLegacyPreferences(
            prefs: SharedPreferences,
            clockAndDateRenderer: ClockAndDateRenderer
        ): MusicStyleConfig {
            val clockFont = prefs.getString("musicClockFont", "Sans-Serif") ?: "Sans-Serif"
            val clockFontPath = prefs.getString("musicClockFontPath", null)
            val dateFont = prefs.getString("musicDateFont", "Sans-Serif") ?: "Sans-Serif"
            val dateFontPath = prefs.getString("musicDateFontPath", null)
            val cardFont = prefs.getString("musicCardFont", "Sans-Serif") ?: "Sans-Serif"
            val cardFontPath = prefs.getString("musicCardFontPath", null)

            return MusicStyleConfig(
                coverX = prefs.getFloat("musicCoverX", 0.50f),
                coverY = prefs.getFloat("musicCoverY", 0.20f),
                coverScale = prefs.getFloat("musicCoverScale", 1.0f),
                cardX = prefs.getFloat("musicCardX", 0.50f),
                cardY = prefs.getFloat("musicCardY", 0.65f),
                cardScale = prefs.getFloat("musicCardScale", 1.0f),
                clockX = prefs.getFloat("musicClockX", 0.50f),
                clockY = prefs.getFloat("musicClockY", 0.14f),
                clockScale = prefs.getFloat("musicClockScale", 1.0f),
                clockMaterial = prefs.getString("musicClockMaterial", "Standard") ?: "Standard",
                clockBlur = prefs.getFloat("musicClockBlur", 18.0f),
                clockBrightness = prefs.getFloat("musicClockBrightness", 0.65f),
                clockOpacity = prefs.getFloat("musicClockOpacity", 1.0f),
                clockShadowEnabled = prefs.getBoolean("musicClockShadowEnabled", true),
                clockEdgeStrokeEnabled = prefs.getBoolean("musicClockEdgeStrokeEnabled", false),
                clockRimWidth = prefs.getFloat("musicClockRimWidth", 1.8f),
                clockRimBlur = prefs.getFloat("musicClockRimBlur", 0.0f),
                cardMaterial = prefs.getString("musicCardMaterial", "Liquid") ?: "Liquid",
                cardBlur = prefs.getFloat("musicCardBlur", 18.0f),
                cardBrightness = prefs.getFloat("musicCardBrightness", 0.65f),
                cardOpacity = prefs.getFloat("musicCardOpacity", 1.0f),
                cardShadowEnabled = prefs.getBoolean("musicCardShadowEnabled", true),
                cardEdgeStrokeEnabled = prefs.getBoolean("musicCardEdgeStrokeEnabled", false),
                cardRimWidth = prefs.getFloat("musicCardRimWidth", 1.8f),
                cardRimBlur = prefs.getFloat("musicCardRimBlur", 0.0f),
                clockTypeface = clockAndDateRenderer.getTypefaceForFont(clockFont, clockFontPath),
                dateTypeface = clockAndDateRenderer.getTypefaceForFont(dateFont, dateFontPath),
                cardTypeface = clockAndDateRenderer.getTypefaceForFont(cardFont, cardFontPath)
            )
        }
    }
}