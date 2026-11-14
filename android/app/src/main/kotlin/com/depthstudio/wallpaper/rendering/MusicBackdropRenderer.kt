package com.depthstudio.wallpaper.rendering

import android.graphics.Bitmap
import android.graphics.BitmapShader
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.ColorMatrix
import android.graphics.ColorMatrixColorFilter
import android.graphics.Matrix
import android.graphics.Paint
import android.graphics.PorterDuff
import android.graphics.PorterDuffXfermode
import android.graphics.RadialGradient
import android.graphics.Shader
import android.util.Log
import com.depthstudio.wallpaper.MusicStateHolder
import kotlin.math.cos
import kotlin.math.max
import kotlin.math.roundToInt
import kotlin.math.sin

class MusicBackdropRenderer {
    companion object {
        private const val TAG = "MusicBackdropRenderer"
    }

    data class BlurSample(
        val bitmap: Bitmap,
        val shader: BitmapShader
    )

    private class BlurSlot {
        var bitmap: Bitmap? = null
        var canvas: Canvas? = null
        var shader: BitmapShader? = null
        var lastBucket: Int = -1
        var lastFrameId: Long = -1L

        fun release() {
            bitmap?.recycle()
            bitmap = null
            canvas = null
            shader = null
            lastBucket = -1
            lastFrameId = -1L
        }
    }

    private var blurredCoverBg: Bitmap? = null
    private val orbTextures = arrayOfNulls<Bitmap>(4)

    var liveBufferBitmap: Bitmap? = null
        private set
    var liveBufferShader: BitmapShader? = null
        private set
    private var liveBufferCanvas: Canvas? = null

    private var currentFrameId: Long = 0L
    private val primaryBlurSlot = BlurSlot()
    private val secondaryBlurSlot = BlurSlot()
    private var nextSlotToggle: Boolean = false

    val hasReadyBackground: Boolean
        get() = blurredCoverBg != null

    private val panMatrix = Matrix()
    private val orbMatrix = Matrix()
    private val scaleMatrix = Matrix()

    private val drawPaint = Paint(Paint.FILTER_BITMAP_FLAG or Paint.DITHER_FLAG or Paint.ANTI_ALIAS_FLAG)
    private val orbAddPaint = Paint(Paint.FILTER_BITMAP_FLAG or Paint.DITHER_FLAG or Paint.ANTI_ALIAS_FLAG).apply {
        xfermode = PorterDuffXfermode(PorterDuff.Mode.SCREEN)
    }
    private val orbNormalPaint = Paint(Paint.FILTER_BITMAP_FLAG or Paint.DITHER_FLAG or Paint.ANTI_ALIAS_FLAG)

    fun prepareAssets(
        smallArt: Bitmap,
        canvasWidth: Int,
        canvasHeight: Int,
        colors: IntArray
    ) {
        try {
            val bufW = 180
            val bufH = if (canvasWidth > 0 && canvasHeight > 0) {
                ((canvasHeight.toFloat() / canvasWidth.toFloat()) * bufW).toInt().coerceAtLeast(180)
            } else {
                380
            }

            val cropped = Bitmap.createBitmap(bufW, bufH, Bitmap.Config.ARGB_8888)
            val ccCanvas = Canvas(cropped)
            val scale = max(bufW.toFloat() / smallArt.width, bufH.toFloat() / smallArt.height)
            val dx = (bufW - smallArt.width * scale) / 2f
            val dy = (bufH - smallArt.height * scale) / 2f
            val m = Matrix().apply {
                postScale(scale, scale)
                postTranslate(dx, dy)
            }

            val satFactor = if (MusicStateHolder.isMonochromeArt) 1.0f else 1.35f
            val cm = ColorMatrix().apply { setSaturation(satFactor) }
            val paint = Paint(Paint.FILTER_BITMAP_FLAG or Paint.ANTI_ALIAS_FLAG).apply {
                colorFilter = ColorMatrixColorFilter(cm)
            }
            ccCanvas.drawBitmap(smallArt, m, paint)
            ccCanvas.drawColor(Color.argb(58, 0, 0, 0))

            val blurred = GlassBitmapProcessor.stackBlurBitmap(cropped, 28)
            if (blurred != cropped) cropped.recycle()

            blurredCoverBg?.recycle()
            blurredCoverBg = blurred

            for (i in 0 until 4) {
                orbTextures[i]?.recycle()
                orbTextures[i] = createRadialOrbBitmap(colors[i], 192)
            }

            if (liveBufferBitmap == null || liveBufferBitmap?.width != bufW || liveBufferBitmap?.height != bufH) {
                liveBufferBitmap?.recycle()
                val liveBmp = Bitmap.createBitmap(bufW, bufH, Bitmap.Config.ARGB_8888)
                liveBufferBitmap = liveBmp
                liveBufferCanvas = Canvas(liveBmp)
                liveBufferShader = GlassBitmapProcessor.createLinearBitmapShader(liveBmp, Shader.TileMode.CLAMP)
            }

            primaryBlurSlot.release()
            secondaryBlurSlot.release()
        } catch (e: Exception) {
            Log.e(TAG, "Error preparing backdrop assets", e)
        }
    }

