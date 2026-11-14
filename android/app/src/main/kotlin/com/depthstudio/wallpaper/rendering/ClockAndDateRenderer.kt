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
import com.depthstudio.wallpaper.SceneEngineConfig
import java.io.File
import java.io.FileOutputStream
import java.util.concurrent.ConcurrentHashMap
import kotlin.math.max
import kotlin.math.min

object BundledFontRegistry {
    private val fontPaths = ConcurrentHashMap<String, String>()

    fun register(name: String, path: String) {
        fontPaths[name] = path
    }

    fun getPath(name: String): String? = fontPaths[name]
}

class ClockAndDateRenderer(
    private val context: Context,
    private val shaders: WallpaperShaders
) {
    private val typefaceCache = mutableMapOf<String, Typeface>()

    private var glyphMaskBitmap: Bitmap? = null
    private var glyphMaskCanvas: Canvas? = null
    private var glyphMaskShader: BitmapShader? = null

    private val srcInXfermode = PorterDuffXfermode(PorterDuff.Mode.SRC_IN)
    private val srcAtopXfermode = PorterDuffXfermode(PorterDuff.Mode.SRC_ATOP)
    private val dstOutXfermode = PorterDuffXfermode(PorterDuff.Mode.DST_OUT)

    private val tempMatrix = Matrix()
    private val glassMatrixBuffer = FloatArray(20)
    private val tempColorMatrix = ColorMatrix()

    private var cachedFilterTint: Int = 0
    private var cachedFilterBrightness: Float = -1f
    private var cachedFilterMode: String = ""
    private var cachedColorMatrixFilter: ColorMatrixColorFilter? = null

    private var cachedGlassSourceBitmap: Bitmap? = null
    private var cachedGlassBitmapShader: BitmapShader? = null

    private val clockPaint = Paint(Paint.ANTI_ALIAS_FLAG)
    private val maskGlyphPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
        color = Color.WHITE
        style = Paint.Style.FILL
    }
    private val strokePaint = Paint(Paint.ANTI_ALIAS_FLAG)
    private val shadowPaint = Paint(Paint.ANTI_ALIAS_FLAG)
    private val glassShaderPaint = Paint(Paint.ANTI_ALIAS_FLAG)
    private val frostVeilPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
        xfermode = srcAtopXfermode
    }
    private val innerRimPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
        style = Paint.Style.STROKE
        strokeJoin = Paint.Join.ROUND
        strokeCap = Paint.Cap.ROUND
        xfermode = srcAtopXfermode
    }
    private val datePaint = Paint(Paint.ANTI_ALIAS_FLAG)
    private val dateMaskPaint = Paint(Paint.ANTI_ALIAS_FLAG)
    private val punchOutPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
        style = Paint.Style.FILL
        color = Color.BLACK
        xfermode = dstOutXfermode
    }

    private val tempGlyphBounds = Rect()
    private val tempCompBounds = RectF()

    private fun getOpticalColorFilter(
        tintColor: Int,
        brightness: Float,
        mode: String
    ): ColorMatrixColorFilter {
        val existing = cachedColorMatrixFilter
        if (existing != null &&
            cachedFilterTint == tintColor &&
            cachedFilterBrightness == brightness &&
            cachedFilterMode == mode
        ) {
            return existing
        }
        GlassBitmapProcessor.buildOpticalGlassMatrix(tintColor, brightness, mode, glassMatrixBuffer)
        tempColorMatrix.set(glassMatrixBuffer)
        val created = ColorMatrixColorFilter(tempColorMatrix)
        cachedFilterTint = tintColor
        cachedFilterBrightness = brightness
        cachedFilterMode = mode
        cachedColorMatrixFilter = created
        return created
    }

    private fun getLinearBitmapShader(bitmap: Bitmap): BitmapShader {
        val existing = cachedGlassBitmapShader
        if (existing != null && cachedGlassSourceBitmap === bitmap) {
            return existing
        }
        val created = GlassBitmapProcessor.createLinearBitmapShader(bitmap, Shader.TileMode.CLAMP)
        cachedGlassSourceBitmap = bitmap
        cachedGlassBitmapShader = created
        return created
    }

    fun setupPaints(config: SceneEngineConfig, canvasWidth: Int) {
        val tf = getTypefaceForFont(config.fontFamily, config.customFontPath)
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
            xfermode = dstOutXfermode
        }
    }

    fun getTypefaceForFont(fontFamily: String, customPath: String? = null): Typeface {
        if (!customPath.isNullOrEmpty()) {
            val cacheKey = "file:$customPath"
            typefaceCache[cacheKey]?.let { return it }
            try {
                val file = File(customPath)
                if (file.exists()) {
                    val tf = Typeface.createFromFile(file)
                    if (tf != null) {
                        typefaceCache[cacheKey] = tf
                        return tf
                    }
                }
            } catch (_: Exception) {}
        }

        val registeredPath = BundledFontRegistry.getPath(fontFamily)
        if (!registeredPath.isNullOrEmpty()) {
            val cacheKey = "bundled:$fontFamily"
            typefaceCache[cacheKey]?.let { return it }
            try {
                val file = File(registeredPath)
                if (file.exists()) {
                    val tf = Typeface.createFromFile(file)
                    if (tf != null) {
                        typefaceCache[cacheKey] = tf
                        return tf
                    }
                }
            } catch (_: Exception) {}
        }

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
                else -> Typeface.create(Typeface.SANS_SERIF, Typeface.NORMAL)
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

        val shader = getLinearBitmapShader(fallbackBmp)
        val scale = max(canvasWidth.toFloat() / fallbackBmp.width, canvasHeight.toFloat() / fallbackBmp.height)
        val dx = (canvasWidth - fallbackBmp.width * scale) / 2f
        val dy = (canvasHeight - fallbackBmp.height * scale) / 2f

        tempMatrix.reset()
        tempMatrix.postScale(scale, scale)
        tempMatrix.postTranslate(dx, dy)
        shader.setLocalMatrix(tempMatrix)

        glassShaderPaint.shader = shader
        glassShaderPaint.colorFilter = getOpticalColorFilter(tintColor, glassBr, mode)
        glassShaderPaint.xfermode = srcInXfermode

        canvas.save()
        if (mode == "Liquid") {
            val lensCenterX = drawBounds.centerX()
            val lensCenterY = drawBounds.centerY()
            canvas.translate(lensCenterX, lensCenterY + 1.0f * density)
            canvas.scale(1.015f, 1.015f)
            canvas.translate(-lensCenterX, -lensCenterY)
        }

        canvas.drawRect(drawBounds, glassShaderPaint)
        canvas.restore()

        glassShaderPaint.shader = null
        glassShaderPaint.colorFilter = null
        glassShaderPaint.xfermode = null

        val isNearWhite = Color.red(tintColor) > 235 && Color.green(tintColor) > 235 && Color.blue(tintColor) > 235
        val frostVeilAlpha = when (mode) {
            "Acrylic" -> if (isNearWhite) 0.20f else 0.28f
            "Liquid" -> if (isNearWhite) 0.08f else 0.16f
            else -> if (isNearWhite) 0.12f else 0.22f
        }

        frostVeilPaint.color = Color.argb(
            (frostVeilAlpha * 255).toInt(),
            Color.red(tintColor),
            Color.green(tintColor),
            Color.blue(tintColor)
        )
        canvas.drawRect(drawBounds, frostVeilPaint)
    }

    fun drawClockLayer(
        canvas: Canvas,
        canvasWidth: Int,
        canvasHeight: Int,
        screenBounds: RectF,
        config: SceneEngineConfig,
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
        val centerX = -canvasWidth * 0.5f + (canvasWidth * 2f) * config.horizontalPos
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
        val density = context.resources.displayMetrics.density
        val glassBr = config.rimBrightness.coerceIn(0f, 1f)
        val userRimWidthPx = (config.rimWidth.coerceIn(0.5f, 8.0f) * density)
        val userRimBlurPx = (config.rimBlur.coerceIn(0f, 12.0f) * density)

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

            val pad = (34f * density + userRimWidthPx + userRimBlurPx) * max(animScale, 1f)
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
                maskGlyphPaint.xfermode = srcInXfermode
                drawComponentText(mCanvas, isHoursComp, maskGlyphPaint)
                maskGlyphPaint.maskFilter = null
                maskGlyphPaint.xfermode = null
                mCanvas.restore()

                val bgShader = getLinearBitmapShader(clearBgBmp)
                val scale = max(canvasWidth.toFloat() / clearBgBmp.width, canvasHeight.toFloat() / clearBgBmp.height)
                val dx = (canvasWidth - clearBgBmp.width * scale) / 2f
                val dy = (canvasHeight - clearBgBmp.height * scale) / 2f

                tempMatrix.reset()
                tempMatrix.postScale(scale, scale)
                tempMatrix.postTranslate(dx, dy)
                bgShader.setLocalMatrix(tempMatrix)

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
                val baseInnerStroke = userRimWidthPx.coerceIn(0.8f * density, 7.5f * density)
                val innerBlur = if (userRimBlurPx > 0.1f) {
                    userRimBlurPx
                } else if (isLiquid) {
                    2.5f * density
                } else {
                    1.0f * density
                }

                if (isLiquid || userRimBlurPx > 0.1f) {
                    innerRimPaint.strokeWidth = (baseInnerStroke * 1.65f).coerceIn(1.2f * density, 12.0f * density)
                    innerRimPaint.maskFilter = BlurMaskFilter(innerBlur, BlurMaskFilter.Blur.NORMAL)
                    innerRimPaint.shader = null
                    innerRimPaint.color = Color.argb((115 + (80 * glassBr).toInt()).coerceIn(90, 210), 255, 255, 255)
                    drawComponentText(canvas, isHoursComp, innerRimPaint)
                }

                innerRimPaint.strokeWidth = baseInnerStroke
                innerRimPaint.maskFilter = null
                innerRimPaint.shader = null
                innerRimPaint.color = Color.argb((155 + (75 * glassBr).toInt()).coerceIn(120, 235), 255, 255, 255)
                drawComponentText(canvas, isHoursComp, innerRimPaint)
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

            val outerStrokeW = (userRimWidthPx * 2.0f).coerceIn(1.0f * density, 16.0f * density)

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
                val gradient = LinearGradient(
                    x, rectTop, x + w, rectBottom,
                    intArrayOf(
                        Color.argb(alphaMain, br, bg, bb),
                        Color.argb(alphaLow, tr, tg, tb),
                        Color.argb(alphaMid, br, bg, bb)
                    ),
                    floatArrayOf(0f, 0.50f, 1f),
                    Shader.TileMode.CLAMP
                )
                strokePaint.shader = gradient

                if (userRimBlurPx > 0.1f) {
                    strokePaint.strokeWidth = outerStrokeW * 1.35f
                    strokePaint.maskFilter = BlurMaskFilter(userRimBlurPx, BlurMaskFilter.Blur.NORMAL)
                    canvas.drawText(text, x, baselineY, strokePaint)
                }

                strokePaint.strokeWidth = outerStrokeW
                strokePaint.maskFilter = null
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

            strokePaint.shader = null
            strokePaint.maskFilter = null

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
        config: SceneEngineConfig,
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

        val effAlpha = (config.dateOpacity * alphaFactor * visibilityFactor).coerceIn(0f, 1f)
        val layerAlpha = (effAlpha * 255).toInt().coerceIn(0, 255)
        if (layerAlpha <= 2) return

        val fontSize = config.dateFontSize * canvasWidth
        val dateText = if (config.dateAllCaps) dateStr.uppercase() else dateStr
        val mode = normalizedDepthMode(config.dateDepthMode)
        val isGlass = mode == "Liquid" || mode == "Acrylic" || mode == "Aero"
        val resolvedTypeface = getTypefaceForFont(config.dateFontFamily, config.customDateFontPath)

        datePaint.apply {
            reset()
            isAntiAlias = true
            color = config.dateColor
            alpha = layerAlpha
            textSize = fontSize
            textAlign = Paint.Align.LEFT
            typeface = resolvedTypeface
            isFakeBoldText = config.dateBold
            if (config.dateShadowEnabled && !isGlass) {
                setShadowLayer(6f, 0f, 2f, Color.argb((125 * effAlpha).toInt(), 0, 0, 0))
            }
        }

        val wDate = datePaint.measureText(dateText)
        val centerX = -canvasWidth * 0.5f + (canvasWidth * 2f) * config.dateHorizontalPos
        val targetBaselineY = (config.dateVerticalPos * canvasHeight) + (fontSize * 0.85f) + offsetY
        val drawX = centerX - (wDate / 2f)

        canvas.save()
        if (scaleFactor != 1f) {
            canvas.scale(scaleFactor, scaleFactor, centerX, targetBaselineY - (fontSize * 0.4f))
        }

        val glassBmp = when (mode) {
            "Liquid" -> sharpGlassBgBitmap ?: blurredBgShaderBitmap
            "Aero" -> ambientMicaBitmap ?: blurredBgShaderBitmap
            else -> blurredBgShaderBitmap
        }

        if (isGlass && backgroundBitmap != null && glassBmp != null) {
            val dateMaskLayer = canvas.saveLayerAlpha(screenBounds, layerAlpha)

            dateMaskPaint.apply {
                reset()
                isAntiAlias = true
                color = Color.WHITE
                alpha = 255
                textSize = fontSize
                textAlign = Paint.Align.LEFT
                typeface = resolvedTypeface
                isFakeBoldText = config.dateBold
            }
            canvas.drawText(dateText, drawX, targetBaselineY, dateMaskPaint)

            val dateBrightness = config.dateRimBrightness.coerceIn(0f, 1f)
            val shader = getLinearBitmapShader(glassBmp)
            val scale = max(canvasWidth.toFloat() / glassBmp.width, canvasHeight.toFloat() / glassBmp.height)
            val dx = (canvasWidth - glassBmp.width * scale) / 2f
            val dy = (canvasHeight - glassBmp.height * scale) / 2f

            tempMatrix.reset()
            tempMatrix.postScale(scale, scale)
            tempMatrix.postTranslate(dx, dy)
            shader.setLocalMatrix(tempMatrix)

            glassShaderPaint.shader = shader
            glassShaderPaint.colorFilter = getOpticalColorFilter(config.dateColor, dateBrightness, mode)
            glassShaderPaint.xfermode = srcInXfermode
            canvas.drawRect(screenBounds, glassShaderPaint)

            glassShaderPaint.shader = null
            glassShaderPaint.colorFilter = null
            glassShaderPaint.xfermode = null

            val isNearWhite = Color.red(config.dateColor) > 235 && Color.green(config.dateColor) > 235 && Color.blue(config.dateColor) > 235
            val veilAlpha = if (mode == "Liquid") (if (isNearWhite) 18 else 38) else (if (isNearWhite) 45 else 65)

            frostVeilPaint.color = Color.argb(
                veilAlpha,
                Color.red(config.dateColor),
                Color.green(config.dateColor),
                Color.blue(config.dateColor)
            )
            canvas.drawRect(screenBounds, frostVeilPaint)

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
        cachedGlassSourceBitmap = null
        cachedGlassBitmapShader = null
        cachedColorMatrixFilter = null
        cachedFilterMode = ""
    }
}