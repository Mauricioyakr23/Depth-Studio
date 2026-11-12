package com.depthstudio.wallpaper

import android.app.KeyguardManager
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.SharedPreferences
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
import android.graphics.PorterDuff
import android.graphics.PorterDuffXfermode
import android.graphics.RadialGradient
import android.graphics.Rect
import android.graphics.RectF
import android.graphics.RuntimeShader
import android.graphics.Shader
import android.graphics.Typeface
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.os.SystemClock
import android.service.wallpaper.WallpaperService
import android.text.TextPaint
import android.text.TextUtils
import android.util.Log
import android.view.Choreographer
import android.view.MotionEvent
import android.view.SurfaceHolder
import java.io.File
import java.io.FileOutputStream
import java.text.SimpleDateFormat
import java.util.Calendar
import java.util.Date
import java.util.Locale
import kotlin.math.abs
import kotlin.math.cos
import kotlin.math.max
import kotlin.math.min
import kotlin.math.sin

class DepthWallpaperService : WallpaperService() {

    override fun onCreateEngine(): Engine {
        return DepthWallpaperEngine()
    }

    inner class DepthWallpaperEngine : Engine(), SharedPreferences.OnSharedPreferenceChangeListener {
        private val TAG = "DepthWallpaperEngine"

        private val AGSL_PLAYER_CARD_SHADER = """
            uniform shader uLiveBg;
            uniform float2 uBgScale;
            uniform float2 uCardCenter;
            uniform float2 uCardHalfSize;
            uniform float uCornerRadius;

            float sdRoundBox(float2 p, float2 b, float r) {
                float2 q = abs(p) - b + r;
                return min(max(q.x, q.y), 0.0) + length(max(q, 0.0)) - r;
            }

            half4 main(float2 coord) {
                float2 p = coord - uCardCenter;
                float dist = sdRoundBox(p, uCardHalfSize, uCornerRadius);
                
                float2 eps = float2(1.5, 0.0);
                float2 normal = normalize(float2(
                    sdRoundBox(p + eps.xy, uCardHalfSize, uCornerRadius) - sdRoundBox(p - eps.xy, uCardHalfSize, uCornerRadius),
                    sdRoundBox(p + eps.yx, uCardHalfSize, uCornerRadius) - sdRoundBox(p - eps.yx, uCardHalfSize, uCornerRadius)
                ) + float2(0.0001));

                float rimWidth = 34.0;
                float edgeFactor = clamp(1.0 + dist / rimWidth, 0.0, 1.0);
                float lensCurve = pow(edgeFactor, 2.6);

                float2 refractOffset = -normal * (lensCurve * 38.0);
                float2 sampleCoord = coord + refractOffset;

                float2 ca = normal * (lensCurve * 3.2);

                float blurStep = 2.2;
                float3 colR = (
                    uLiveBg.eval((sampleCoord + ca) * uBgScale).rgb * 2.0 +
                    uLiveBg.eval((sampleCoord + ca + float2(blurStep, blurStep)) * uBgScale).rgb +
                    uLiveBg.eval((sampleCoord + ca + float2(-blurStep, -blurStep)) * uBgScale).rgb
                ) * 0.25;

                float3 colG = (
                    uLiveBg.eval(sampleCoord * uBgScale).rgb * 2.0 +
                    uLiveBg.eval((sampleCoord + float2(blurStep, -blurStep)) * uBgScale).rgb +
                    uLiveBg.eval((sampleCoord + float2(-blurStep, blurStep)) * uBgScale).rgb
                ) * 0.25;

                float3 colB = (
                    uLiveBg.eval((sampleCoord - ca) * uBgScale).rgb * 2.0 +
                    uLiveBg.eval((sampleCoord - ca + float2(-blurStep, 0.0)) * uBgScale).rgb +
                    uLiveBg.eval((sampleCoord - ca + float2(blurStep, 0.0)) * uBgScale).rgb
                ) * 0.25;

                float3 glass = float3(colR.r, colG.g, colB.b);

                float luma = dot(glass, float3(0.2126, 0.7152, 0.0722));
                glass = clamp(mix(float3(luma), glass, 1.25), 0.0, 1.0);

                float lightDir = dot(normal, normalize(float2(-0.55, -0.83)));
                float innerShadow = smoothstep(0.35, 1.0, edgeFactor) * clamp(-lightDir, 0.0, 1.0) * 0.14;
                glass -= float3(innerShadow);

                float rimHighlight = smoothstep(0.55, 1.0, edgeFactor) * (0.35 + 0.65 * clamp(lightDir, 0.0, 1.0));
                glass += float3(0.32 * rimHighlight);

                float outerHairline = smoothstep(-2.5, 0.0, dist);
                glass += float3(0.24 * outerHairline * (0.5 + 0.5 * lightDir));

                return half4(clamp(glass, 0.0, 1.0), 1.0);
            }
        """.trimIndent()

        private var cachedPlayerCardShader: RuntimeShader? = null
        private var playerCardShaderFailed: Boolean = false

        private val AGSL_CLOCK_CLEAR_SHADER = """
            uniform shader uBg;
            uniform shader uGlyphMask;
            uniform float2 uMaskOffset;
            uniform float3 uTint;
            uniform float uTintStrength;
            uniform float uBrightness;

            half4 main(float2 coord) {
                float2 maskCoord = coord - uMaskOffset;
                float centerAlpha = uGlyphMask.eval(maskCoord).a;
                if (centerAlpha <= 0.005) return half4(0.0);

                float step = 5.5;
                float aL = uGlyphMask.eval(maskCoord + float2(-step, 0.0)).a;
                float aR = uGlyphMask.eval(maskCoord + float2( step, 0.0)).a;
                float aU = uGlyphMask.eval(maskCoord + float2(0.0, -step)).a;
                float aD = uGlyphMask.eval(maskCoord + float2(0.0,  step)).a;

                float avgRing = (aL + aR + aU + aD) * 0.25;
                float edgeLens = clamp((1.0 - avgRing) * 2.2, 0.0, 1.0);
                float2 normal = normalize(float2(aL - aR, aU - aD) + float2(0.0001));

                float2 refractPos = coord - normal * (edgeLens * 22.0);
                float2 ca = normal * (edgeLens * 2.4);

                half4 cR = uBg.eval(refractPos + ca);
                half4 cG = uBg.eval(refractPos);
                half4 cB = uBg.eval(refractPos - ca);
                float3 glass = float3(cR.r, cG.g, cB.b);

                float luma = dot(glass, float3(0.2126, 0.7152, 0.0722));
                glass = clamp(mix(float3(luma), glass, 1.30), 0.0, 1.0);
                glass = mix(glass, uTint, uTintStrength);

                float lightDir = dot(normal, normalize(float2(-0.5, -0.85)));
                float rimSpec = pow(edgeLens, 1.6) * (0.35 + 0.65 * clamp(lightDir, 0.0, 1.0));
                glass += float3(rimSpec * (0.28 + 0.25 * uBrightness));

                return half4(clamp(glass, 0.0, 1.0) * centerAlpha, centerAlpha);
            }
        """.trimIndent()

        private var cachedClockClearShader: RuntimeShader? = null
        private var clockClearShaderFailed: Boolean = false
        private var backgroundBitmap: Bitmap? = null
        private var sharpGlassBgBitmap: Bitmap? = null
        private var blurredBgShaderBitmap: Bitmap? = null
        private var ambientMicaBitmap: Bitmap? = null
        private var foregroundBitmap: Bitmap? = null

        private var glyphMaskBitmap: Bitmap? = null
        private var glyphMaskCanvas: Canvas? = null
        private var glyphMaskShader: BitmapShader? = null
        private var lastMaskStateKey: String = ""

        private lateinit var config: WallpaperConfig

        private var musicBlurredCoverBg: Bitmap? = null
        private var musicOrbTextures = arrayOfNulls<Bitmap>(4)
        private var musicLiveBufferBitmap: Bitmap? = null
        private var musicLiveBufferCanvas: Canvas? = null
        private var musicLiveBufferShader: BitmapShader? = null

        private var musicCoverBitmap: Bitmap? = null
        private var musicCoverShader: BitmapShader? = null
        private val coverShaderMatrix = Matrix()
        private val bgPanMatrix = Matrix()
        private val orbDrawMatrix = Matrix()
        private val liveBufferScaleMatrix = Matrix()

        private var lastProcessedTrackId: String = ""

        private var musicTransition: Float = 0f
        private var musicTransitionTarget: Float = 0f
        private var animProgress: Float = 1.0f
        private var animTarget: Float = 1.0f
        private var isVSyncLoopRunning: Boolean = false
        private var lastFrameUptimeMs: Long = 0L
        private var lastMusicIdleDrawMs: Long = 0L
        private var musicStartNanoTime: Long = System.nanoTime()

        private var currentDynamicHourColor: Int = Color.WHITE
        private var currentDynamicMinColor: Int = Color.parseColor("#64D2FF")
        private var currentDynamicVibrantColor: Int = Color.parseColor("#FF9F0A")
        private var currentDynamicFourthColor: Int = Color.parseColor("#BF5AF2")
        private var currentDynamicDarkColor: Int = Color.parseColor("#141418")

        private val bitmapDrawPaint = Paint(Paint.FILTER_BITMAP_FLAG or Paint.DITHER_FLAG or Paint.ANTI_ALIAS_FLAG)
        private val orbAddPaint = Paint(Paint.FILTER_BITMAP_FLAG or Paint.DITHER_FLAG or Paint.ANTI_ALIAS_FLAG).apply {
            xfermode = PorterDuffXfermode(PorterDuff.Mode.SCREEN)
        }
        private val orbNormalPaint = Paint(Paint.FILTER_BITMAP_FLAG or Paint.DITHER_FLAG or Paint.ANTI_ALIAS_FLAG)
        private val fgPaint = Paint(Paint.FILTER_BITMAP_FLAG or Paint.ANTI_ALIAS_FLAG)
        private val dimPaint = Paint(Paint.ANTI_ALIAS_FLAG)
        private val darkOverlayPaint = Paint(Paint.ANTI_ALIAS_FLAG)

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
        private val musicHeaderClockPaint = Paint(Paint.ANTI_ALIAS_FLAG)
        private val musicHeaderDatePaint = Paint(Paint.ANTI_ALIAS_FLAG)
        private val punchOutPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            style = Paint.Style.FILL
            color = Color.BLACK
            xfermode = PorterDuffXfermode(PorterDuff.Mode.DST_OUT)
        }