    private fun createRadialOrbBitmap(color: Int, size: Int): Bitmap {
        val bmp = Bitmap.createBitmap(size, size, Bitmap.Config.ARGB_8888)
        val c = Canvas(bmp)
        val r = Color.red(color)
        val g = Color.green(color)
        val b = Color.blue(color)
        val half = size / 2f

        val p = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            shader = RadialGradient(
                half, half, half,
                intArrayOf(
                    Color.argb(245, r, g, b),
                    Color.argb(175, r, g, b),
                    Color.argb(70, r, g, b),
                    Color.argb(0, r, g, b)
                ),
                floatArrayOf(0f, 0.36f, 0.72f, 1f),
                Shader.TileMode.CLAMP
            )
        }
        c.drawCircle(half, half, half, p)
        return bmp
    }

    fun updateAndDraw(
        canvas: Canvas,
        canvasWidth: Int,
        canvasHeight: Int,
        alphaFraction: Float,
        elapsedSec: Float,
        darkColor: Int
    ) {
        val baseCover = blurredCoverBg ?: return
        val liveBmp = liveBufferBitmap ?: return
        val liveCanvas = liveBufferCanvas ?: return

        val alphaInt = (alphaFraction.coerceIn(0f, 1f) * 255).toInt()
        if (alphaInt <= 2) return

        currentFrameId++
        val bw = liveBmp.width.toFloat()
        val bh = liveBmp.height.toFloat()
        val t = elapsedSec * 0.85f

        liveCanvas.drawColor(darkColor)
        val coverScale = 1.12f + 0.05f * sin(t * 0.45f)
        val coverPanX = bw * 0.04f * cos(t * 0.35f)
        val coverPanY = bh * 0.04f * sin(t * 0.28f)

        panMatrix.reset()
        panMatrix.postTranslate(-baseCover.width / 2f, -baseCover.height / 2f)
        panMatrix.postScale((bw / baseCover.width) * coverScale, (bh / baseCover.height) * coverScale)
        panMatrix.postTranslate(bw / 2f + coverPanX, bh / 2f + coverPanY)
        drawPaint.alpha = 255
        liveCanvas.drawBitmap(baseCover, panMatrix, drawPaint)

        val isMono = MusicStateHolder.isMonochromeArt
        val orbPaint = if (isMono) orbNormalPaint else orbAddPaint

        for (i in 0 until 5) {
            val orbBmp = orbTextures[i % 4] ?: continue
            val ow = orbBmp.width.toFloat()
            val oh = orbBmp.height.toFloat()
            val cx: Float
            val cy: Float
            val radiusScale: Float
            val orbAlpha: Int

            when (i) {
                0 -> {
                    cx = bw * (0.50f + 0.36f * cos(t * 0.68f + 0.2f))
                    cy = bh * (0.28f + 0.24f * sin(t * 0.54f + 0.5f))
                    radiusScale = (max(bw, bh) / ow) * (0.95f + 0.18f * sin(t * 0.80f))
                    orbAlpha = if (isMono) 115 else 210
                }
                1 -> {
                    cx = bw * (0.48f - 0.38f * sin(t * 0.62f + 1.4f))
                    cy = bh * (0.68f + 0.25f * cos(t * 0.50f + 1.1f))
                    radiusScale = (max(bw, bh) / ow) * (1.05f + 0.20f * cos(t * 0.72f))
                    orbAlpha = if (isMono) 105 else 200
                }
                2 -> {
                    cx = bw * (0.52f + 0.34f * sin(t * 0.76f + 2.8f))
                    cy = bh * (0.48f - 0.28f * cos(t * 0.64f + 2.1f))
                    radiusScale = (max(bw, bh) / ow) * (0.88f + 0.16f * sin(t * 0.92f + 1.0f))
                    orbAlpha = if (isMono) 95 else 190
                }
                3 -> {
                    cx = bw * (0.45f - 0.32f * cos(t * 0.56f + 4.0f))
                    cy = bh * (0.36f - 0.22f * sin(t * 0.74f + 3.4f))
                    radiusScale = (max(bw, bh) / ow) * (0.92f + 0.15f * cos(t * 0.65f + 2.3f))
                    orbAlpha = if (isMono) 90 else 175
                }
                else -> {
                    cx = bw * (0.55f + 0.30f * cos(t * 0.82f + 5.1f))
                    cy = bh * (0.76f - 0.22f * sin(t * 0.60f + 4.5f))
                    radiusScale = (max(bw, bh) / ow) * (0.85f + 0.18f * sin(t * 0.70f + 3.8f))
                    orbAlpha = if (isMono) 85 else 165
                }
            }

            orbMatrix.reset()
            orbMatrix.postTranslate(-ow / 2f, -oh / 2f)
            orbMatrix.postScale(radiusScale, radiusScale)
            orbMatrix.postTranslate(cx, cy)
            orbPaint.alpha = orbAlpha
            liveCanvas.drawBitmap(orbBmp, orbMatrix, orbPaint)
        }

        scaleMatrix.reset()
        scaleMatrix.postScale(canvasWidth.toFloat() / bw, canvasHeight.toFloat() / bh)
        drawPaint.alpha = alphaInt
        canvas.drawBitmap(liveBmp, scaleMatrix, drawPaint)
    }

    fun getBlurSample(blurAmount: Float): BlurSample? {
        val liveBmp = liveBufferBitmap ?: return null
        val liveShader = liveBufferShader ?: return null
        val clampedBlur = blurAmount.coerceIn(1f, 40f)
        if (clampedBlur <= 3.5f) {
            return BlurSample(liveBmp, liveShader)
        }

        val bucket = (clampedBlur / 2f).roundToInt().coerceIn(2, 20)
        val slot = when {
            primaryBlurSlot.lastBucket == bucket -> primaryBlurSlot
            secondaryBlurSlot.lastBucket == bucket -> secondaryBlurSlot
            primaryBlurSlot.lastFrameId != currentFrameId -> primaryBlurSlot
            secondaryBlurSlot.lastFrameId != currentFrameId -> secondaryBlurSlot
            else -> {
                nextSlotToggle = !nextSlotToggle
                if (nextSlotToggle) primaryBlurSlot else secondaryBlurSlot
            }
        }

        if (slot.lastBucket == bucket && slot.lastFrameId == currentFrameId && slot.bitmap != null && slot.shader != null) {
            return BlurSample(slot.bitmap!!, slot.shader!!)
        }

        val bw = liveBmp.width.toFloat()
        val bh = liveBmp.height.toFloat()
        val norm = ((clampedBlur - 1f) / 39f).coerceIn(0f, 1f)
        val targetW = (112f - norm * 64f).roundToInt().coerceIn(48, 112)
        val targetH = ((bh / max(bw, 1f)) * targetW).roundToInt().coerceAtLeast(48)

        if (slot.bitmap == null || slot.bitmap?.width != targetW || slot.bitmap?.height != targetH) {
            slot.bitmap?.recycle()
            val bmp = Bitmap.createBitmap(targetW, targetH, Bitmap.Config.ARGB_8888)
            slot.bitmap = bmp
            slot.canvas = Canvas(bmp)
            slot.shader = GlassBitmapProcessor.createLinearBitmapShader(bmp, Shader.TileMode.CLAMP)
        }

        val targetBmp = slot.bitmap ?: return BlurSample(liveBmp, liveShader)
        val targetCanvas = slot.canvas ?: return BlurSample(liveBmp, liveShader)
        val targetShader = slot.shader ?: return BlurSample(liveBmp, liveShader)

        scaleMatrix.reset()
        scaleMatrix.postScale(targetW.toFloat() / bw, targetH.toFloat() / bh)
        drawPaint.alpha = 255
        targetCanvas.drawBitmap(liveBmp, scaleMatrix, drawPaint)

        val stackRadius = (2 + norm * 12f).roundToInt().coerceIn(2, 14)
        val blurredCopy = GlassBitmapProcessor.stackBlurBitmap(targetBmp, stackRadius)
        if (blurredCopy !== targetBmp) {
            targetCanvas.drawBitmap(blurredCopy, 0f, 0f, null)
            blurredCopy.recycle()
        }

        slot.lastBucket = bucket
        slot.lastFrameId = currentFrameId
        return BlurSample(targetBmp, targetShader)
    }

    fun release() {
        blurredCoverBg?.recycle(); blurredCoverBg = null
        for (i in orbTextures.indices) {
            orbTextures[i]?.recycle()
            orbTextures[i] = null
        }
        liveBufferBitmap?.recycle(); liveBufferBitmap = null
        liveBufferCanvas = null
        liveBufferShader = null
        primaryBlurSlot.release()
        secondaryBlurSlot.release()
    }
}