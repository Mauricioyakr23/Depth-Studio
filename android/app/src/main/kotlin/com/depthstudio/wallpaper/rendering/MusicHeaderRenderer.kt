package com.depthstudio.wallpaper.rendering

import android.graphics.Bitmap
import android.graphics.BitmapShader
import android.graphics.BlurMaskFilter
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.ColorMatrix
import android.graphics.ColorMatrixColorFilter
import android.graphics.Matrix
import android.graphics.Paint
import android.graphics.PorterDuff
import android.graphics.PorterDuffXfermode
import android.graphics.RectF
import android.graphics.Shader
import kotlin.math.max

class MusicHeaderRenderer(
    private val shaders: WallpaperShaders
) {
    private var maskBitmap: Bitmap? = null
    private var maskCanvas: Canvas? = null
    private var maskShader: BitmapShader? = null

    private val glassMatrix = Matrix()
    private val bounds = RectF()

    private val clockPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
        textAlign = Paint.Align.LEFT
        letterSpacing = -0.02f
    }
    private val datePaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
        textAlign = Paint.Align.LEFT
        letterSpacing = -0.01f
    }
    private val punchPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
        style = Paint.Style.FILL
        color = Color.BLACK
        xfermode = PorterDuffXfermode(PorterDuff.Mode.DST_OUT)
    }
    private val rimPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
        style = Paint.Style.STROKE
        strokeJoin = Paint.Join.ROUND
        strokeCap = Paint.Cap.ROUND
        xfermode = PorterDuffXfermode(PorterDuff.Mode.SRC_ATOP)
    }
    private val shaderPaint = Paint(Paint.ANTI_ALIAS_FLAG)

    fun draw(
        canvas: Canvas,
        canvasWidth: Int,
        canvasHeight: Int,
        density: Float,
        slideOffsetY: Float,
        clockText: String,
        dateText: String,
        tintBaseColor: Int,
        style: MusicStyleConfig,
        backdrop: MusicBackdropRenderer
    ) {
        val opAlpha = (style.clockOpacity.coerceIn(0.15f, 1.0f) * 255).toInt()
        if (opAlpha <= 2) return

        val w = canvasWidth.toFloat()
        val h = canvasHeight.toFloat()
        val mode = when (style.clockMaterial) {
            "Liquid", "Acrylic", "Aero" -> style.clockMaterial
            else -> "Standard"
        }
        val isGlass = mode != "Standard"
        val isLiquid = mode == "Liquid"
        val glassBr = style.clockBrightness.coerceIn(0f, 1f)

        clockPaint.typeface = style.clockTypeface
        datePaint.typeface = style.dateTypeface
        clockPaint.textSize = w * 0.068f * style.clockScale
        datePaint.textSize = w * 0.052f * style.clockScale
        clockPaint.clearShadowLayer()
        datePaint.clearShadowLayer()

        val clockW = clockPaint.measureText(clockText)
        val dateW = datePaint.measureText(dateText)
        val headerGap = 13f * density * style.clockScale
        val totalHeaderW = clockW + headerGap + dateW
        val clockCenterX = (w / 2f) + (style.clockX - 0.50f) * w * 1.4f
        val startX = (clockCenterX - totalHeaderW / 2f).coerceIn(
            12f * density,
            max(12f * density, w - totalHeaderW - 12f * density)
        )
        val baselineY = (h * style.clockY) + (clockPaint.textSize * 0.85f) + slideOffsetY
        val dateX = startX + clockW + headerGap
        val dateY = baselineY - (1.5f * density)

        val pad = 18f * density
        bounds.set(
            (startX - pad).coerceAtLeast(0f),
            (baselineY - clockPaint.textSize - pad).coerceAtLeast(0f),
            (startX + totalHeaderW + pad).coerceAtMost(w),
            (baselineY + pad).coerceAtMost(h)
        )

        val headerTint = GlassBitmapProcessor.blendTowardsWhite(tintBaseColor, 0.82f)

        if (style.clockShadowEnabled) {
            val shadowSave = canvas.saveLayerAlpha(bounds, 255)
            val shadowRad = (if (isLiquid) 8f else if (isGlass) 6f else 5f) * density
            clockPaint.color = Color.BLACK
            datePaint.color = Color.BLACK
            clockPaint.setShadowLayer(shadowRad, 0f, 1.5f * density, Color.argb(95, 0, 0, 0))
            datePaint.setShadowLayer(shadowRad, 0f, 1.5f * density, Color.argb(95, 0, 0, 0))
            canvas.drawText(clockText, startX, baselineY, clockPaint)
            canvas.drawText(dateText, dateX, dateY, datePaint)
            clockPaint.clearShadowLayer()
            datePaint.clearShadowLayer()

            drawPunch(canvas, clockPaint, clockText, startX, baselineY)
            drawPunch(canvas, datePaint, dateText, dateX, dateY)
            canvas.restoreToCount(shadowSave)
        }

        val textLayer = canvas.saveLayerAlpha(bounds, opAlpha)

        if (!isGlass) {
            clockPaint.color = headerTint
            datePaint.color = Color.argb(
                220,
                Color.red(headerTint),
                Color.green(headerTint),
                Color.blue(headerTint)
            )
            canvas.drawText(clockText, startX, baselineY, clockPaint)
            canvas.drawText(dateText, dateX, dateY, datePaint)
        } else {
            val clearShader = if (isLiquid) shaders.getClockClearShader() else null
            val effectiveBlur = if (isLiquid) {
                (style.clockBlur * 0.25f).coerceIn(1f, 8f)
            } else {
                style.clockBlur
            }
            val blurSample = backdrop.getBlurSample(effectiveBlur)
            val sampleBmp = blurSample?.bitmap ?: backdrop.liveBufferBitmap
            val sampleShader = blurSample?.shader ?: backdrop.liveBufferShader

            if (isLiquid && clearShader != null && sampleBmp != null && sampleShader != null) {
                val fixedW = canvasWidth.coerceAtLeast(16)
                val fixedH = max((canvasHeight * 0.25f).toInt(), bounds.height().toInt() + 16).coerceAtLeast(64)
                if (maskBitmap == null || maskBitmap?.width != fixedW || maskBitmap?.height != fixedH) {
                    maskBitmap?.recycle()
                    val mBmp = Bitmap.createBitmap(fixedW, fixedH, Bitmap.Config.ARGB_8888)
                    maskBitmap = mBmp
                    maskCanvas = Canvas(mBmp)
                    maskShader = GlassBitmapProcessor.createLinearBitmapShader(mBmp, Shader.TileMode.CLAMP)
                }

                val mCanvas = maskCanvas!!
                mCanvas.drawColor(Color.TRANSPARENT, PorterDuff.Mode.CLEAR)
                mCanvas.save()
                mCanvas.translate(-bounds.left, -bounds.top)
                clockPaint.color = Color.WHITE
                datePaint.color = Color.WHITE
                mCanvas.drawText(clockText, startX, baselineY, clockPaint)
                mCanvas.drawText(dateText, dateX, dateY, datePaint)
                mCanvas.restore()

                glassMatrix.reset()
                glassMatrix.postScale(w / max(sampleBmp.width.toFloat(), 1f), h / max(sampleBmp.height.toFloat(), 1f))
                sampleShader.setLocalMatrix(glassMatrix)

                clearShader.setInputShader("uBg", sampleShader)
                clearShader.setInputShader("uGlyphMask", maskShader!!)
                clearShader.setFloatUniform("uMaskOffset", bounds.left, bounds.top)
                clearShader.setFloatUniform(
                    "uTint",
                    Color.red(headerTint) / 255f,
                    Color.green(headerTint) / 255f,
                    Color.blue(headerTint) / 255f
                )
                clearShader.setFloatUniform("uTintStrength", 0.14f)
                clearShader.setFloatUniform("uBrightness", glassBr)

                shaderPaint.shader = clearShader
                shaderPaint.colorFilter = null
                shaderPaint.xfermode = null
                canvas.drawRect(bounds, shaderPaint)
                shaderPaint.shader = null
            } else if (sampleBmp != null && sampleShader != null) {
                clockPaint.color = Color.WHITE
                datePaint.color = Color.WHITE
                canvas.drawText(clockText, startX, baselineY, clockPaint)
                canvas.drawText(dateText, dateX, dateY, datePaint)

                val opticalMatrix = GlassBitmapProcessor.buildOpticalGlassMatrix(headerTint, glassBr, mode)
                glassMatrix.reset()
                glassMatrix.postScale(
                    w / max(sampleBmp.width.toFloat(), 1f),
                    h / max(sampleBmp.height.toFloat(), 1f)
                )
                sampleShader.setLocalMatrix(glassMatrix)

                shaderPaint.shader = sampleShader
                shaderPaint.colorFilter = ColorMatrixColorFilter(ColorMatrix(opticalMatrix))
                shaderPaint.xfermode = PorterDuffXfermode(PorterDuff.Mode.SRC_IN)
                canvas.drawRect(bounds, shaderPaint)
                shaderPaint.shader = null
                shaderPaint.colorFilter = null
                shaderPaint.xfermode = null
            }
        }

        if (style.clockEdgeStrokeEnabled) {
            val strokeW = (style.clockRimWidth * 0.55f * density).coerceIn(0.8f * density, 5.5f * density)
            val rimAlpha = (145 + (80 * glassBr).toInt()).coerceIn(110, 235)
            rimPaint.color = Color.argb(rimAlpha, 255, 255, 255)

            if (isLiquid || style.clockRimBlur > 0.1f) {
                val blurRad = if (style.clockRimBlur > 0.1f) style.clockRimBlur * 0.5f * density else 1.5f * density
                rimPaint.strokeWidth = strokeW * 1.6f
                rimPaint.maskFilter = BlurMaskFilter(blurRad, BlurMaskFilter.Blur.NORMAL)
                drawStroke(canvas, clockText, startX, baselineY, dateText, dateX, dateY)
            }

            rimPaint.strokeWidth = strokeW
            rimPaint.maskFilter = null
            drawStroke(canvas, clockText, startX, baselineY, dateText, dateX, dateY)
        }

        canvas.restoreToCount(textLayer)
    }

    private fun drawPunch(canvas: Canvas, ref: Paint, text: String, x: Float, y: Float) {
        punchPaint.textSize = ref.textSize
        punchPaint.typeface = ref.typeface
        punchPaint.letterSpacing = ref.letterSpacing
        canvas.drawText(text, x, y, punchPaint)
    }

    private fun drawStroke(
        canvas: Canvas,
        clockText: String,
        cX: Float,
        cY: Float,
        dateText: String,
        dX: Float,
        dY: Float
    ) {
        rimPaint.textSize = clockPaint.textSize
        rimPaint.typeface = clockPaint.typeface
        rimPaint.letterSpacing = clockPaint.letterSpacing
        canvas.drawText(clockText, cX, cY, rimPaint)

        rimPaint.textSize = datePaint.textSize
        rimPaint.typeface = datePaint.typeface
        rimPaint.letterSpacing = datePaint.letterSpacing
        canvas.drawText(dateText, dX, dY, rimPaint)
    }

    fun release() {
        maskBitmap?.recycle(); maskBitmap = null
        maskCanvas = null
        maskShader = null
    }
}