        private val cardShadowPaint = Paint(Paint.ANTI_ALIAS_FLAG)
        private val coverPaint = Paint(Paint.ANTI_ALIAS_FLAG or Paint.FILTER_BITMAP_FLAG)
        private val borderPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            style = Paint.Style.STROKE
        }
        private val uiFillPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            style = Paint.Style.FILL
        }
        private val uiStrokePaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            style = Paint.Style.STROKE
            strokeCap = Paint.Cap.ROUND
            strokeJoin = Paint.Join.ROUND
        }
        private val titleTextPaint = TextPaint(Paint.ANTI_ALIAS_FLAG)
        private val subTextPaint = TextPaint(Paint.ANTI_ALIAS_FLAG)
        private val timeSmallPaint = TextPaint(Paint.ANTI_ALIAS_FLAG)
        private val progressClipPath = Path()

        private val tempGlyphBounds = Rect()
        private val tempCompBounds = RectF()
        private val screenBounds = RectF()

        private var cachedMinuteBucket: Long = -1L
        private var cachedUse24Hour: Boolean = true
        private var cachedDateFormatStr: String = ""
        private var cachedHourStr: String = "12"
        private var cachedMinStr: String = "00"
        private var cachedDateStr: String = ""

        private val typefaceCache = mutableMapOf<String, Typeface>()

        private var canvasWidth: Int = 0
        private var canvasHeight: Int = 0
        private var isVisible = false

        private var lastLockedCheck: Long = 0L
        private var lastLockedResult: Boolean = false
        private var hasBeenVisible: Boolean = false

        private val fullReloadKeys = setOf(
            "backgroundPath", "foregroundPath", "blurAmount", "depthMode",
            "fontFamily", "fontSize", "letterSpacing", "rimWidth", "rimBlur"
        )

        private val handler = Handler(Looper.getMainLooper())

        private val updateRunnable = object : Runnable {
            override fun run() {
                drawWallpaper()
                if (isVisible) scheduleNextUpdate()
            }
        }

        private val vsyncFrameCallback = object : Choreographer.FrameCallback {
            override fun doFrame(frameTimeNanos: Long) {
                if (!isVisible) {
                    isVSyncLoopRunning = false
                    return
                }

                val nowMs = SystemClock.uptimeMillis()
                val musicIdle = musicTransition >= 0.995f &&
                        abs(musicTransition - musicTransitionTarget) < 0.002f &&
                        abs(animProgress - animTarget) < 0.002f
                if (musicIdle && (nowMs - lastMusicIdleDrawMs) < 32L) {
                    Choreographer.getInstance().postFrameCallback(this)
                    return
                }
                if (musicIdle) lastMusicIdleDrawMs = nowMs

                val dtSec = if (lastFrameUptimeMs > 0L) {
                    ((nowMs - lastFrameUptimeMs) / 1000f).coerceIn(0.001f, 0.08f)
                } else {
                    0.016f
                }
                lastFrameUptimeMs = nowMs

                if (abs(musicTransition - musicTransitionTarget) > 0.002f) {
                    val step = dtSec / 0.55f
                    musicTransition = if (musicTransition < musicTransitionTarget) {
                        min(musicTransitionTarget, musicTransition + step * (1.35f - 0.7f * musicTransition))
                    } else {
                        max(musicTransitionTarget, musicTransition - step * 1.4f)
                    }
                } else {
                    musicTransition = musicTransitionTarget
                }

                val clockDurSec = if (::config.isInitialized) {
                    (config.clockAnimDuration / 1000f).coerceIn(0.18f, 2.0f)
                } else {
                    0.65f
                }
                if (abs(animProgress - animTarget) > 0.002f) {
                    val step = dtSec / clockDurSec
                    animProgress = if (animProgress < animTarget) {
                        min(animTarget, animProgress + step * (1.4f - 0.7f * animProgress))
                    } else {
                        max(animTarget, animProgress - step * 1.4f)
                    }
                } else {
                    animProgress = animTarget
                }

                drawWallpaper()

                val needsContinuousFrames = musicTransition > 0.002f ||
                        musicTransitionTarget > 0.002f ||
                        abs(musicTransition - musicTransitionTarget) > 0.002f ||
                        abs(animProgress - animTarget) > 0.002f

                if (needsContinuousFrames) {
                    Choreographer.getInstance().postFrameCallback(this)
                } else {
                    isVSyncLoopRunning = false
                    lastFrameUptimeMs = 0L
                    lastMusicIdleDrawMs = 0L
                }
            }
        }

        private val musicUpdateCallback: () -> Unit = {
            handler.post {
                onMusicStateUpdated()
            }
        }

        private val lockStateReceiver = object : BroadcastReceiver() {
            override fun onReceive(context: Context?, intent: Intent?) {
                lastLockedCheck = 0L
                when (intent?.action) {
                    Intent.ACTION_SCREEN_ON -> {
                        if (::config.isInitialized && config.animateOnScreenOn && config.clockAnimStyle != "None") {
                            animProgress = 0f
                            animTarget = 1f
                        } else {
                            animProgress = 1f
                            animTarget = 1f
                        }
                        onMusicStateUpdated()
                        ensureVSyncLoop()
                        scheduleNextUpdate()
                    }
                    Intent.ACTION_USER_PRESENT -> {
                        if (::config.isInitialized) {
                            val target = if (config.homescreenClock) 1f else 0f
                            if (config.animateOnUnlock && config.clockAnimStyle != "None") {
                                animTarget = target
                            } else {
                                animProgress = target
                                animTarget = target
                            }
                        }
                        onMusicStateUpdated()
                        ensureVSyncLoop()
                    }
                    Intent.ACTION_SCREEN_OFF -> {
                        handler.removeCallbacks(updateRunnable)
                        stopVSyncLoop()
                        if (::config.isInitialized && config.animateOnScreenOn && config.clockAnimStyle != "None") {
                            animProgress = 0f
                            animTarget = 0f
                        } else {
                            animProgress = 1f
                            animTarget = 1f
                        }
                    }
                }
            }
        }

        private fun ensureVSyncLoop() {
            if (!isVisible) return
            if (!isVSyncLoopRunning) {
                isVSyncLoopRunning = true
                lastFrameUptimeMs = SystemClock.uptimeMillis()
                Choreographer.getInstance().postFrameCallback(vsyncFrameCallback)
            }
        }

        private fun stopVSyncLoop() {
            if (isVSyncLoopRunning) {
                isVSyncLoopRunning = false
                lastFrameUptimeMs = 0L
                Choreographer.getInstance().removeFrameCallback(vsyncFrameCallback)
            }
        }

        private fun createLinearBitmapShader(bitmap: Bitmap, tileMode: Shader.TileMode): BitmapShader {
            val shader = BitmapShader(bitmap, tileMode, tileMode)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                shader.filterMode = BitmapShader.FILTER_MODE_LINEAR
            }
            return shader
        }

        private fun getPlayerCardShader(): RuntimeShader? {
            if (Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU) return null
            if (playerCardShaderFailed) return null
            if (cachedPlayerCardShader == null) {
                try {
                    cachedPlayerCardShader = RuntimeShader(AGSL_PLAYER_CARD_SHADER)
                } catch (e: Exception) {
                    Log.e(TAG, "AGSL player card shader compilation failed", e)
                    playerCardShaderFailed = true
                    return null
                }
            }
            return cachedPlayerCardShader
        }

        private fun getClockClearShader(): RuntimeShader? {
            if (Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU) return null
            if (clockClearShaderFailed) return null
            if (cachedClockClearShader == null) {
                try {
                    cachedClockClearShader = RuntimeShader(AGSL_CLOCK_CLEAR_SHADER)
                } catch (e: Exception) {
                    Log.e(TAG, "AGSL clock clear shader compilation failed", e)
                    clockClearShaderFailed = true
                    return null
                }
            }
            return cachedClockClearShader
        }

        private fun onMusicStateUpdated() {
            if (!::config.isInitialized) return
            lastLockedCheck = 0L

            if (MusicStateHolder.isPlaying && MusicStateHolder.albumArt != null) {
                currentDynamicHourColor = MusicStateHolder.primaryColor
                currentDynamicMinColor = MusicStateHolder.secondaryColor
                currentDynamicVibrantColor = MusicStateHolder.vibrantColor
                currentDynamicFourthColor = MusicStateHolder.accentFourthColor
                currentDynamicDarkColor = MusicStateHolder.darkColor

                if (MusicStateHolder.trackId != lastProcessedTrackId || musicBlurredCoverBg == null) {
                    prepareAlbumArtAssets(
                        MusicStateHolder.albumArt!!,
                        MusicStateHolder.highResArt ?: MusicStateHolder.albumArt!!
                    )
                    lastProcessedTrackId = MusicStateHolder.trackId
                }
            }

            val shouldShowMusic = MusicStateHolder.isPlaying &&
                    MusicStateHolder.albumArt != null &&
                    isDeviceLocked()
            musicTransitionTarget = if (shouldShowMusic) 1f else 0f
            ensureVSyncLoop()
        }

        private fun createRadialOrbBitmap(color: Int, size: Int = 192): Bitmap {
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

        private fun prepareAlbumArtAssets(smallArt: Bitmap, hiResArt: Bitmap) {
            try {
                val bufW = 180
                val bufH = if (canvasWidth > 0 && canvasHeight > 0) {
                    ((canvasHeight.toFloat() / canvasWidth.toFloat()) * bufW).toInt().coerceAtLeast(180)
                } else {
                    380
                }

                val croppedCover = Bitmap.createBitmap(bufW, bufH, Bitmap.Config.ARGB_8888)
                val ccCanvas = Canvas(croppedCover)
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

                val blurredCover = stackBlurBitmap(croppedCover, 28)
                if (blurredCover != croppedCover) croppedCover.recycle()

                musicBlurredCoverBg?.recycle()
                musicBlurredCoverBg = blurredCover

                val orbColors = intArrayOf(
                    currentDynamicHourColor,
                    currentDynamicMinColor,
                    currentDynamicVibrantColor,
                    currentDynamicFourthColor
                )
                for (i in 0 until 4) {
                    musicOrbTextures[i]?.recycle()
                    musicOrbTextures[i] = createRadialOrbBitmap(orbColors[i], 192)
                }

                if (musicLiveBufferBitmap == null || musicLiveBufferBitmap?.width != bufW || musicLiveBufferBitmap?.height != bufH) {
                    musicLiveBufferBitmap?.recycle()
                    val liveBmp = Bitmap.createBitmap(bufW, bufH, Bitmap.Config.ARGB_8888)
                    musicLiveBufferBitmap = liveBmp
                    musicLiveBufferCanvas = Canvas(liveBmp)
                    musicLiveBufferShader = createLinearBitmapShader(liveBmp, Shader.TileMode.CLAMP)
                }

                val coverCopy = hiResArt.copy(Bitmap.Config.ARGB_8888, false)
                musicCoverBitmap?.recycle()
                musicCoverBitmap = coverCopy
                musicCoverShader = createLinearBitmapShader(coverCopy, Shader.TileMode.CLAMP)
            } catch (e: Exception) {
                Log.e(TAG, "Error preparing album assets", e)
            }
        }

        override fun onCreate(surfaceHolder: SurfaceHolder?) {
            super.onCreate(surfaceHolder)
            setTouchEventsEnabled(true)
            musicStartNanoTime = System.nanoTime()
            val prefs = getSharedPreferences("wallpaper_config", Context.MODE_PRIVATE)
            prefs.registerOnSharedPreferenceChangeListener(this)

            val filter = IntentFilter().apply {
                addAction(Intent.ACTION_USER_PRESENT)
                addAction(Intent.ACTION_SCREEN_ON)
                addAction(Intent.ACTION_SCREEN_OFF)
            }
            registerReceiver(lockStateReceiver, filter)
            MusicStateHolder.addListener(musicUpdateCallback)
            loadConfigAndBitmaps()
            onMusicStateUpdated()
        }

        override fun onDestroy() {
            super.onDestroy()
            stopVSyncLoop()
            MusicStateHolder.removeListener(musicUpdateCallback)
            val prefs = getSharedPreferences("wallpaper_config", Context.MODE_PRIVATE)
            prefs.unregisterOnSharedPreferenceChangeListener(this)
            try {
                unregisterReceiver(lockStateReceiver)
            } catch (_: Exception) {}
            handler.removeCallbacks(updateRunnable)
            typefaceCache.clear()
            recycleBitmaps()
        }

        override fun onTouchEvent(event: MotionEvent?) {
            super.onTouchEvent(event)
        }

        override fun onVisibilityChanged(visible: Boolean) {
            this.isVisible = visible
            if (visible) {
                loadConfigAndBitmaps()

                if (!hasBeenVisible) {
                    val initialTarget = if (!config.homescreenClock && !isDeviceLocked()) 0f else 1f
                    animProgress = initialTarget
                    animTarget = initialTarget
                }
                hasBeenVisible = true

                onMusicStateUpdated()
                drawWallpaper()
                handler.removeCallbacks(updateRunnable)
                scheduleNextUpdate()
                ensureVSyncLoop()
            } else {
                handler.removeCallbacks(updateRunnable)
                stopVSyncLoop()
            }
        }

        override fun onSurfaceChanged(holder: SurfaceHolder?, format: Int, width: Int, height: Int) {
            super.onSurfaceChanged(holder, format, width, height)
            this.canvasWidth = width
            this.canvasHeight = height
            this.screenBounds.set(0f, 0f, width.toFloat(), height.toFloat())
            recycleBitmaps()
            loadConfigAndBitmaps()
            if (MusicStateHolder.albumArt != null) {
                prepareAlbumArtAssets(
                    MusicStateHolder.albumArt!!,
                    MusicStateHolder.highResArt ?: MusicStateHolder.albumArt!!
                )
            }
            drawWallpaper()
            handler.removeCallbacks(updateRunnable)
            scheduleNextUpdate()
            ensureVSyncLoop()
        }

        override fun onSurfaceRedrawNeeded(holder: SurfaceHolder?) {
            super.onSurfaceRedrawNeeded(holder)
            drawWallpaper()
        }

        override fun onSharedPreferenceChanged(sharedPreferences: SharedPreferences?, key: String?) {
            if (key == null) return
            if (key == "musicModeEnabled" || key == "musicTargetPackage") {
                onMusicStateUpdated()
                return
            }
            cachedMinuteBucket = -1L
            lastMaskStateKey = ""
            if (key in fullReloadKeys) {
                loadConfigAndBitmaps()
            } else {
                config = WallpaperConfig.fromSharedPreferences(this@DepthWallpaperService)
                setupPaints()
            }
            val target = if (!config.homescreenClock && !isDeviceLocked()) 0f else 1f
            animProgress = target
            animTarget = target
            drawWallpaper()
        }

        private fun normalizedDepthMode(): String {
            return when (config.depthMode) {
                "Liquid", "Acrylic", "Aero" -> config.depthMode
                else -> "Standard"
            }
        }

        private fun buildOpticalGlassMatrix(tintColor: Int, brightness: Float, mode: String): FloatArray {
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

        private fun centerCropToScreen(src: Bitmap?, targetW: Int, targetH: Int): Bitmap? {
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
            } catch (e: Exception) {
                src
            }
        }

        private fun loadConfigAndBitmaps() {
            val oldConfig = if (::config.isInitialized) config else null
            config = WallpaperConfig.fromSharedPreferences(this@DepthWallpaperService)
            lastMaskStateKey = ""

            if (canvasWidth > 0 && canvasHeight > 0) {
                val bgChanged = backgroundBitmap == null || oldConfig?.backgroundPath != config.backgroundPath
                val blurChanged = oldConfig?.blurAmount != config.blurAmount || oldConfig?.depthMode != config.depthMode
                val mode = normalizedDepthMode()
                val isGlass = mode == "Liquid" || mode == "Acrylic" || mode == "Aero"

                if (bgChanged) {
                    backgroundBitmap?.recycle()
                    val rawBg = BitmapLoader.loadOptimizedBitmap(config.backgroundPath, canvasWidth, canvasHeight)
                    backgroundBitmap = centerCropToScreen(rawBg, canvasWidth, canvasHeight)
                }

                if (isGlass) {
                    if (bgChanged || blurChanged || blurredBgShaderBitmap == null || sharpGlassBgBitmap == null) {
                        sharpGlassBgBitmap?.recycle()
                        blurredBgShaderBitmap?.recycle()
                        ambientMicaBitmap?.recycle()

                        backgroundBitmap?.let { bg ->
                            val rawBlur = config.blurAmount.coerceIn(1f, 45f)

                            val lowBlur = (rawBlur * 0.12f).toInt().coerceIn(2, 5)
                            sharpGlassBgBitmap = createOpticalGlassBitmap(bg, canvasWidth, canvasHeight, lowBlur, 1.18f)

                            val medBlur = when (mode) {
                                "Acrylic" -> (rawBlur * 1.25f).toInt().coerceIn(18, 36)
                                "Aero" -> (rawBlur * 1.45f).toInt().coerceIn(22, 38)
                                else -> (rawBlur * 0.85f).toInt().coerceIn(12, 26)
                            }
                            val satBoost = if (mode == "Acrylic") 1.48f else 1.55f
                            blurredBgShaderBitmap = createOpticalGlassBitmap(bg, canvasWidth, canvasHeight, medBlur, satBoost)

                            ambientMicaBitmap = createAmbientMicaBitmap(bg, canvasWidth, canvasHeight)
                        }
                    }
                } else {
                    sharpGlassBgBitmap?.recycle(); sharpGlassBgBitmap = null
                    blurredBgShaderBitmap?.recycle(); blurredBgShaderBitmap = null
                    ambientMicaBitmap?.recycle(); ambientMicaBitmap = null
                }

                if (foregroundBitmap == null || oldConfig?.foregroundPath != config.foregroundPath) {
                    foregroundBitmap?.recycle()
                    val rawFg = BitmapLoader.loadOptimizedBitmap(config.foregroundPath, canvasWidth, canvasHeight)
                    foregroundBitmap = centerCropToScreen(rawFg, canvasWidth, canvasHeight)
                }
            }
            setupPaints()
        }

        private fun createOpticalGlassBitmap(
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
            } catch (e: Exception) {
                src
            }
        }

        private fun createAmbientMicaBitmap(src: Bitmap, targetW: Int, targetH: Int): Bitmap {
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
            } catch (e: Exception) {
                src
            }
        }

        private fun stackBlurBitmap(sentBitmap: Bitmap, radius: Int): Bitmap {
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

        private fun setupPaints() {
            val tf = getTypefaceForFont(config.fontFamily)
            val sfBold = getTypefaceForFont("SF Pro")
            val sfSemi = getTypefaceForFont("SF Pro")
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

            musicHeaderClockPaint.apply {
                isAntiAlias = true
                typeface = sfBold
                textAlign = Paint.Align.LEFT
                letterSpacing = -0.02f
            }

            musicHeaderDatePaint.apply {
                isAntiAlias = true
                typeface = sfSemi
                textAlign = Paint.Align.LEFT
                letterSpacing = -0.01f
            }

            titleTextPaint.apply {
                isAntiAlias = true
                typeface = sfBold
                color = Color.WHITE
                textAlign = Paint.Align.CENTER
                clearShadowLayer()
            }

            subTextPaint.apply {
                isAntiAlias = true
                typeface = sfSemi
                color = Color.argb(165, 255, 255, 255)
                textAlign = Paint.Align.CENTER
                clearShadowLayer()
            }

            timeSmallPaint.apply {
                isAntiAlias = true
                typeface = sfSemi
                fontFeatureSettings = "tnum"
                color = Color.argb(145, 255, 255, 255)
                clearShadowLayer()
            }
        }

        private fun loadAssetFontSmart(baseFileName: String): Typeface {
            typefaceCache[baseFileName]?.let { return it }

            val assetMgr = applicationContext.assets
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
                        val tempFile = File(applicationContext.cacheDir, "font_${assetPath.substringAfterLast("/")}")
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

        private fun getTypefaceForFont(fontFamily: String): Typeface {
            return try {
                when (fontFamily) {
                    "Display 1" -> loadAssetFontSmart("bigclock")
                    "Display 2" -> loadAssetFontSmart("tall1")
                    "Display 3" -> loadAssetFontSmart("tall3")
                    "Display 4" -> loadAssetFontSmart("tall4.otf")
                    "Display 5" -> loadAssetFontSmart("tall5.otf")
                    "Display 6" -> loadAssetFontSmart("tall7")
                    "Display 7" -> loadAssetFontSmart("tall8")
                    "SF Pro" -> loadAssetFontSmart("SFProDisplay-Bold.otf")
                    "New York" -> loadAssetFontSmart("NewYork-Semibold.otf")
                    else -> loadAssetFontSmart("SFProDisplay-Bold.otf")
                }
            } catch (e: Exception) {
                Typeface.create(Typeface.DEFAULT, Typeface.NORMAL)
            }
        }

        private fun recycleBitmaps() {
            backgroundBitmap?.recycle(); backgroundBitmap = null
            sharpGlassBgBitmap?.recycle(); sharpGlassBgBitmap = null
            blurredBgShaderBitmap?.recycle(); blurredBgShaderBitmap = null
            ambientMicaBitmap?.recycle(); ambientMicaBitmap = null
            foregroundBitmap?.recycle(); foregroundBitmap = null
            glyphMaskBitmap?.recycle(); glyphMaskBitmap = null; glyphMaskCanvas = null; glyphMaskShader = null
            musicBlurredCoverBg?.recycle(); musicBlurredCoverBg = null
            for (i in musicOrbTextures.indices) {
                musicOrbTextures[i]?.recycle()
                musicOrbTextures[i] = null
            }
            musicLiveBufferBitmap?.recycle(); musicLiveBufferBitmap = null; musicLiveBufferCanvas = null; musicLiveBufferShader = null
            musicCoverBitmap?.recycle(); musicCoverBitmap = null; musicCoverShader = null
            lastProcessedTrackId = ""
            lastMaskStateKey = ""
        }

        private fun isDeviceLocked(): Boolean {
            val now = SystemClock.uptimeMillis()
            if (now - lastLockedCheck < 500L) return lastLockedResult
            lastLockedCheck = now
            lastLockedResult = try {
                val km = getSystemService(Context.KEYGUARD_SERVICE) as? KeyguardManager
                km?.isKeyguardLocked == true
            } catch (_: Exception) {
                false
            }
            return lastLockedResult
        }

        private fun currentElapsedSeconds(): Float {
            return ((System.nanoTime() - musicStartNanoTime) / 1_000_000_000.0).toFloat()
        }

        private fun updateAndDrawAppleMusicBackground(canvas: Canvas, alphaFraction: Float, elapsedSec: Float) {
            val baseCover = musicBlurredCoverBg ?: return
            val liveBmp = musicLiveBufferBitmap ?: return
            val liveCanvas = musicLiveBufferCanvas ?: return

            val alphaInt = (alphaFraction.coerceIn(0f, 1f) * 255).toInt()
            if (alphaInt <= 2) return

            val bw = liveBmp.width.toFloat()
            val bh = liveBmp.height.toFloat()
            val t = elapsedSec * 0.85f

            liveCanvas.drawColor(currentDynamicDarkColor)
            val coverScale = 1.12f + 0.05f * sin(t * 0.45f)
            val coverPanX = bw * 0.04f * cos(t * 0.35f)
            val coverPanY = bh * 0.04f * sin(t * 0.28f)

            bgPanMatrix.reset()
            bgPanMatrix.postTranslate(-baseCover.width / 2f, -baseCover.height / 2f)
            bgPanMatrix.postScale(
                (bw / baseCover.width) * coverScale,
                (bh / baseCover.height) * coverScale
            )
            bgPanMatrix.postTranslate(bw / 2f + coverPanX, bh / 2f + coverPanY)
            bitmapDrawPaint.alpha = 255
            liveCanvas.drawBitmap(baseCover, bgPanMatrix, bitmapDrawPaint)

            val isMono = MusicStateHolder.isMonochromeArt
            val orbPaint = if (isMono) orbNormalPaint else orbAddPaint

            for (i in 0 until 5) {
                val orbBmp = musicOrbTextures[i % 4] ?: continue
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

                orbDrawMatrix.reset()
                orbDrawMatrix.postTranslate(-ow / 2f, -oh / 2f)
                orbDrawMatrix.postScale(radiusScale, radiusScale)
                orbDrawMatrix.postTranslate(cx, cy)

                orbPaint.alpha = orbAlpha
                liveCanvas.drawBitmap(orbBmp, orbDrawMatrix, orbPaint)
            }

            liveBufferScaleMatrix.reset()
            liveBufferScaleMatrix.postScale(
                canvasWidth.toFloat() / bw,
                canvasHeight.toFloat() / bh
            )
            bitmapDrawPaint.alpha = alphaInt
            canvas.drawBitmap(liveBmp, liveBufferScaleMatrix, bitmapDrawPaint)
        }

        private fun formatDurationMmSs(ms: Long, prefixMinus: Boolean = false): String {
            val totalSec = (ms.coerceAtLeast(0L) / 1000L).toInt()
            val mins = totalSec / 60
            val secs = totalSec % 60
            val base = String.format(Locale.US, "%d:%02d", mins, secs)
            return if (prefixMinus) "-$base" else base
        }

        private fun renderPlayerCardLiquidGlass(canvas: Canvas, cardRect: RectF, cardCorner: Float) {
            val liveBmp = musicLiveBufferBitmap
            val liveShader = musicLiveBufferShader
            val cardShader = getPlayerCardShader()

            if (cardShader != null && liveBmp != null && liveShader != null) {
                try {
                    cardShader.setInputShader("uLiveBg", liveShader)
                    cardShader.setFloatUniform(
                        "uBgScale",
                        liveBmp.width.toFloat() / max(canvasWidth.toFloat(), 1f),
                        liveBmp.height.toFloat() / max(canvasHeight.toFloat(), 1f)
                    )
                    cardShader.setFloatUniform("uCardCenter", cardRect.centerX(), cardRect.centerY())
                    cardShader.setFloatUniform("uCardHalfSize", cardRect.width() / 2f, cardRect.height() / 2f)
                    cardShader.setFloatUniform("uCornerRadius", cardCorner)

                    uiFillPaint.shader = cardShader
                    uiFillPaint.xfermode = null
                    uiFillPaint.alpha = 255
                    canvas.drawRoundRect(cardRect, cardCorner, cardCorner, uiFillPaint)
                    uiFillPaint.shader = null
                    return
                } catch (e: Exception) {
                    Log.e(TAG, "Player card AGSL failed, using fallback", e)
                    playerCardShaderFailed = true
                }
            }

            uiFillPaint.shader = null
            uiFillPaint.color = Color.argb(118, 30, 30, 35)
            canvas.drawRoundRect(cardRect, cardCorner, cardCorner, uiFillPaint)

            val cardHighlightPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
                shader = LinearGradient(
                    cardRect.left, cardRect.top, cardRect.right, cardRect.bottom,
                    intArrayOf(
                        Color.argb(60, 255, 255, 255),
                        Color.argb(0, 255, 255, 255)
                    ),
                    floatArrayOf(0f, 0.5f),
                    Shader.TileMode.CLAMP
                )
            }
            canvas.drawRoundRect(cardRect, cardCorner, cardCorner, cardHighlightPaint)
        }

        private fun drawIos26MusicPlayerOverlay(canvas: Canvas, mTrans: Float, elapsedSec: Float) {
            if (mTrans <= 0.01f) return
            val coverBmp = musicCoverBitmap ?: return
            val coverShader = musicCoverShader ?: return

            val w = canvasWidth.toFloat()
            val h = canvasHeight.toFloat()
            val density = resources.displayMetrics.density
            val alphaInt = (mTrans.coerceIn(0f, 1f) * 255).toInt()

            val entryScale = 0.92f + 0.08f * mTrans
            val slideOffsetY = (1f - mTrans) * (28f * density)

            val layerSave = if (alphaInt < 254) {
                canvas.saveLayerAlpha(0f, 0f, w, h, alphaInt)
            } else {
                canvas.save()
            }

            val coverSize = (w * 0.85f).coerceAtMost(h * 0.42f)
            val coverLeft = (w - coverSize) / 2f
            val coverTop = h * 0.198f + slideOffsetY
            val coverRect = RectF(coverLeft, coverTop, coverLeft + coverSize, coverTop + coverSize)
            val coverCorner = 20f * density

            val clockText = "$cachedHourStr:$cachedMinStr"
            val dateText = cachedDateStr

            musicHeaderClockPaint.textSize = w * 0.068f
            musicHeaderDatePaint.textSize = w * 0.052f

            val headerTint = blendTowardsWhite(currentDynamicHourColor, 0.82f)
            musicHeaderClockPaint.color = headerTint
            musicHeaderDatePaint.color = Color.argb(
                220,
                Color.red(headerTint),
                Color.green(headerTint),
                Color.blue(headerTint)
            )
            musicHeaderClockPaint.setShadowLayer(6f * density, 0f, 1.5f * density, Color.argb(75, 0, 0, 0))
            musicHeaderDatePaint.setShadowLayer(6f * density, 0f, 1.5f * density, Color.argb(75, 0, 0, 0))

            val clockW = musicHeaderClockPaint.measureText(clockText)
            val dateW = musicHeaderDatePaint.measureText(dateText)
            val headerGap = 13f * density
            val totalHeaderW = clockW + headerGap + dateW
            val headerStartX = (w - totalHeaderW) / 2f
            val headerBaselineY = coverTop - (22f * density)

            canvas.drawText(clockText, headerStartX, headerBaselineY, musicHeaderClockPaint)
            canvas.drawText(dateText, headerStartX + clockW + headerGap, headerBaselineY - (1.5f * density), musicHeaderDatePaint)

            canvas.save()
            canvas.scale(entryScale, entryScale, coverRect.centerX(), coverRect.centerY())

            cardShadowPaint.color = Color.BLACK
            cardShadowPaint.setShadowLayer(
                26f * density,
                0f,
                12f * density,
                Color.argb(165, 0, 0, 0)
            )
            canvas.drawRoundRect(coverRect, coverCorner, coverCorner, cardShadowPaint)
            cardShadowPaint.clearShadowLayer()

            val scaleX = coverSize / max(coverBmp.width.toFloat(), 1f)
            val scaleY = coverSize / max(coverBmp.height.toFloat(), 1f)
            coverShaderMatrix.reset()
            coverShaderMatrix.postScale(scaleX, scaleY)
            coverShaderMatrix.postTranslate(coverLeft, coverTop)
            coverShader.setLocalMatrix(coverShaderMatrix)

            coverPaint.shader = coverShader
            canvas.drawRoundRect(coverRect, coverCorner, coverCorner, coverPaint)

            borderPaint.strokeWidth = 0.85f * density
            borderPaint.shader = null
            borderPaint.color = Color.argb(45, 255, 255, 255)
            canvas.drawRoundRect(coverRect, coverCorner, coverCorner, borderPaint)
            canvas.restore()

            val cardW = coverSize
            val cardH = (h * 0.10f).coerceIn(90f * density, 110f * density) // Más corta por no tener botones
            val cardLeft = (w - cardW) / 2f
            val cardTop = coverRect.bottom + (h * 0.028f)
            val cardRect = RectF(cardLeft, cardTop, cardLeft + cardW, cardTop + cardH)
            val cardCorner = 26f * density

            canvas.save()
            canvas.scale(entryScale, entryScale, cardRect.centerX(), cardRect.centerY())

            cardShadowPaint.color = Color.TRANSPARENT
            cardShadowPaint.setShadowLayer(
                20f * density,
                0f,
                8f * density,
                Color.argb(95, 0, 0, 0)
            )
            canvas.drawRoundRect(cardRect, cardCorner, cardCorner, cardShadowPaint)
            cardShadowPaint.clearShadowLayer()

            renderPlayerCardLiquidGlass(canvas, cardRect, cardCorner)

            borderPaint.maskFilter = null
            borderPaint.strokeWidth = 0.95f * density
            borderPaint.shader = LinearGradient(
                cardRect.left, cardRect.top, cardRect.right, cardRect.bottom,
                intArrayOf(
                    Color.argb(92, 255, 255, 255),
                    Color.argb(28, 255, 255, 255),
                    Color.argb(24, 255, 255, 255),
                    Color.argb(68, 255, 255, 255)
                ),
                floatArrayOf(0f, 0.35f, 0.70f, 1f),
                Shader.TileMode.CLAMP
            )
            canvas.drawRoundRect(cardRect, cardCorner, cardCorner, borderPaint)
            borderPaint.shader = null

            val padX = 22f * density
            val titleY = cardRect.top + cardH * 0.35f
            val artistY = titleY + 17.5f * density

            titleTextPaint.textSize = 15.2f * density
            subTextPaint.textSize = 13.0f * density

            val maxTitleW = cardW - (padX * 4.4f)
            val rawTitle = MusicStateHolder.title.ifEmpty { "Apple Music" }
            val rawArtist = MusicStateHolder.artist.ifEmpty { "En reproducción" }

            val ellipsizedTitle = TextUtils.ellipsize(rawTitle, titleTextPaint, maxTitleW, TextUtils.TruncateAt.END).toString()
            val ellipsizedArtist = TextUtils.ellipsize(rawArtist, subTextPaint, maxTitleW, TextUtils.TruncateAt.END).toString()

            canvas.drawText(ellipsizedTitle, cardRect.centerX(), titleY, titleTextPaint)
            canvas.drawText(ellipsizedArtist, cardRect.centerX(), artistY, subTextPaint)

            val eqRightX = cardRect.right - padX - 2f * density
            val eqCenterY = (titleY + artistY) / 2f - 4.5f * density
            val barSpacing = 3.4f * density
            uiStrokePaint.strokeWidth = 1.8f * density
            uiStrokePaint.color = Color.argb(145, 255, 255, 255)

            for (b in 0 until 5) {
                val bx = eqRightX - (4 - b) * barSpacing
                val wave = if (MusicStateHolder.isPlaying) {
                    0.25f + 0.75f * abs(sin(elapsedSec * (3.4f + b * 0.55f) + b * 1.2f))
                } else {
                    0.20f
                }
                val halfBarH = (1.5f + wave * 5.8f) * density
                canvas.drawLine(bx, eqCenterY - halfBarH, bx, eqCenterY + halfBarH, uiStrokePaint)
            }

            val progY = cardRect.top + cardH * 0.75f
            val durMs = MusicStateHolder.durationMs
            val posMs = MusicStateHolder.getCurrentPositionMs()
            val remMs = (durMs - posMs).coerceAtLeast(0L)
            val progressFrac = if (durMs > 0L) (posMs.toFloat() / durMs.toFloat()).coerceIn(0f, 1f) else 0.0f

            val elapsedText = formatDurationMmSs(posMs, prefixMinus = false)
            val remainText = formatDurationMmSs(remMs, prefixMinus = true)

            timeSmallPaint.textSize = 10.5f * density
            timeSmallPaint.textAlign = Paint.Align.LEFT
            canvas.drawText(elapsedText, cardRect.left + padX, progY + 3.6f * density, timeSmallPaint)

            timeSmallPaint.textAlign = Paint.Align.RIGHT
            canvas.drawText(remainText, cardRect.right - padX, progY + 3.6f * density, timeSmallPaint)

            val timeLeftW = timeSmallPaint.measureText("00:00") + 8f * density
            val timeRightW = timeSmallPaint.measureText("-00:00") + 8f * density
            val barLeft = cardRect.left + padX + timeLeftW
            val barRight = cardRect.right - padX - timeRightW
            val barHeight = 4.6f * density
            val barRadius = barHeight / 2f
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

            canvas.restore()
            canvas.restoreToCount(layerSave)
        }

        private fun updateCachedTimeStrings() {
            val nowMs = System.currentTimeMillis()
            val minuteBucket = nowMs / 1000L
            if (minuteBucket == cachedMinuteBucket &&
                cachedUse24Hour == config.use24Hour &&
                cachedDateFormatStr == config.dateFormat
            ) {
                return
            }
            cachedMinuteBucket = minuteBucket
            cachedUse24Hour = config.use24Hour
            cachedDateFormatStr = config.dateFormat

            val now = Date(nowMs)
            val hourPattern = if (config.use24Hour) "HH" else "hh"
            cachedHourStr = SimpleDateFormat(hourPattern, Locale.getDefault()).format(now)
            cachedMinStr = SimpleDateFormat("mm", Locale.getDefault()).format(now)

            cachedDateStr = try {
                SimpleDateFormat(config.dateFormat, Locale.getDefault()).format(now)
            } catch (_: Exception) {
                SimpleDateFormat("EEE, MMM dd", Locale.getDefault()).format(now)
            }
        }

        private fun drawWallpaper() {
            if (!isVisible || canvasWidth <= 0 || canvasHeight <= 0 || !::config.isInitialized) return

            val holder = surfaceHolder ?: return
            val canvas: Canvas = try {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    holder.lockHardwareCanvas()
                } else {
                    holder.lockCanvas()
                }
            } catch (e: Exception) {
                try { holder.lockCanvas() } catch (_: Exception) { null }
            } ?: return

            try {
                updateCachedTimeStrings()
                val elapsedSec = currentElapsedSeconds()
                val shouldRenderClock = (config.homescreenClock || isDeviceLocked() || abs(animProgress - animTarget) > 0.005f) && animProgress > 0.01f
                val mTrans = musicTransition.coerceIn(0f, 1f)
                val normalVisibility = (1f - mTrans).coerceIn(0f, 1f)
                val isMusicFullyOpaque = mTrans >= 0.99f

                if (!isMusicFullyOpaque) {
                    drawBackground(canvas)
                }

                if (shouldRenderClock && normalVisibility > 0.01f) {
                    val drawHoursBehind = config.depthLayering != "Hours Forward"
                    val drawMinutesBehind = config.depthLayering != "Minutes Forward"
                    val drawHoursFront = config.depthLayering == "Hours Forward"
                    val drawMinutesFront = config.depthLayering == "Minutes Forward"

                    if (drawHoursBehind || drawMinutesBehind) {
                        drawClockLayer(canvas, drawHoursBehind, drawMinutesBehind, normalVisibility)
                    }

                    drawForeground(canvas, normalVisibility)

                    if (drawHoursFront || drawMinutesFront) {
                        drawClockLayer(canvas, drawHoursFront, drawMinutesFront, normalVisibility)
                    }

                    if (config.showDate) {
                        drawDate(canvas, normalVisibility)
                    }
                } else if (!isMusicFullyOpaque) {
                    drawForeground(canvas, normalVisibility)
                }

                if (mTrans > 0.01f) {
                    updateAndDrawAppleMusicBackground(canvas, mTrans, elapsedSec)

                    darkOverlayPaint.color = Color.argb((70 * mTrans).toInt(), 0, 0, 0)
                    canvas.drawRect(0f, 0f, canvasWidth.toFloat(), canvasHeight.toFloat(), darkOverlayPaint)

                    drawIos26MusicPlayerOverlay(canvas, mTrans, elapsedSec)
                }
            } catch (e: Exception) {
                Log.e(TAG, "Error drawing wallpaper", e)
            } finally {
                try {
                    holder.unlockCanvasAndPost(canvas)
                } catch (_: Exception) {}
            }
        }

        private fun drawBackground(canvas: Canvas) {
            val bg = backgroundBitmap
            if (bg != null) {
                canvas.drawBitmap(bg, 0f, 0f, null)
                if (config.backgroundDim > 0.001f) {
                    dimPaint.color = Color.argb(
                        (config.backgroundDim * 255f).toInt().coerceIn(0, 255),
                        0, 0, 0
                    )
                    canvas.drawRect(
                        0f, 0f,
                        canvasWidth.toFloat(), canvasHeight.toFloat(),
                        dimPaint
                    )
                }
            } else {
                canvas.drawColor(Color.BLACK)
            }
        }

        private fun drawForeground(canvas: Canvas, alphaFraction: Float = 1f) {
            val fg = foregroundBitmap ?: return
            val a = (alphaFraction.coerceIn(0f, 1f) * 255).toInt()
            if (a <= 2) return
            if (a >= 254) {
                canvas.drawBitmap(fg, 0f, 0f, null)
            } else {
                fgPaint.alpha = a
                canvas.drawBitmap(fg, 0f, 0f, fgPaint)
            }
        }

        private fun blendTowardsWhite(color: Int, factor: Float): Int {
            val f = factor.coerceIn(0f, 1f)
            val r = (Color.red(color) + (255 - Color.red(color)) * f).toInt()
            val g = (Color.green(color) + (255 - Color.green(color)) * f).toInt()
            val b = (Color.blue(color) + (255 - Color.blue(color)) * f).toInt()
            return Color.rgb(r, g, b)
        }

        private fun renderGlyphOpticalGlass(
            canvas: Canvas,
            drawBounds: RectF,
            tintColor: Int,
            glassBr: Float,
            mode: String,
            density: Float
        ) {
            val fallbackBmp = when (mode) {
                "Liquid" -> sharpGlassBgBitmap ?: blurredBgShaderBitmap
                "Aero" -> ambientMicaBitmap ?: blurredBgShaderBitmap
                else -> blurredBgShaderBitmap
            } ?: return

            val glassMatrix = buildOpticalGlassMatrix(tintColor, glassBr, mode)
            val shader = createLinearBitmapShader(fallbackBmp, Shader.TileMode.CLAMP)

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
            val frostVeilAlpha = if (mode == "Acrylic") (if (isNearWhite) 0.20f else 0.28f)
            else if (mode == "Liquid") (if (isNearWhite) 0.08f else 0.16f)
            else (if (isNearWhite) 0.12f else 0.22f)

            val uniformFrostPaint = Paint(Paint.ANTI_ALIAS_FLAG)
            uniformFrostPaint.xfermode = PorterDuffXfermode(PorterDuff.Mode.SRC_ATOP)
            uniformFrostPaint.color = Color.argb((frostVeilAlpha * 255).toInt(), Color.red(tintColor), Color.green(tintColor), Color.blue(tintColor))
            canvas.drawRect(drawBounds, uniformFrostPaint)
        }

        private fun drawClockLayer(
            canvas: Canvas,
            paintHours: Boolean,
            paintMinutes: Boolean,
            visibilityFactor: Float
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

            val hourStr = cachedHourStr
            val minStr = cachedMinStr
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

            val mode = normalizedDepthMode()
            val isGlass = mode == "Liquid" || mode == "Acrylic" || mode == "Aero"
            val isLiquid = mode == "Liquid"
            val isAcrylic = mode == "Acrylic"
            val density = resources.displayMetrics.density
            val glassBr = config.rimBrightness.coerceIn(0f, 1f)

            fun applyStretchAndAnim(c: Canvas) {
                if (config.stretch != 1f || animScale != 1f) {
                    c.scale(animScale, config.stretch * animScale, centerX, pivotY)
                }
            }

            fun drawComponentText(isHoursComp: Boolean, paintToUse: Paint) {
                if (isHoursComp) {
                    canvas.drawText(hourStr, hourX, hourBaselineY, paintToUse)
                    if (!useVertical && sepStr.isNotEmpty()) {
                        canvas.drawText(sepStr, sepX, hourBaselineY, paintToUse)
                    }
                } else {
                    canvas.drawText(minStr, minX, minBaselineY, paintToUse)
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
                    drawComponentText(isHoursComp, shadowPaint)
                    shadowPaint.clearShadowLayer()
                    drawComponentText(isHoursComp, punchOutPaint)
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
                    drawComponentText(isHoursComp, clockPaint)
                    canvas.restore()
                    canvas.restoreToCount(solidLayer)
                    return
                }

                val glassLayer = canvas.saveLayerAlpha(tempCompBounds, layerAlpha)
                val clearShader = if (isLiquid) getClockClearShader() else null
                val clearBgBmp = sharpGlassBgBitmap ?: blurredBgShaderBitmap

                if (isLiquid && clearShader != null && clearBgBmp != null) {
                    val maskW = tempCompBounds.width().toInt().coerceAtLeast(16)
                    val maskH = tempCompBounds.height().toInt().coerceAtLeast(16)

                    if (glyphMaskBitmap == null || glyphMaskBitmap?.width != maskW || glyphMaskBitmap?.height != maskH) {
                        glyphMaskBitmap?.recycle()
                        val mBmp = Bitmap.createBitmap(maskW, maskH, Bitmap.Config.ARGB_8888)
                        glyphMaskBitmap = mBmp
                        glyphMaskCanvas = Canvas(mBmp)
                        glyphMaskShader = createLinearBitmapShader(mBmp, Shader.TileMode.CLAMP)
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
                    if (isHoursComp) {
                        mCanvas.drawText(hourStr, hourX, hourBaselineY, clockPaint)
                        if (!useVertical && sepStr.isNotEmpty()) {
                            mCanvas.drawText(sepStr, sepX, hourBaselineY, clockPaint)
                        }
                    } else {
                        mCanvas.drawText(minStr, minX, minBaselineY, clockPaint)
                    }

                    maskGlyphPaint.textSize = fontSize
                    maskGlyphPaint.typeface = clockPaint.typeface
                    maskGlyphPaint.letterSpacing = config.letterSpacing
                    maskGlyphPaint.maskFilter = BlurMaskFilter(3.5f * density, BlurMaskFilter.Blur.NORMAL)
                    maskGlyphPaint.xfermode = PorterDuffXfermode(PorterDuff.Mode.SRC_IN)
                    if (isHoursComp) {
                        mCanvas.drawText(hourStr, hourX, hourBaselineY, maskGlyphPaint)
                        if (!useVertical && sepStr.isNotEmpty()) {
                            mCanvas.drawText(sepStr, sepX, hourBaselineY, maskGlyphPaint)
                        }
                    } else {
                        mCanvas.drawText(minStr, minX, minBaselineY, maskGlyphPaint)
                    }
                    maskGlyphPaint.maskFilter = null
                    maskGlyphPaint.xfermode = null
                    mCanvas.restore()

                    val bgShader = createLinearBitmapShader(clearBgBmp, Shader.TileMode.CLAMP)
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
                    drawComponentText(isHoursComp, clockPaint)
                    canvas.restore()

                    renderGlyphOpticalGlass(
                        canvas = canvas,
                        drawBounds = tempCompBounds,
                        tintColor = tintColor,
                        glassBr = glassBr,
                        mode = mode,
                        density = density
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
                        drawComponentText(isHoursComp, innerRimPaint)

                        innerRimPaint.strokeWidth = 1.35f * density
                        innerRimPaint.maskFilter = null
                        innerRimPaint.color = Color.argb((155 + (75 * glassBr).toInt()).coerceIn(120, 235), 255, 255, 255)
                        drawComponentText(isHoursComp, innerRimPaint)
                    } else if (isAcrylic) {
                        innerRimPaint.strokeWidth = 1.25f * density
                        innerRimPaint.maskFilter = null
                        innerRimPaint.shader = null
                        innerRimPaint.color = Color.argb((135 + (65 * glassBr).toInt()).coerceIn(100, 210), 255, 255, 255)
                        drawComponentText(isHoursComp, innerRimPaint)
                    } else {
                        innerRimPaint.strokeWidth = 1.5f * density
                        innerRimPaint.maskFilter = BlurMaskFilter(1.2f * density, BlurMaskFilter.Blur.NORMAL)
                        innerRimPaint.shader = null
                        innerRimPaint.color = Color.argb((125 + (65 * glassBr).toInt()).coerceIn(95, 200), 255, 255, 255)
                        drawComponentText(isHoursComp, innerRimPaint)
                    }
                }
                canvas.restore()

                canvas.restoreToCount(glassLayer)
            }

            if (paintHours) {
                renderIsolatedComponent(true)
            }
            if (paintMinutes) {
                renderIsolatedComponent(false)
            }

            val shouldDrawRim = config.edgeStrokeEnabled && config.rimOpacity > 0.01f
            if (shouldDrawRim) {
                val rimLayer = canvas.saveLayerAlpha(screenBounds, layerAlpha)
                canvas.save()
                applyStretchAndAnim(canvas)

                fun strokePart(text: String, x: Float, baselineY: Float, w: Float, tintColor: Int) {
                    if (text.isEmpty()) return
                    val bright = blendTowardsWhite(tintColor, if (isLiquid) 0.92f else glassBr * 0.85f)
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

                if (paintHours) {
                    drawComponentText(true, punchOutPaint)
                }
                if (paintMinutes) {
                    drawComponentText(false, punchOutPaint)
                }

                canvas.restore()
                canvas.restoreToCount(rimLayer)
            }
        }

        private fun scheduleNextUpdate() {
            if (!isVisible) return
            val now = Calendar.getInstance()
            val delay = ((60 - now.get(Calendar.SECOND)) * 1000 - now.get(Calendar.MILLISECOND)).toLong()
            handler.postDelayed(updateRunnable, if (delay < 100L) 60000L else delay)
        }

        private fun drawDate(canvas: Canvas, visibilityFactor: Float) {
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
            val dateText = if (config.dateAllCaps) cachedDateStr.uppercase() else cachedDateStr

            datePaint.apply {
                color = config.dateColor
                alpha = layerAlpha
                textSize = fontSize
                textAlign = Paint.Align.LEFT
                typeface = getTypefaceForFont(config.dateFontFamily)
                isFakeBoldText = config.dateBold
                setShadowLayer(6f, 0f, 2f, Color.argb((125 * effAlpha).toInt(), 0, 0, 0))
            }

            val wDate = datePaint.measureText(dateText)
            val centerX = (canvasWidth / 2f) + (config.dateHorizontalPos - 0.50f) * canvasWidth * 2f
            val targetBaselineY = (config.dateVerticalPos * canvasHeight) + (fontSize * 0.85f) + offsetY

            canvas.save()
            if (scaleFactor != 1f) {
                canvas.scale(scaleFactor, scaleFactor, centerX, targetBaselineY - (fontSize * 0.4f))
            }

            val dateMaskLayer = canvas.saveLayerAlpha(screenBounds, layerAlpha)

            val maskPaint = Paint(datePaint).apply {
                color = Color.WHITE
                clearShadowLayer()
            }
            canvas.drawText(dateText, centerX - (wDate / 2f), targetBaselineY, maskPaint)

            val bg = backgroundBitmap
            if (bg != null && blurredBgShaderBitmap != null) {
                val glassMatrix = buildOpticalGlassMatrix(config.dateColor, 0.65f, "Acrylic")
                val shader = createLinearBitmapShader(blurredBgShaderBitmap!!, Shader.TileMode.CLAMP)

                val matrix = Matrix()
                val scale = max(canvasWidth.toFloat() / blurredBgShaderBitmap!!.width, canvasHeight.toFloat() / blurredBgShaderBitmap!!.height)
                val dx = (canvasWidth - blurredBgShaderBitmap!!.width * scale) / 2f
                val dy = (canvasHeight - blurredBgShaderBitmap!!.height * scale) / 2f
                matrix.postScale(scale, scale)
                matrix.postTranslate(dx, dy)
                shader.setLocalMatrix(matrix)

                val glassPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
                    this.shader = shader
                    colorFilter = ColorMatrixColorFilter(ColorMatrix(glassMatrix))
                    xfermode = PorterDuffXfermode(PorterDuff.Mode.SRC_IN)
                }
                canvas.drawRect(screenBounds, glassPaint)

                val frostPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
                    xfermode = PorterDuffXfermode(PorterDuff.Mode.SRC_ATOP)
                    color = Color.argb(65, Color.red(config.dateColor), Color.green(config.dateColor), Color.blue(config.dateColor))
                }
                canvas.drawRect(screenBounds, frostPaint)
            } else {
                canvas.drawText(dateText, centerX - (wDate / 2f), targetBaselineY, datePaint)
            }

            canvas.restoreToCount(dateMaskLayer)
            canvas.restore()
        }
    }
}