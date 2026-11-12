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
import android.graphics.PorterDuff
import android.graphics.PorterDuffXfermode
import android.graphics.Rect
import android.graphics.RectF
import android.graphics.Shader
import android.graphics.Typeface
import com.depthstudio.wallpaper.WallpaperConfig
import java.io.File
import java.io.FileOutputStream
import kotlin.math.max
import kotlin.math.min

class ClockAndDateRenderer(
    private val context: Context,
    private val shaders: WallpaperShaders
) {
    private val typefaceCache = mutableMapOf<String, Typeface>()

    private var glyphMaskBitmap: Bitmap? = null
    private var glyphMaskCanvas: Canvas? = null
    private var glyphMaskShader: BitmapShader? = null

    private val clockPaint = Paint(Paint.ANTI_ALIAS_FLAG)
    private val maskGlyphPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
        color = Color.WHITE
        style = Paint.Style.FILL
    }
    private val strokePaint = Paint(Paint.ANTI_ALIAS_FLAG)
    private val shadowPaint = Paint(Paint.ANTI_ALIAS_FLAG)
    private val glassShaderPaint = Paint(Paint.ANTI_ALIAS_FLAG)
    private val innerRimPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
        style = Paint.Style.STROKE
        strokeJoin = Paint.Join.ROUND
        strokeCap = Paint.Cap.ROUND
        xfermode = PorterDuffXfermode(PorterDuff.Mode.SRC_ATOP)
    }
    private val datePaint = Paint(Paint.ANTI_ALIAS_FLAG)
    private val punchOutPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
        style = Paint.Style.FILL
        color = Color.BLACK
        xfermode = PorterDuffXfermode(PorterDuff.Mode.DST_OUT)
    }

    private val tempGlyphBounds = Rect()
    private val tempCompBounds = RectF()

    fun setupPaints(config: WallpaperConfig, canvasWidth: Int) {
        val tf = getTypefaceForFont(config.fontFamily)
        val textPx = config.fontSize * canvasWidth

        clockPaint.apply {
            reset()
            isAntiAlias = true
            textSize = textPx
            textAlign = Paint.Align.LEFT
            typeface = tf
            letterSpacing = config.letterSpacing
        }

        shadowPaint.apply {
            reset()
            isAntiAlias = true
            textSize = textPx
            textAlign = Paint.Align.LEFT
            typeface = tf
            letterSpacing = config.letterSpacing
            color = Color.BLACK
        }

        strokePaint.apply {
            reset()
            isAntiAlias = true
            textSize = textPx
            textAlign = Paint.Align.LEFT
            style = Paint.Style.STROKE
            strokeJoin = Paint.Join.ROUND
            strokeCap = Paint.Cap.ROUND
            typeface = tf
            letterSpacing = config.letterSpacing
        }

        innerRimPaint.apply {
            textSize = textPx
            textAlign = Paint.Align.LEFT
            typeface = tf
            letterSpacing = config.letterSpacing
        }

        punchOutPaint.apply {
            isAntiAlias = true
            textSize = textPx
            textAlign = Paint.Align.LEFT
            style = Paint.Style.FILL
            typeface = tf
            letterSpacing = config.letterSpacing
            color = Color.BLACK
            xfermode = PorterDuffXfermode(PorterDuff.Mode.DST_OUT)
        }
    }

    fun getTypefaceForFont(fontFamily: String): Typeface {
        return try {
            when (fontFamily) {
                "Display 1" -> loadAssetFontSmart("bigclock")
                "Display 2" -> loadAssetFontSmart("tall1")
                "Display 3" -> loadAssetFontSmart("tall3")
                "Display 4" -> loadAssetFontSmart("tall4.otf")
                "Display 5" -> loadAssetFontSmart("tall5.otf")
                "Display 6" -> loadAssetFontSmart("tall7")
                "Display 7" -> loadAssetFontSmart("tall8")
                "Sans-Serif" -> Typeface.create(Typeface.SANS_SERIF, Typeface.NORMAL)
                "SF Pro" -> loadAssetFontSmart("SFProDisplay-Bold.otf")
                "New York" -> loadAssetFontSmart("NewYork-Semibold.otf")
                else -> loadAssetFontSmart("SFProDisplay-Bold.otf")
            }
        } catch (_: Exception) {
            Typeface.create(Typeface.DEFAULT, Typeface.NORMAL)
        }
    }

    private fun loadAssetFontSmart(baseFileName: String): Typeface {
        typefaceCache[baseFileName]?.let { return it }

        val assetMgr = context.applicationContext.assets
        val cleanBase = baseFileName.substringBeforeLast(".")
        val folder = "flutter_assets/assets/fonts"

        val candidates = mutableListOf(
            "$folder/$baseFileName",
            "$folder/$cleanBase.otf",
            "$folder/$cleanBase.ttf",
            "$folder/$cleanBase.OTF",
            "$folder/$cleanBase.TTF"
        )

        try {
            val filesInAssets = assetMgr.list(folder)
            if (filesInAssets != null) {
                for (file in filesInAssets) {
                    if (file.equals(baseFileName, ignoreCase = true) ||
                        file.substringBeforeLast(".").equals(cleanBase, ignoreCase = true)
                    ) {
                        candidates.add(0, "$folder/$file")
                    }
                }
            }
        } catch (_: Exception) {}

        for (assetPath in candidates.distinct()) {
            try {
                val tf = Typeface.createFromAsset(assetMgr, assetPath)
                if (tf != null) {
                    typefaceCache[baseFileName] = tf
                    return tf
                }
            } catch (_: Exception) {
                try {
                    val tempFile = File(context.applicationContext.cacheDir, "font_${assetPath.substringAfterLast("/")}")
                    assetMgr.open(assetPath).use { input ->
                        FileOutputStream(tempFile).use { output ->
                            input.copyTo(output)
                        }
                    }
                    val tf = Typeface.createFromFile(tempFile)
                    if (tf != null) {
                        typefaceCache[baseFileName] = tf
                        return tf
                    }
                } catch (_: Exception) {}
            }
        }

        return Typeface.create(Typeface.DEFAULT, Typeface.NORMAL)
    }

    fun normalizedDepthMode(mode: String): String {
        return when (mode) {
            "Liquid", "Acrylic", "Aero" -> mode
            else -> "Standard"
        }
    }

    private fun renderGlyphOpticalGlass(
        canvas: Canvas,
        canvasWidth: Int,
        canvasHeight: Int,
        drawBounds: RectF,
        tintColor: Int,
        glassBr: Float,
        mode: String,
        density: Float,
        sharpGlassBgBitmap: Bitmap?,
        blurredBgShaderBitmap: Bitmap?,
        ambientMicaBitmap: Bitmap?
    ) {
        val fallbackBmp = when (mode) {
            "Liquid" -> sharpGlassBgBitmap ?: blurredBgShaderBitmap
            "Aero" -> ambientMicaBitmap ?: blurredBgShaderBitmap
            else -> blurredBgShaderBitmap
        } ?: return

        val glassMatrix = GlassBitmapProcessor.buildOpticalGlassMatrix(tintColor, glassBr, mode)
        val shader = GlassBitmapProcessor.createLinearBitmapShader(fallbackBmp, Shader.TileMode.CLAMP)

        val matrix = Matrix()
        val scale = max(canvasWidth.toFloat() / fallbackBmp.width, canvasHeight.toFloat() / fallbackBmp.height)
        val dx = (canvasWidth - fallbackBmp.width * scale) / 2f
        val dy = (canvasHeight - fallbackBmp.height * scale) / 2f
        matrix.postScale(scale, scale)
        matrix.postTranslate(dx, dy)
        shader.setLocalMatrix(matrix)

        glassShaderPaint.shader = shader
        glassShaderPaint.colorFilter = ColorMatrixColorFilter(ColorMatrix(glassMatrix))

        canvas.save()
        if (mode == "Liquid") {
            val lensCenterX = drawBounds.centerX()
            val lensCenterY = drawBounds.centerY()
            canvas.translate(lensCenterX, lensCenterY + 1.0f * density)
            canvas.scale(1.015f, 1.015f)
            canvas.translate(-lensCenterX, -lensCenterY)
        }

        glassShaderPaint.xfermode = PorterDuffXfermode(PorterDuff.Mode.SRC_IN)
        canvas.drawRect(drawBounds, glassShaderPaint)
        canvas.restore()

        glassShaderPaint.xfermode = null

        val isNearWhite = Color.red(tintColor) > 235 && Color.green(tintColor) > 235 && Color.blue(tintColor) > 235
        val frostVeilAlpha = when (mode) {
            "Acrylic" -> if (isNearWhite) 0.20f else 0.28f
            "Liquid" -> if (isNearWhite) 0.08f else 0.16f
            else -> if (isNearWhite) 0.12f else 0.22f
        }

        val uniformFrostPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            xfermode = PorterDuffXfermode(PorterDuff.Mode.SRC_ATOP)
            color = Color.argb((frostVeilAlpha * 255).toInt(), Color.red(tintColor), Color.green(tintColor), Color.blue(tintColor))
        }
        canvas.drawRect(drawBounds, uniformFrostPaint)
    }

    fun drawClockLayer(
        canvas: Canvas,
        canvasWidth: Int,
        canvasHeight: Int,
        screenBounds: RectF,
        config: WallpaperConfig,
        hourStr: String,
        minStr: String,
        animProgress: Float,
        paintHours: Boolean,
        paintMinutes: Boolean,
        visibilityFactor: Float,
        sharpGlassBgBitmap: Bitmap?,
        blurredBgShaderBitmap: Bitmap?,
        ambientMicaBitmap: Bitmap?
    ) {
        val p = animProgress.coerceIn(0f, 1f)
        if (p <= 0.01f || visibilityFactor <= 0.01f) return

        val animStyle = config.clockAnimStyle
        var animAlpha = 1f
        var animOffsetY = 0f
        var animScale = 1f

        if (animStyle != "None") {
            animAlpha = p
            when (animStyle) {
                "SlideUp" -> animOffsetY = (1f - p) * (canvasHeight * 0.12f)
                "SlideDown" -> animOffsetY = -(1f - p) * (canvasHeight * 0.12f)
                "ScaleUp" -> animScale = 0.68f + (0.32f * p)
                "ScaleDown" -> animScale = 1.32f - (0.32f * p)
            }
        }

        val effectiveOpacity = (config.textOpacity * animAlpha * visibilityFactor).coerceIn(0f, 1f)
        val layerAlpha = (effectiveOpacity * 255).toInt().coerceIn(0, 255)
        if (layerAlpha <= 2) return

        val sepStr = when (config.clockFormat) {
            "HH:MM" -> ":"
            "HH MM" -> " "
            else -> ""
        }

        val fontSize = config.fontSize * canvasWidth
        clockPaint.textSize = fontSize
        shadowPaint.textSize = fontSize
        strokePaint.textSize = fontSize
        innerRimPaint.textSize = fontSize
        punchOutPaint.textSize = fontSize

        val letterSpacingPx = config.letterSpacing * fontSize
        val centerX = (canvasWidth / 2f) + (config.horizontalPos - 0.50f) * canvasWidth * 2f
        val topY = (config.verticalPos * canvasHeight) + animOffsetY

        val wHour = clockPaint.measureText(hourStr)
        val wSep = clockPaint.measureText(sepStr)
        val wMin = clockPaint.measureText(minStr)

        clockPaint.getTextBounds(hourStr, 0, hourStr.length, tempGlyphBounds)
        val fm = clockPaint.fontMetrics
        val realTopOffset = min(tempGlyphBounds.top.toFloat(), fm.ascent)
        val realBottomOffset = max(tempGlyphBounds.bottom.toFloat(), fm.descent)

        val hourBaselineY = topY + (fontSize * 0.82f)
        val stepY = (fontSize * 0.88f) + (config.lineSpacing * canvasHeight)

        val hourVisualW = wHour - letterSpacingPx
        val minVisualW = wMin - letterSpacingPx
        val useVertical = config.clockDisplay == "Vertical"

        val hourX: Float
        val sepX: Float
        val minX: Float
        val minBaselineY: Float
        val pivotY: Float

        if (useVertical) {
            hourX = centerX - (hourVisualW / 2f)
            sepX = 0f
            minX = centerX - (minVisualW / 2f)
            minBaselineY = hourBaselineY + stepY
            pivotY = hourBaselineY - (fontSize * 0.41f) + (stepY / 2f)
        } else {
            val fullVisualW = wHour + wSep + wMin - letterSpacingPx
            val startX = centerX - (fullVisualW / 2f)
            hourX = startX
            sepX = startX + wHour
            minX = startX + wHour + wSep
            minBaselineY = hourBaselineY
            pivotY = hourBaselineY - (fontSize * 0.41f)
        }

        val mode = normalizedDepthMode(config.depthMode)
        val isGlass = mode == "Liquid" || mode == "Acrylic" || mode == "Aero"
        val isLiquid = mode == "Liquid"
        val isAcrylic = mode == "Acrylic"
        val density = context.resources.displayMetrics.density
        val glassBr = config.rimBrightness.coerceIn(0f, 1f)

        fun applyStretchAndAnim(c: Canvas) {
            if (config.stretch != 1f || animScale != 1f) {
                c.scale(animScale, config.stretch * animScale, centerX, pivotY)
            }
        }

        fun drawComponentText(targetCanvas: Canvas, isHoursComp: Boolean, paintToUse: Paint) {
            if (isHoursComp) {
                targetCanvas.drawText(hourStr, hourX, hourBaselineY, paintToUse)
                if (!useVertical && sepStr.isNotEmpty()) {
                    targetCanvas.drawText(sepStr, sepX, hourBaselineY, paintToUse)
                }
            } else {
                targetCanvas.drawText(minStr, minX, minBaselineY, paintToUse)
            }
        }

        fun renderIsolatedComponent(isHoursComp: Boolean) {
            val tintColor = if (isHoursComp) config.fontColor else config.minuteColor
            val compLeft = if (isHoursComp) hourX else minX
            val compWidth = if (isHoursComp) {
                wHour + (if (!useVertical) wSep else 0f)
            } else {
                wMin
            }
            val compBaselineY = if (isHoursComp) hourBaselineY else minBaselineY

            val rawTop = compBaselineY + realTopOffset
            val rawBottom = compBaselineY + realBottomOffset
            val stretchedTop = pivotY + (rawTop - pivotY) * config.stretch * animScale
            val stretchedBottom = pivotY + (rawBottom - pivotY) * config.stretch * animScale

            val pad = 34f * density * max(animScale, 1f)
            val scaledHalfW = (compWidth * max(animScale, 1f)) / 2f
            val compCenterX = compLeft + compWidth / 2f
            tempCompBounds.set(
                (compCenterX - scaledHalfW - pad).coerceAtLeast(0f),
                (stretchedTop - pad).coerceAtLeast(0f),
                (compCenterX + scaledHalfW + pad).coerceAtMost(canvasWidth.toFloat()),
                (stretchedBottom + pad).coerceAtMost(canvasHeight.toFloat())
            )

            if (config.shadowEnabled) {
                val shadowLayer = canvas.saveLayerAlpha(tempCompBounds, (animAlpha * visibilityFactor * 255).toInt().coerceIn(0, 255))
                canvas.save()
                applyStretchAndAnim(canvas)
                val shadowRad = (if (isLiquid) 14f else if (isGlass) 12f else 10f) * density
                val shadowAlpha = if (isLiquid) 68 else if (isGlass) 58 else 105
                shadowPaint.setShadowLayer(
                    shadowRad,
                    0f,
                    (if (isLiquid) 4f else 3f) * density,
                    Color.argb(shadowAlpha, 0, 0, 0)
                )
                drawComponentText(canvas, isHoursComp, shadowPaint)
                shadowPaint.clearShadowLayer()
                drawComponentText(canvas, isHoursComp, punchOutPaint)
                canvas.restore()
                canvas.restoreToCount(shadowLayer)
            }

            if (!isGlass) {
                val solidLayer = canvas.saveLayerAlpha(tempCompBounds, layerAlpha)
                canvas.save()
                applyStretchAndAnim(canvas)
                clockPaint.shader = null
                clockPaint.xfermode = null
                clockPaint.color = tintColor
                clockPaint.alpha = 255
                drawComponentText(canvas, isHoursComp, clockPaint)
                canvas.restore()
                canvas.restoreToCount(solidLayer)
                return
            }

            val glassLayer = canvas.saveLayerAlpha(tempCompBounds, layerAlpha)
            val clearShader = if (isLiquid) shaders.getClockClearShader() else null
            val clearBgBmp = sharpGlassBgBitmap ?: blurredBgShaderBitmap

            if (isLiquid && clearShader != null && clearBgBmp != null) {
                val maskW = tempCompBounds.width().toInt().coerceAtLeast(16)
                val maskH = tempCompBounds.height().toInt().coerceAtLeast(16)

                if (glyphMaskBitmap == null || glyphMaskBitmap?.width != maskW || glyphMaskBitmap?.height != maskH) {
                    glyphMaskBitmap?.recycle()
                    val mBmp = Bitmap.createBitmap(maskW, maskH, Bitmap.Config.ARGB_8888)
                    glyphMaskBitmap = mBmp
                    glyphMaskCanvas = Canvas(mBmp)
                    glyphMaskShader = GlassBitmapProcessor.createLinearBitmapShader(mBmp, Shader.TileMode.CLAMP)
                }

                val mCanvas = glyphMaskCanvas!!
                val mShader = glyphMaskShader!!
                mCanvas.drawColor(Color.TRANSPARENT, PorterDuff.Mode.CLEAR)

                mCanvas.save()
                mCanvas.translate(-tempCompBounds.left, -tempCompBounds.top)
                applyStretchAndAnim(mCanvas)
                clockPaint.shader = null
                clockPaint.xfermode = null
                clockPaint.maskFilter = null
                clockPaint.color = Color.WHITE
                clockPaint.alpha = 255
                drawComponentText(mCanvas, isHoursComp, clockPaint)

                maskGlyphPaint.textSize = fontSize
                maskGlyphPaint.typeface = clockPaint.typeface
                maskGlyphPaint.letterSpacing = config.letterSpacing
                maskGlyphPaint.maskFilter = BlurMaskFilter(3.5f * density, BlurMaskFilter.Blur.NORMAL)
                maskGlyphPaint.xfermode = PorterDuffXfermode(PorterDuff.Mode.SRC_IN)
                drawComponentText(mCanvas, isHoursComp, maskGlyphPaint)
                maskGlyphPaint.maskFilter = null
                maskGlyphPaint.xfermode = null
                mCanvas.restore()

                val bgShader = GlassBitmapProcessor.createLinearBitmapShader(clearBgBmp, Shader.TileMode.CLAMP)
                val bgMatrix = Matrix()
                val scale = max(canvasWidth.toFloat() / clearBgBmp.width, canvasHeight.toFloat() / clearBgBmp.height)
                val dx = (canvasWidth - clearBgBmp.width * scale) / 2f
                val dy = (canvasHeight - clearBgBmp.height * scale) / 2f
                bgMatrix.postScale(scale, scale)
                bgMatrix.postTranslate(dx, dy)
                bgShader.setLocalMatrix(bgMatrix)

                val isNearWhite = Color.red(tintColor) > 235 && Color.green(tintColor) > 235 && Color.blue(tintColor) > 235
                val tintStrength = if (isNearWhite) 0.04f else 0.22f

                clearShader.setInputShader("uBg", bgShader)
                clearShader.setInputShader("uGlyphMask", mShader)
                clearShader.setFloatUniform("uMaskOffset", tempCompBounds.left, tempCompBounds.top)
                clearShader.setFloatUniform(
                    "uTint",
                    Color.red(tintColor) / 255f,
                    Color.green(tintColor) / 255f,
                    Color.blue(tintColor) / 255f
                )
                clearShader.setFloatUniform("uTintStrength", tintStrength)
                clearShader.setFloatUniform("uBrightness", glassBr)

                glassShaderPaint.shader = clearShader
                glassShaderPaint.colorFilter = null
                glassShaderPaint.xfermode = null
                canvas.drawRect(tempCompBounds, glassShaderPaint)
                glassShaderPaint.shader = null
            } else {
                canvas.save()
                applyStretchAndAnim(canvas)
                clockPaint.shader = null
                clockPaint.xfermode = null
                clockPaint.color = Color.WHITE
                clockPaint.alpha = 255
                drawComponentText(canvas, isHoursComp, clockPaint)
                canvas.restore()

                renderGlyphOpticalGlass(
                    canvas = canvas,
                    canvasWidth = canvasWidth,
                    canvasHeight = canvasHeight,
                    drawBounds = tempCompBounds,
                    tintColor = tintColor,
                    glassBr = glassBr,
                    mode = mode,
                    density = density,
                    sharpGlassBgBitmap = sharpGlassBgBitmap,
                    blurredBgShaderBitmap = blurredBgShaderBitmap,
                    ambientMicaBitmap = ambientMicaBitmap
                )
            }

            canvas.save()
            applyStretchAndAnim(canvas)

            if (config.edgeStrokeEnabled) {
                if (isLiquid) {
                    innerRimPaint.strokeWidth = (fontSize * 0.036f).coerceIn(2.2f * density, 7.5f * density)
                    innerRimPaint.maskFilter = BlurMaskFilter(2.8f * density, BlurMaskFilter.Blur.NORMAL)
                    innerRimPaint.shader = null
                    innerRimPaint.color = Color.argb((115 + (80 * glassBr).toInt()).coerceIn(90, 210), 255, 255, 255)
                    drawComponentText(canvas, isHoursComp, innerRimPaint)

                    innerRimPaint.strokeWidth = 1.35f * density
                    innerRimPaint.maskFilter = null
                    innerRimPaint.color = Color.argb((155 + (75 * glassBr).toInt()).coerceIn(120, 235), 255, 255, 255)
                    drawComponentText(canvas, isHoursComp, innerRimPaint)
                } else if (isAcrylic) {
                    innerRimPaint.strokeWidth = 1.25f * density
                    innerRimPaint.maskFilter = null
                    innerRimPaint.shader = null
                    innerRimPaint.color = Color.argb((135 + (65 * glassBr).toInt()).coerceIn(100, 210), 255, 255, 255)
                    drawComponentText(canvas, isHoursComp, innerRimPaint)
                } else {
                    innerRimPaint.strokeWidth = 1.5f * density
                    innerRimPaint.maskFilter = BlurMaskFilter(1.2f * density, BlurMaskFilter.Blur.NORMAL)
                    innerRimPaint.shader = null
                    innerRimPaint.color = Color.argb((125 + (65 * glassBr).toInt()).coerceIn(95, 200), 255, 255, 255)
                    drawComponentText(canvas, isHoursComp, innerRimPaint)
                }
            }
            canvas.restore()
            canvas.restoreToCount(glassLayer)
        }

        if (paintHours) renderIsolatedComponent(true)
        if (paintMinutes) renderIsolatedComponent(false)

        val shouldDrawRim = config.edgeStrokeEnabled && config.rimOpacity > 0.01f
        if (shouldDrawRim) {
            val rimLayer = canvas.saveLayerAlpha(screenBounds, layerAlpha)
            canvas.save()
            applyStretchAndAnim(canvas)

            fun strokePart(text: String, x: Float, baselineY: Float, w: Float, tintColor: Int) {
                if (text.isEmpty()) return
                val bright = GlassBitmapProcessor.blendTowardsWhite(tintColor, if (isLiquid) 0.92f else glassBr * 0.85f)
                val br = Color.red(bright); val bg = Color.green(bright); val bb = Color.blue(bright)
                val tr = Color.red(tintColor); val tg = Color.green(tintColor); val tb = Color.blue(tintColor)

                val effOpacity = if (isLiquid) (config.rimOpacity * 1.10f).coerceIn(0.30f, 1f) else config.rimOpacity
                val alphaMain = (effOpacity * 255).toInt().coerceIn(0, 255)
                val alphaLow = (alphaMain * 0.45f).toInt()
                val alphaMid = (alphaMain * 0.90f).toInt()

                val rectTop = baselineY + realTopOffset
                val rectBottom = baselineY + realBottomOffset
                strokePaint.shader = LinearGradient(
                    x, rectTop, x + w, rectBottom,
                    intArrayOf(
                        Color.argb(alphaMain, br, bg, bb),
                        Color.argb(alphaLow, tr, tg, tb),
                        Color.argb(alphaMid, br, bg, bb)
                    ),
                    floatArrayOf(0f, 0.50f, 1f),
                    Shader.TileMode.CLAMP
                )
                canvas.drawText(text, x, baselineY, strokePaint)
            }

            if (paintHours) {
                strokePart(hourStr, hourX, hourBaselineY, wHour, config.fontColor)
                if (!useVertical && sepStr.isNotEmpty()) {
                    strokePart(sepStr, sepX, hourBaselineY, wSep, config.fontColor)
                }
            }
            if (paintMinutes) {
                strokePart(minStr, minX, minBaselineY, wMin, config.minuteColor)
            }

            if (paintHours) drawComponentText(canvas, true, punchOutPaint)
            if (paintMinutes) drawComponentText(canvas, false, punchOutPaint)

            canvas.restore()
            canvas.restoreToCount(rimLayer)
        }
    }

    fun drawDate(
        canvas: Canvas,
        canvasWidth: Int,
        canvasHeight: Int,
        screenBounds: RectF,
        config: WallpaperConfig,
        dateStr: String,
        animProgress: Float,
        visibilityFactor: Float,
        backgroundBitmap: Bitmap?,
        sharpGlassBgBitmap: Bitmap?,
        blurredBgShaderBitmap: Bitmap?,
        ambientMicaBitmap: Bitmap?
    ) {
        val p = animProgress.coerceIn(0f, 1f)
        if (p <= 0.01f || visibilityFactor <= 0.01f) return

        val animStyle = config.clockAnimStyle
        var alphaFactor = 1f
        var offsetY = 0f
        var scaleFactor = 1f

        if (animStyle != "None") {
            alphaFactor = p
            when (animStyle) {
                "SlideUp" -> offsetY = (1f - p) * (canvasHeight * 0.08f)
                "SlideDown" -> offsetY = -(1f - p) * (canvasHeight * 0.08f)
                "ScaleUp" -> scaleFactor = 0.72f + (0.28f * p)
                "ScaleDown" -> scaleFactor = 1.28f - (0.28f * p)
            }
        }

        val effAlpha = (alphaFactor * visibilityFactor).coerceIn(0f, 1f)
        val layerAlpha = (effAlpha * 255).toInt().coerceIn(0, 255)
        if (layerAlpha <= 2) return

        val fontSize = config.dateFontSize * canvasWidth
        val dateText = if (config.dateAllCaps) dateStr.uppercase() else dateStr

        datePaint.apply {
            reset()
            isAntiAlias = true
            color = config.dateColor
            alpha = layerAlpha
            textSize = fontSize
            textAlign = Paint.Align.LEFT
            typeface = getTypefaceForFont(config.dateFontFamily)
            isFakeBoldText = config.dateBold
            if (config.shadowEnabled) {
                setShadowLayer(6f, 0f, 2f, Color.argb((125 * effAlpha).toInt(), 0, 0, 0))
            }
        }

        val wDate = datePaint.measureText(dateText)
        val centerX = (canvasWidth / 2f) + (config.dateHorizontalPos - 0.50f) * canvasWidth * 2f
        val targetBaselineY = (config.dateVerticalPos * canvasHeight) + (fontSize * 0.85f) + offsetY
        val drawX = centerX - (wDate / 2f)

        canvas.save()
        if (scaleFactor != 1f) {
            canvas.scale(scaleFactor, scaleFactor, centerX, targetBaselineY - (fontSize * 0.4f))
        }

        val mode = normalizedDepthMode(config.depthMode)
        val isGlass = mode == "Liquid" || mode == "Acrylic" || mode == "Aero"
        val glassBmp = when (mode) {
            "Liquid" -> sharpGlassBgBitmap ?: blurredBgShaderBitmap
            "Aero" -> ambientMicaBitmap ?: blurredBgShaderBitmap
            else -> blurredBgShaderBitmap
        }

        if (isGlass && backgroundBitmap != null && glassBmp != null) {
            val dateMaskLayer = canvas.saveLayerAlpha(screenBounds, layerAlpha)

            val maskPaint = Paint(datePaint).apply {
                color = Color.WHITE
                alpha = 255
                clearShadowLayer()
            }
            canvas.drawText(dateText, drawX, targetBaselineY, maskPaint)

            val glassMatrix = GlassBitmapProcessor.buildOpticalGlassMatrix(config.dateColor, config.rimBrightness.coerceIn(0f, 1f), mode)
            val shader = GlassBitmapProcessor.createLinearBitmapShader(glassBmp, Shader.TileMode.CLAMP)

            val matrix = Matrix()
            val scale = max(canvasWidth.toFloat() / glassBmp.width, canvasHeight.toFloat() / glassBmp.height)
            val dx = (canvasWidth - glassBmp.width * scale) / 2f
            val dy = (canvasHeight - glassBmp.height * scale) / 2f
            matrix.postScale(scale, scale)
            matrix.postTranslate(dx, dy)
            shader.setLocalMatrix(matrix)

            val glassPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
                this.shader = shader
                colorFilter = ColorMatrixColorFilter(ColorMatrix(glassMatrix))
                xfermode = PorterDuffXfermode(PorterDuff.Mode.SRC_IN)
            }
            canvas.drawRect(screenBounds, glassPaint)

            val isNearWhite = Color.red(config.dateColor) > 235 && Color.green(config.dateColor) > 235 && Color.blue(config.dateColor) > 235
            val veilAlpha = if (mode == "Liquid") (if (isNearWhite) 18 else 38) else (if (isNearWhite) 45 else 65)

            val frostPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
                xfermode = PorterDuffXfermode(PorterDuff.Mode.SRC_ATOP)
                color = Color.argb(veilAlpha, Color.red(config.dateColor), Color.green(config.dateColor), Color.blue(config.dateColor))
            }
            canvas.drawRect(screenBounds, frostPaint)

            canvas.restoreToCount(dateMaskLayer)
        } else {
            canvas.drawText(dateText, drawX, targetBaselineY, datePaint)
        }

        canvas.restore()
    }

    fun release() {
        typefaceCache.clear()
        glyphMaskBitmap?.recycle()
        glyphMaskBitmap = null
        glyphMaskCanvas = null
        glyphMaskShader = null
    }
}