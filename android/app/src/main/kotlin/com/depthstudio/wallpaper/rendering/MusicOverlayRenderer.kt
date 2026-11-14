package com.depthstudio.wallpaper.rendering

import android.content.Context
import android.graphics.Bitmap
import android.graphics.BitmapShader
import android.graphics.BlurMaskFilter
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.ColorMatrix
import android.graphics.ColorMatrixColorFilter
import android.graphics.LinearGradient
import android.graphics.Matrix
import android.graphics.Paint
import android.graphics.Path
import android.graphics.RectF
import android.graphics.Shader
import android.text.TextPaint
import android.text.TextUtils
import android.util.Log
import com.depthstudio.wallpaper.MainActivity
import com.depthstudio.wallpaper.MusicStateHolder
import java.util.Locale
import kotlin.math.abs
import kotlin.math.max
import kotlin.math.sin

class MusicOverlayRenderer(
    private val context: Context,
    private val shaders: WallpaperShaders
) {
    companion object {
        private const val TAG = "MusicOverlayRenderer"
    }

    private val backdrop = MusicBackdropRenderer()
    private val headerRenderer = MusicHeaderRenderer(shaders)
    private var style = MusicStyleConfig()

    private var coverBitmap: Bitmap? = null
    private var coverShader: BitmapShader? = null
    private var lastProcessedTrackId: String = ""

    private var dynamicHourColor: Int = Color.WHITE
    private var dynamicMinColor: Int = Color.parseColor("#64D2FF")
    private var dynamicVibrantColor: Int = Color.parseColor("#FF9F0A")
    private var dynamicFourthColor: Int = Color.parseColor("#BF5AF2")
    private var dynamicDarkColor: Int = Color.parseColor("#141418")

    private val coverShaderMatrix = Matrix()
    private val cardGlassMatrix = Matrix()
    private val darkOverlayPaint = Paint(Paint.ANTI_ALIAS_FLAG)
    private val cardShadowPaint = Paint(Paint.ANTI_ALIAS_FLAG)
    private val coverPaint = Paint(Paint.ANTI_ALIAS_FLAG or Paint.FILTER_BITMAP_FLAG or Paint.DITHER_FLAG).apply {
        isFilterBitmap = true
        isDither = true
    }
    private val borderPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply { style = Paint.Style.STROKE }
    private val uiFillPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply { style = Paint.Style.FILL }
    private val uiStrokePaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
        style = Paint.Style.STROKE
        strokeCap = Paint.Cap.ROUND
        strokeJoin = Paint.Join.ROUND
    }
    private val titleTextPaint = TextPaint(Paint.ANTI_ALIAS_FLAG).apply {
        color = Color.WHITE
        textAlign = Paint.Align.CENTER
    }
    private val subTextPaint = TextPaint(Paint.ANTI_ALIAS_FLAG).apply {
        color = Color.argb(175, 255, 255, 255)
        textAlign = Paint.Align.CENTER
    }
    private val timeSmallPaint = TextPaint(Paint.ANTI_ALIAS_FLAG).apply {
        fontFeatureSettings = "tnum"
        color = Color.argb(155, 255, 255, 255)
    }
    private val progressClipPath = Path()
    private val cardClipPath = Path()

    fun reloadLayoutAndStyle(clockAndDateRenderer: ClockAndDateRenderer) {
        style = MusicStyleConfig.fromPreferences(context, clockAndDateRenderer)
        titleTextPaint.typeface = style.cardTypeface
        subTextPaint.typeface = style.cardTypeface
        timeSmallPaint.typeface = style.cardTypeface
    }

    fun syncWithMusicState(canvasWidth: Int, canvasHeight: Int) {
        val small = MusicStateHolder.albumArt
        if (small != null && !small.isRecycled) {
            dynamicHourColor = MusicStateHolder.primaryColor
            dynamicMinColor = MusicStateHolder.secondaryColor
            dynamicVibrantColor = MusicStateHolder.vibrantColor
            dynamicFourthColor = MusicStateHolder.accentFourthColor
            dynamicDarkColor = MusicStateHolder.darkColor

            if (MusicStateHolder.trackId != lastProcessedTrackId || !backdrop.hasReadyBackground) {
                val hiRes = MusicStateHolder.highResArt?.takeIf { !it.isRecycled } ?: small
                prepareAlbumArtAssets(
                    small,
                    hiRes,
                    canvasWidth,
                    canvasHeight
                )
                lastProcessedTrackId = MusicStateHolder.trackId
            }
        }
    }

    fun prepareAlbumArtAssets(smallArt: Bitmap, hiResArt: Bitmap, canvasWidth: Int, canvasHeight: Int) {
        try {
            backdrop.prepareAssets(
                smallArt,
                canvasWidth,
                canvasHeight,
                intArrayOf(dynamicHourColor, dynamicMinColor, dynamicVibrantColor, dynamicFourthColor)
            )
            val coverCopy = hiResArt.copy(Bitmap.Config.ARGB_8888, false).apply {
                setHasMipMap(true)
            }
            coverBitmap?.recycle()
            coverBitmap = coverCopy
            coverShader = GlassBitmapProcessor.createLinearBitmapShader(coverCopy, Shader.TileMode.CLAMP)
        } catch (e: Exception) {
            Log.e(TAG, "Error preparing album assets", e)
        }
    }

    fun drawMusicExperience(
        canvas: Canvas,
        canvasWidth: Int,
        canvasHeight: Int,
        mTrans: Float,
        elapsedSec: Float,
        clockText: String,
        dateText: String
    ) {
        if (mTrans <= 0.01f) return
        backdrop.updateAndDraw(canvas, canvasWidth, canvasHeight, mTrans, elapsedSec, dynamicDarkColor)

        darkOverlayPaint.color = Color.argb((70 * mTrans).toInt(), 0, 0, 0)
        canvas.drawRect(0f, 0f, canvasWidth.toFloat(), canvasHeight.toFloat(), darkOverlayPaint)

        drawPlayerOverlay(canvas, canvasWidth, canvasHeight, mTrans, elapsedSec, clockText, dateText)
    }

    private fun drawPlayerOverlay(
        canvas: Canvas,
        canvasWidth: Int,
        canvasHeight: Int,
        mTrans: Float,
        elapsedSec: Float,
        clockText: String,
        dateText: String
    ) {
        val coverBmp = coverBitmap ?: return
        val cShader = coverShader ?: return

        val w = canvasWidth.toFloat()
        val h = canvasHeight.toFloat()
        val density = context.resources.displayMetrics.density
        val alphaInt = (mTrans.coerceIn(0f, 1f) * 255).toInt()
        val entryScale = 0.92f + 0.08f * mTrans
        val slideOffsetY = (1f - mTrans) * (28f * density)

        val layerSave = if (alphaInt < 254) {
            canvas.saveLayerAlpha(0f, 0f, w, h, alphaInt)
        } else {
            canvas.save()
        }

        headerRenderer.draw(
            canvas, canvasWidth, canvasHeight, density,
            slideOffsetY, clockText, dateText, dynamicHourColor, style, backdrop
        )

        val baseCoverSize = (w * 0.85f).coerceAtMost(h * 0.42f)
        val coverSize = (baseCoverSize * style.coverScale).coerceIn(w * 0.30f, w * 0.94f)
        val coverCenterX = (w / 2f) + (style.coverX - 0.50f) * w * 1.4f
        val coverLeft = (coverCenterX - coverSize / 2f).coerceIn(12f * density, w - coverSize - 12f * density)
        val coverTop = (h * style.coverY) + slideOffsetY
        val coverRect = RectF(coverLeft, coverTop, coverLeft + coverSize, coverTop + coverSize)
        val coverCorner = 20f * density * style.coverScale.coerceIn(0.75f, 1.25f)

        canvas.save()
        canvas.scale(entryScale, entryScale, coverRect.centerX(), coverRect.centerY())
        cardShadowPaint.color = Color.BLACK
        cardShadowPaint.setShadowLayer(26f * density, 0f, 12f * density, Color.argb(165, 0, 0, 0))
        canvas.drawRoundRect(coverRect, coverCorner, coverCorner, cardShadowPaint)
        cardShadowPaint.clearShadowLayer()

        val bmpW = max(coverBmp.width.toFloat(), 1f)
        val bmpH = max(coverBmp.height.toFloat(), 1f)
        val uniformScale = max(coverSize / bmpW, coverSize / bmpH)
        val offsetX = coverLeft + (coverSize - bmpW * uniformScale) * 0.5f
        val offsetY = coverTop + (coverSize - bmpH * uniformScale) * 0.5f

        coverShaderMatrix.reset()
        coverShaderMatrix.postScale(uniformScale, uniformScale)
        coverShaderMatrix.postTranslate(offsetX, offsetY)
        cShader.setLocalMatrix(coverShaderMatrix)
        coverPaint.shader = cShader
        canvas.drawRoundRect(coverRect, coverCorner, coverCorner, coverPaint)

        borderPaint.strokeWidth = 0.85f * density
        borderPaint.shader = null
        borderPaint.color = Color.argb(45, 255, 255, 255)
        canvas.drawRoundRect(coverRect, coverCorner, coverCorner, borderPaint)
        canvas.restore()

        val cardW = (w * 0.85f * style.cardScale).coerceIn(w * 0.58f, w * 0.94f)
        val cardH = ((h * 0.10f).coerceIn(90f * density, 110f * density)) * style.cardScale.coerceIn(0.85f, 1.25f)
        val cardCenterX = (w / 2f) + (style.cardX - 0.50f) * w * 1.4f
        val cardLeft = (cardCenterX - cardW / 2f).coerceIn(12f * density, w - cardW - 12f * density)
        val cardTop = (h * style.cardY) + slideOffsetY
        val cardRect = RectF(cardLeft, cardTop, cardLeft + cardW, cardTop + cardH)
        val cardCorner = 26f * density * style.cardScale.coerceIn(0.80f, 1.20f)

        canvas.save()
        canvas.scale(entryScale, entryScale, cardRect.centerX(), cardRect.centerY())

        if (style.cardShadowEnabled) {
            cardShadowPaint.color = Color.TRANSPARENT
            cardShadowPaint.setShadowLayer(20f * density, 0f, 8f * density, Color.argb(95, 0, 0, 0))
            canvas.drawRoundRect(cardRect, cardCorner, cardCorner, cardShadowPaint)
            cardShadowPaint.clearShadowLayer()
        }

        renderPlayerCardMaterial(canvas, canvasWidth, canvasHeight, cardRect, cardCorner, density)
        drawTrackMetadataAndProgress(canvas, cardRect, cardH, density, elapsedSec)

        canvas.restore()
        canvas.restoreToCount(layerSave)
    }

    private fun renderPlayerCardMaterial(
        canvas: Canvas,
        canvasWidth: Int,
        canvasHeight: Int,
        cardRect: RectF,
        cardCorner: Float,
        density: Float
    ) {
        val alphaInt = (style.cardOpacity.coerceIn(0.15f, 1.0f) * 255).toInt()
        val mode = when (style.cardMaterial) {
            "Liquid", "Acrylic", "Aero" -> style.cardMaterial
            else -> "Standard"
        }
        val glassBr = style.cardBrightness.coerceIn(0f, 1f)
        val isLiquid = mode == "Liquid"

        cardClipPath.reset()
        cardClipPath.addRoundRect(cardRect, cardCorner, cardCorner, Path.Direction.CW)
        canvas.save()
        canvas.clipPath(cardClipPath)

        if (mode == "Standard") {
            uiFillPaint.shader = null
            uiFillPaint.colorFilter = null
            uiFillPaint.color = Color.argb((alphaInt * 0.78f).toInt(), 24, 24, 28)
            canvas.drawRoundRect(cardRect, cardCorner, cardCorner, uiFillPaint)
        } else {
            val cardShader = if (isLiquid) shaders.getPlayerCardShader() else null
            val effectiveBlur = if (isLiquid) {
                (style.cardBlur * 0.25f).coerceIn(1f, 8f)
            } else {
                style.cardBlur
            }
            val blurSample = backdrop.getBlurSample(effectiveBlur)
            val sampleBmp = blurSample?.bitmap ?: backdrop.liveBufferBitmap
            val sampleShader = blurSample?.shader ?: backdrop.liveBufferShader

            if (isLiquid && cardShader != null && sampleBmp != null && sampleShader != null) {
                cardGlassMatrix.reset()
                sampleShader.setLocalMatrix(cardGlassMatrix)
                cardShader.setInputShader("uLiveBg", sampleShader)
                cardShader.setFloatUniform(
                    "uBgScale",
                    sampleBmp.width.toFloat() / max(canvasWidth.toFloat(), 1f),
                    sampleBmp.height.toFloat() / max(canvasHeight.toFloat(), 1f)
                )
                cardShader.setFloatUniform("uCardCenter", cardRect.centerX(), cardRect.centerY())
                cardShader.setFloatUniform("uCardHalfSize", cardRect.width() / 2f, cardRect.height() / 2f)
                cardShader.setFloatUniform("uCornerRadius", cardCorner)
                cardShader.setFloatUniform("uBrightness", glassBr)

                uiFillPaint.shader = cardShader
                uiFillPaint.colorFilter = null
                uiFillPaint.alpha = alphaInt
                canvas.drawRoundRect(cardRect, cardCorner, cardCorner, uiFillPaint)
                uiFillPaint.shader = null
            } else if (sampleBmp != null && sampleShader != null) {
                val tintColor = GlassBitmapProcessor.blendTowardsWhite(dynamicHourColor, 0.70f)
                val opticalMatrix = GlassBitmapProcessor.buildOpticalGlassMatrix(tintColor, glassBr, mode)

                cardGlassMatrix.reset()
                cardGlassMatrix.postScale(
                    canvasWidth.toFloat() / max(sampleBmp.width.toFloat(), 1f),
                    canvasHeight.toFloat() / max(sampleBmp.height.toFloat(), 1f)
                )
                sampleShader.setLocalMatrix(cardGlassMatrix)

                uiFillPaint.shader = sampleShader
                uiFillPaint.colorFilter = ColorMatrixColorFilter(ColorMatrix(opticalMatrix))
                uiFillPaint.alpha = alphaInt
                canvas.drawRoundRect(cardRect, cardCorner, cardCorner, uiFillPaint)
                uiFillPaint.shader = null
                uiFillPaint.colorFilter = null

                val veilAlpha = if (mode == "Acrylic") 0.26f else if (mode == "Aero") 0.22f else 0.14f
                uiFillPaint.color = Color.argb(
                    (veilAlpha * alphaInt).toInt(),
                    Color.red(tintColor),
                    Color.green(tintColor),
                    Color.blue(tintColor)
                )
                canvas.drawRoundRect(cardRect, cardCorner, cardCorner, uiFillPaint)
            }
        }
        canvas.restore()

        borderPaint.maskFilter = null
        if (style.cardEdgeStrokeEnabled) {
            val strokeW = (style.cardRimWidth * density).coerceIn(0.6f * density, 8.0f * density)
            val rimAlpha = (145 + (90 * glassBr).toInt()).coerceIn(110, 245)
            borderPaint.shader = null
            borderPaint.color = Color.argb(rimAlpha, 255, 255, 255)

            if (isLiquid || style.cardRimBlur > 0.1f) {
                val blurRad = if (style.cardRimBlur > 0.1f) style.cardRimBlur * density else 2.2f * density
                borderPaint.strokeWidth = strokeW * 1.6f
                borderPaint.maskFilter = BlurMaskFilter(blurRad, BlurMaskFilter.Blur.NORMAL)
                canvas.drawRoundRect(cardRect, cardCorner, cardCorner, borderPaint)
            }

            borderPaint.strokeWidth = strokeW
            borderPaint.maskFilter = null
            canvas.drawRoundRect(cardRect, cardCorner, cardCorner, borderPaint)
        } else {
            borderPaint.strokeWidth = 0.95f * density
            borderPaint.shader = LinearGradient(
                cardRect.left, cardRect.top, cardRect.right, cardRect.bottom,
                intArrayOf(
                    Color.argb(95, 255, 255, 255),
                    Color.argb(30, 255, 255, 255),
                    Color.argb(26, 255, 255, 255),
                    Color.argb(72, 255, 255, 255)
                ),
                floatArrayOf(0f, 0.35f, 0.70f, 1f),
                Shader.TileMode.CLAMP
            )
            canvas.drawRoundRect(cardRect, cardCorner, cardCorner, borderPaint)
            borderPaint.shader = null
        }
    }

    private fun isSpanishLanguage(): Boolean {
        val prefs = context.getSharedPreferences(MainActivity.PREFS_NAME, Context.MODE_PRIVATE)
        val lang = prefs.getString("appLanguage", null) ?: Locale.getDefault().language
        return lang.startsWith("es", ignoreCase = true)
    }

    private fun drawTrackMetadataAndProgress(
        canvas: Canvas,
        cardRect: RectF,
        cardH: Float,
        density: Float,
        elapsedSec: Float
    ) {
        val textScale = style.cardScale.coerceIn(0.85f, 1.25f)
        val padX = 22f * density * textScale
        val titleY = cardRect.top + cardH * 0.35f
        val artistY = titleY + 17.5f * density * textScale

        titleTextPaint.textSize = 15.2f * density * textScale
        subTextPaint.textSize = 13.0f * density * textScale

        val isEs = isSpanishLanguage()
        val maxTitleW = cardRect.width() - (padX * 4.4f)
        val rawTitle = MusicStateHolder.title.ifEmpty { if (isEs) "M\u00fasica" else "Music" }
        val rawArtist = MusicStateHolder.artist.ifEmpty { if (isEs) "En reproducci\u00f3n" else "Now Playing" }

        canvas.drawText(
            TextUtils.ellipsize(rawTitle, titleTextPaint, maxTitleW, TextUtils.TruncateAt.END).toString(),
            cardRect.centerX(), titleY, titleTextPaint
        )
        canvas.drawText(
            TextUtils.ellipsize(rawArtist, subTextPaint, maxTitleW, TextUtils.TruncateAt.END).toString(),
            cardRect.centerX(), artistY, subTextPaint
        )

        val eqRightX = cardRect.right - padX - 2f * density
        val eqCenterY = (titleY + artistY) / 2f - 4.5f * density
        val barSpacing = 3.4f * density * textScale
        uiStrokePaint.strokeWidth = 1.8f * density * textScale
        uiStrokePaint.color = Color.argb(145, 255, 255, 255)

        for (b in 0 until 5) {
            val bx = eqRightX - (4 - b) * barSpacing
            val wave = if (MusicStateHolder.isPlaying) {
                0.25f + 0.75f * abs(sin(elapsedSec * (3.4f + b * 0.55f) + b * 1.2f))
            } else {
                0.20f
            }
            val halfBarH = (1.5f + wave * 5.8f) * density * textScale
            canvas.drawLine(bx, eqCenterY - halfBarH, bx, eqCenterY + halfBarH, uiStrokePaint)
        }

        val progY = cardRect.top + cardH * 0.75f
        val durMs = MusicStateHolder.durationMs
        val posMs = MusicStateHolder.getCurrentPositionMs()
        val remMs = (durMs - posMs).coerceAtLeast(0L)
        val progressFrac = if (durMs > 0L) (posMs.toFloat() / durMs.toFloat()).coerceIn(0f, 1f) else 0.0f

        timeSmallPaint.textSize = 10.5f * density * textScale
        timeSmallPaint.textAlign = Paint.Align.LEFT
        canvas.drawText(formatDurationMmSs(posMs, false), cardRect.left + padX, progY + 3.6f * density, timeSmallPaint)

        timeSmallPaint.textAlign = Paint.Align.RIGHT
        canvas.drawText(formatDurationMmSs(remMs, true), cardRect.right - padX, progY + 3.6f * density, timeSmallPaint)

        val barLeft = cardRect.left + padX + timeSmallPaint.measureText("00:00") + 8f * density
        val barRight = cardRect.right - padX - timeSmallPaint.measureText("-00:00") - 8f * density
        val barRadius = (4.6f * density) / 2f
        val barRect = RectF(barLeft, progY - barRadius, barRight, progY + barRadius)

        uiFillPaint.shader = null
        uiFillPaint.color = Color.argb(64, 255, 255, 255)
        canvas.drawRoundRect(barRect, barRadius, barRadius, uiFillPaint)

        if (progressFrac > 0.005f) {
            progressClipPath.reset()
            progressClipPath.addRoundRect(barRect, barRadius, barRadius, Path.Direction.CW)
            canvas.save()
            canvas.clipPath(progressClipPath)
            val fillRight = barLeft + (barRect.width() * progressFrac).coerceAtLeast(2f * density)
            uiFillPaint.color = Color.argb(235, 255, 255, 255)
            canvas.drawRect(barLeft, barRect.top, fillRight.coerceAtMost(barRight), barRect.bottom, uiFillPaint)
            canvas.restore()
        }
    }

    private fun formatDurationMmSs(ms: Long, prefixMinus: Boolean): String {
        val totalSec = (ms.coerceAtLeast(0L) / 1000L).toInt()
        val base = String.format(Locale.US, "%d:%02d", totalSec / 60, totalSec % 60)
        return if (prefixMinus) "-$base" else base
    }

    fun release() {
        backdrop.release()
        headerRenderer.release()
        coverBitmap?.recycle(); coverBitmap = null
        coverShader = null
        lastProcessedTrackId = ""
    }
}