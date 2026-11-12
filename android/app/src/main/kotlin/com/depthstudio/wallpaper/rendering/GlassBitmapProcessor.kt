package com.depthstudio.wallpaper.rendering

import android.graphics.Bitmap
import android.graphics.BitmapShader
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.ColorMatrix
import android.graphics.ColorMatrixColorFilter
import android.graphics.Matrix
import android.graphics.Paint
import android.graphics.Rect
import android.graphics.Shader
import android.os.Build
import kotlin.math.abs
import kotlin.math.max

object GlassBitmapProcessor {

    fun createLinearBitmapShader(bitmap: Bitmap, tileMode: Shader.TileMode): BitmapShader {
        val shader = BitmapShader(bitmap, tileMode, tileMode)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            shader.filterMode = BitmapShader.FILTER_MODE_LINEAR
        }
        return shader
    }

    fun blendTowardsWhite(color: Int, factor: Float): Int {
        val f = factor.coerceIn(0f, 1f)
        val r = (Color.red(color) + (255 - Color.red(color)) * f).toInt()
        val g = (Color.green(color) + (255 - Color.green(color)) * f).toInt()
        val b = (Color.blue(color) + (255 - Color.blue(color)) * f).toInt()
        return Color.rgb(r, g, b)
    }

    fun buildOpticalGlassMatrix(tintColor: Int, brightness: Float, mode: String): FloatArray {
        val b = brightness.coerceIn(0f, 1f)
        val tr = Color.red(tintColor) / 255f
        val tg = Color.green(tintColor) / 255f
        val tb = Color.blue(tintColor) / 255f

        val sat = when (mode) {
            "Liquid" -> 1.45f
            "Aero" -> 1.65f
            else -> 1.48f
        }
        val invSat = 1f - sat
        val lumR = 0.2126f * invSat
        val lumG = 0.7152f * invSat
        val lumB = 0.0722f * invSat

        val baseGain = if (mode == "Acrylic") (0.96f + b * 0.28f) else (0.94f + b * 0.24f)
        val rGain = baseGain * (0.65f + 0.35f * tr)
        val gGain = baseGain * (0.65f + 0.35f * tg)
        val bGain = baseGain * (0.65f + 0.35f * tb)

        val frostLift = when (mode) {
            "Acrylic" -> 18f + b * 20f
            "Aero" -> 10f + b * 15f
            else -> 6f + b * 10f
        }

        return floatArrayOf(
            (lumR + sat) * rGain, lumG * rGain,         lumB * rGain,         0f, frostLift,
            lumR * gGain,         (lumG + sat) * gGain, lumB * gGain,         0f, frostLift,
            lumR * bGain,         lumG * bGain,         (lumB + sat) * bGain, 0f, frostLift,
            0f,                   0f,                   0f,                   1f, 0f
        )
    }

    fun centerCropToScreen(src: Bitmap?, targetW: Int, targetH: Int): Bitmap? {
        if (src == null || targetW <= 0 || targetH <= 0) return src
        if (src.width == targetW && src.height == targetH) return src
        return try {
            val result = Bitmap.createBitmap(targetW, targetH, Bitmap.Config.ARGB_8888)
            val canvas = Canvas(result)
            val scale = max(targetW.toFloat() / src.width, targetH.toFloat() / src.height)
            val scaledW = scale * src.width
            val scaledH = scale * src.height
            val dx = (targetW - scaledW) / 2f
            val dy = (targetH - scaledH) / 2f
            val matrix = Matrix().apply {
                postScale(scale, scale)
                postTranslate(dx, dy)
            }
            val paint = Paint(Paint.FILTER_BITMAP_FLAG or Paint.ANTI_ALIAS_FLAG)
            canvas.drawBitmap(src, matrix, paint)
            if (result != src) src.recycle()
            result
        } catch (_: Exception) {
            src
        }
    }

    fun createOpticalGlassBitmap(
        src: Bitmap,
        targetW: Int,
        targetH: Int,
        blurRadius: Int,
        saturationBoost: Float
    ): Bitmap {
        return try {
            val scaleFactor = if (blurRadius <= 10) 2 else 4
            val w = (targetW / scaleFactor).coerceAtLeast(96)
            val h = (targetH / scaleFactor).coerceAtLeast(96)

            val smallSaturated = Bitmap.createBitmap(w, h, Bitmap.Config.ARGB_8888)
            val c = Canvas(smallSaturated)
            val cm = ColorMatrix().apply { setSaturation(saturationBoost) }
            val p = Paint(Paint.FILTER_BITMAP_FLAG).apply {
                colorFilter = ColorMatrixColorFilter(cm)
            }
            c.drawBitmap(src, null, Rect(0, 0, w, h), p)

            val blurred = stackBlurBitmap(smallSaturated, blurRadius.coerceIn(2, 38))
            if (blurred != smallSaturated) smallSaturated.recycle()

            val result = Bitmap.createScaledBitmap(blurred, targetW, targetH, true)
            if (result != blurred) blurred.recycle()
            result
        } catch (_: Exception) {
            src
        }
    }

    fun createAmbientMicaBitmap(src: Bitmap, targetW: Int, targetH: Int): Bitmap {
        return try {
            val w = 112
            val h = ((targetH.toFloat() / max(targetW, 1)) * w).toInt().coerceAtLeast(112)
            val small = Bitmap.createBitmap(w, h, Bitmap.Config.ARGB_8888)
            val c = Canvas(small)
            val cm = ColorMatrix().apply { setSaturation(1.75f) }
            val p = Paint(Paint.FILTER_BITMAP_FLAG).apply {
                colorFilter = ColorMatrixColorFilter(cm)
            }
            c.drawBitmap(src, null, Rect(0, 0, w, h), p)

            val deepBlur = stackBlurBitmap(small, 30)
            if (deepBlur != small) small.recycle()

            val scaled = Bitmap.createScaledBitmap(deepBlur, targetW, targetH, true)
            if (scaled != deepBlur) deepBlur.recycle()
            scaled
        } catch (_: Exception) {
            src
        }
    }

    fun stackBlurBitmap(sentBitmap: Bitmap, radius: Int): Bitmap {
        val bitmap = sentBitmap.copy(Bitmap.Config.ARGB_8888, true)
        if (radius < 1) return bitmap
        val w = bitmap.width
        val h = bitmap.height
        val pix = IntArray(w * h)
        bitmap.getPixels(pix, 0, w, 0, 0, w, h)
        val wm = w - 1
        val hm = h - 1
        val wh = w * h
        val div = radius + radius + 1
        val r = IntArray(wh)
        val g = IntArray(wh)
        val b = IntArray(wh)
        var rsum: Int; var gsum: Int; var bsum: Int
        var x: Int; var y: Int; var i: Int; var p: Int; var yp: Int; var yi = 0; var yw = 0
        val vmin = IntArray(w.coerceAtLeast(h))
        var divsum = (div + 1) shr 1
        divsum *= divsum
        val dv = IntArray(256 * divsum)
        for (idx in 0 until 256 * divsum) dv[idx] = (idx / divsum)
        val stack = Array(div) { IntArray(3) }
        var stackpointer: Int; var stackstart: Int; var sir: IntArray; var rbs: Int
        val r1 = radius + 1
        var routsum: Int; var goutsum: Int; var boutsum: Int
        var rinsum: Int; var ginsum: Int; var binsum: Int
        y = 0
        while (y < h) {
            bsum = 0; gsum = 0; rsum = 0; boutsum = 0; goutsum = 0; routsum = 0; binsum = 0; ginsum = 0; rinsum = 0
            i = -radius
            while (i <= radius) {
                p = pix[yi + wm.coerceAtMost(i.coerceAtLeast(0))]
                sir = stack[i + radius]
                sir[0] = (p and 0xff0000) shr 16
                sir[1] = (p and 0x00ff00) shr 8
                sir[2] = (p and 0x0000ff)
                rbs = r1 - abs(i)
                rsum += sir[0] * rbs; gsum += sir[1] * rbs; bsum += sir[2] * rbs
                if (i > 0) { rinsum += sir[0]; ginsum += sir[1]; binsum += sir[2] }
                else { routsum += sir[0]; goutsum += sir[1]; boutsum += sir[2] }
                i++
            }
            stackpointer = radius
            x = 0
            while (x < w) {
                r[yi] = dv[rsum]; g[yi] = dv[gsum]; b[yi] = dv[bsum]
                rsum -= routsum; gsum -= goutsum; bsum -= boutsum
                stackstart = stackpointer - radius + div
                sir = stack[stackstart % div]
                routsum -= sir[0]; goutsum -= sir[1]; boutsum -= sir[2]
                if (y == 0) vmin[x] = (x + radius + 1).coerceAtMost(wm)
                p = pix[yw + vmin[x]]
                sir[0] = (p and 0xff0000) shr 16; sir[1] = (p and 0x00ff00) shr 8; sir[2] = (p and 0x0000ff)
                rinsum += sir[0]; ginsum += sir[1]; binsum += sir[2]
                rsum += rinsum; gsum += ginsum; bsum += binsum
                stackpointer = (stackpointer + 1) % div
                sir = stack[stackpointer % div]
                routsum += sir[0]; goutsum += sir[1]; boutsum += sir[2]
                rinsum -= sir[0]; ginsum -= sir[1]; binsum -= sir[2]
                yi++; x++
            }
            yw += w; y++
        }
        x = 0
        while (x < w) {
            bsum = 0; gsum = 0; rsum = 0; boutsum = 0; goutsum = 0; routsum = 0; binsum = 0; ginsum = 0; rinsum = 0
            yp = -radius * w
            i = -radius
            while (i <= radius) {
                yi = 0.coerceAtLeast(yp) + x
                sir = stack[i + radius]
                sir[0] = r[yi]; sir[1] = g[yi]; sir[2] = b[yi]
                rbs = r1 - abs(i)
                rsum += r[yi] * rbs; gsum += g[yi] * rbs; bsum += b[yi] * rbs
                if (i > 0) { rinsum += sir[0]; ginsum += sir[1]; binsum += sir[2] }
                else { routsum += sir[0]; goutsum += sir[1]; boutsum += sir[2] }
                if (i < hm) yp += w
                i++
            }
            yi = x; stackpointer = radius; y = 0
            while (y < h) {
                pix[yi] = (-0x1000000 and pix[yi]) or (dv[rsum] shl 16) or (dv[gsum] shl 8) or dv[bsum]
                rsum -= routsum; gsum -= goutsum; bsum -= boutsum
                stackstart = stackpointer - radius + div
                sir = stack[stackstart % div]
                routsum -= sir[0]; goutsum -= sir[1]; boutsum -= sir[2]
                if (x == 0) vmin[y] = ((y + r1).coerceAtMost(hm)) * w
                p = x + vmin[y]
                sir[0] = r[p]; sir[1] = g[p]; sir[2] = b[p]
                rinsum += sir[0]; ginsum += sir[1]; binsum += sir[2]
                rsum += rinsum; gsum += ginsum; bsum += binsum
                stackpointer = (stackpointer + 1) % div
                sir = stack[stackpointer]
                routsum += sir[0]; goutsum += sir[1]; boutsum += sir[2]
                rinsum -= sir[0]; ginsum -= sir[1]; binsum -= sir[2]
                yi += w; y++
            }
            x++
        }
        bitmap.setPixels(pix, 0, w, 0, 0, w, h)
        return bitmap
    }
}