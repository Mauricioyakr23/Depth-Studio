package com.depthstudio.wallpaper

import android.app.KeyguardManager
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.SharedPreferences
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Paint
import android.graphics.RectF
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.os.SystemClock
import android.service.wallpaper.WallpaperService
import android.view.Choreographer
import android.view.SurfaceHolder
import com.depthstudio.wallpaper.rendering.ClockAndDateRenderer
import com.depthstudio.wallpaper.rendering.GlassBitmapProcessor
import com.depthstudio.wallpaper.rendering.MusicOverlayRenderer
import com.depthstudio.wallpaper.rendering.WallpaperShaders
import java.text.SimpleDateFormat
import java.util.Calendar
import java.util.Date
import java.util.Locale
import kotlin.math.abs
import kotlin.math.max
import kotlin.math.min

class LiveSceneWallpaperService : WallpaperService() {

    override fun onCreateEngine(): Engine {
        return LiveSceneEngine()
    }

    inner class LiveSceneEngine : Engine(), SharedPreferences.OnSharedPreferenceChangeListener {
        private val TAG = "LiveSceneEngine"

        private val shaders = WallpaperShaders()
        private lateinit var clockAndDateRenderer: ClockAndDateRenderer
        private lateinit var musicOverlayRenderer: MusicOverlayRenderer

        private var backgroundBitmap: Bitmap? = null
        private var sharpGlassBgBitmap: Bitmap? = null
        private var blurredBgShaderBitmap: Bitmap? = null
        private var ambientMicaBitmap: Bitmap? = null
        private var foregroundBitmap: Bitmap? = null

        private lateinit var config: SceneEngineConfig

        private var musicTransition: Float = 0f
        private var musicTransitionTarget: Float = 0f
        private var animProgress: Float = 1.0f
        private var animTarget: Float = 1.0f
        private var isVSyncLoopRunning: Boolean = false
        private var lastFrameUptimeMs: Long = 0L
        private var lastMusicIdleDrawMs: Long = 0L
        private var musicStartNanoTime: Long = System.nanoTime()

        private val fgPaint = Paint(Paint.FILTER_BITMAP_FLAG or Paint.ANTI_ALIAS_FLAG)
        private val dimPaint = Paint(Paint.ANTI_ALIAS_FLAG)
        private val screenBounds = RectF()

        private var cachedMinuteBucket: Long = -1L
        private var cachedUse24Hour: Boolean = true
        private var cachedDateFormatStr: String = ""
        private var cachedHourStr: String = "12"
        private var cachedMinStr: String = "00"
        private var cachedDateStr: String = ""

        private var canvasWidth: Int = 0
        private var canvasHeight: Int = 0
        private var isVisible = false

        private var lastLockedCheck: Long = 0L
        private var lastLockedResult: Boolean = false
        private var hasBeenVisible: Boolean = false
        private var hasLoadedConfigOnce: Boolean = false

        private var pendingFullBitmapReload: Boolean = false
        private var pendingMusicStyleReload: Boolean = false

        private val fullReloadKeys = setOf(
            "sceneJson",
            "backgroundAssetPath",
            "subjectAssetPath",
            "customClockFontPath",
            "customDateFontPath"
        )

        private val handler = Handler(Looper.getMainLooper())

        private val musicPauseGraceRunnable = Runnable {
            onMusicStateUpdated()
        }

        private val pendingPrefReloadRunnable = Runnable {
            if (!::config.isInitialized) return@Runnable
            val reloadBitmaps = pendingFullBitmapReload
            val reloadMusic = pendingMusicStyleReload
            pendingFullBitmapReload = false
            pendingMusicStyleReload = false

            cachedMinuteBucket = -1L
            if (reloadBitmaps) {
                loadConfigAndBitmaps()
            } else {
                config = SceneEngineConfig.loadFromStorage(this@LiveSceneWallpaperService)
                clockAndDateRenderer.setupPaints(config, canvasWidth)
                if (reloadMusic) {
                    musicOverlayRenderer.reloadLayoutAndStyle(clockAndDateRenderer)
                }
            }
            hasLoadedConfigOnce = true

            if (reloadMusic) {
                onMusicStateUpdated()
            }

            val target = if (!config.homescreenClock && !isDeviceLocked()) 0f else 1f
            animProgress = target
            animTarget = target
            drawWallpaper()
        }

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
            handler.post { onMusicStateUpdated() }
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
                        handler.removeCallbacks(musicPauseGraceRunnable)
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

        private fun onMusicStateUpdated() {
            if (!::config.isInitialized) return
            lastLockedCheck = 0L
            handler.removeCallbacks(musicPauseGraceRunnable)
            musicOverlayRenderer.syncWithMusicState(canvasWidth, canvasHeight)

            val hasArt = MusicStateHolder.albumArt != null
            val pausedElapsed = if (!MusicStateHolder.isPlaying && MusicStateHolder.pausedSinceElapsedMs > 0L) {
                SystemClock.elapsedRealtime() - MusicStateHolder.pausedSinceElapsedMs
            } else {
                Long.MAX_VALUE
            }
            val withinPauseGrace = !MusicStateHolder.isPlaying && hasArt && pausedElapsed in 0L..19_999L

            if (withinPauseGrace) {
                handler.postDelayed(musicPauseGraceRunnable, (20_000L - pausedElapsed).coerceAtLeast(100L))
            }

            val shouldShowMusic = (MusicStateHolder.isPlaying || withinPauseGrace) &&
                    hasArt &&
                    isDeviceLocked()
            musicTransitionTarget = if (shouldShowMusic) 1f else 0f
            ensureVSyncLoop()
        }

        override fun onCreate(surfaceHolder: SurfaceHolder?) {
            super.onCreate(surfaceHolder)
            setTouchEventsEnabled(true)
            clockAndDateRenderer = ClockAndDateRenderer(this@LiveSceneWallpaperService, shaders)
            musicOverlayRenderer = MusicOverlayRenderer(this@LiveSceneWallpaperService, shaders)
            musicOverlayRenderer.reloadLayoutAndStyle(clockAndDateRenderer)

            musicStartNanoTime = System.nanoTime()
            val prefs = getSharedPreferences(MainActivity.PREFS_NAME, Context.MODE_PRIVATE)
            prefs.registerOnSharedPreferenceChangeListener(this)

            val filter = IntentFilter().apply {
                addAction(Intent.ACTION_USER_PRESENT)
                addAction(Intent.ACTION_SCREEN_ON)
                addAction(Intent.ACTION_SCREEN_OFF)
            }
            registerReceiver(lockStateReceiver, filter)
            MusicStateHolder.addListener(musicUpdateCallback)
            loadConfigAndBitmaps()
            hasLoadedConfigOnce = true
            onMusicStateUpdated()
        }

        override fun onDestroy() {
            super.onDestroy()
            stopVSyncLoop()
            MusicStateHolder.removeListener(musicUpdateCallback)
            val prefs = getSharedPreferences(MainActivity.PREFS_NAME, Context.MODE_PRIVATE)
            prefs.unregisterOnSharedPreferenceChangeListener(this)
            try {
                unregisterReceiver(lockStateReceiver)
            } catch (_: Exception) {}
            handler.removeCallbacks(updateRunnable)
            handler.removeCallbacks(pendingPrefReloadRunnable)
            handler.removeCallbacks(musicPauseGraceRunnable)
            clockAndDateRenderer.release()
            musicOverlayRenderer.release()
            recycleBitmaps()
        }

        override fun onVisibilityChanged(visible: Boolean) {
            this.isVisible = visible
            if (visible) {
                if (!hasLoadedConfigOnce || pendingFullBitmapReload || pendingMusicStyleReload) {
                    handler.removeCallbacks(pendingPrefReloadRunnable)
                    pendingFullBitmapReload = false
                    pendingMusicStyleReload = false
                    loadConfigAndBitmaps()
                    hasLoadedConfigOnce = true
                }

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
                handler.removeCallbacks(musicPauseGraceRunnable)
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
            hasLoadedConfigOnce = true
            val small = MusicStateHolder.albumArt
            val hiRes = MusicStateHolder.highResArt ?: small
            if (small != null && !small.isRecycled && hiRes != null && !hiRes.isRecycled) {
                musicOverlayRenderer.prepareAlbumArtAssets(small, hiRes, width, height)
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
            if (key in fullReloadKeys) {
                pendingFullBitmapReload = true
            }
            if (key.startsWith("music") || key == "use24Hour") {
                pendingMusicStyleReload = true
            }
            handler.removeCallbacks(pendingPrefReloadRunnable)
            handler.postDelayed(pendingPrefReloadRunnable, 60L)
        }

        private fun loadConfigAndBitmaps() {
            val oldConfig = if (::config.isInitialized) config else null
            config = SceneEngineConfig.loadFromStorage(this@LiveSceneWallpaperService)
            musicOverlayRenderer.reloadLayoutAndStyle(clockAndDateRenderer)

            if (canvasWidth > 0 && canvasHeight > 0) {
                val bgChanged = backgroundBitmap == null || oldConfig?.backgroundPath != config.backgroundPath
                val clockMode = clockAndDateRenderer.normalizedDepthMode(config.depthMode)
                val dateMode = clockAndDateRenderer.normalizedDepthMode(config.dateDepthMode)
                val needsGlass = clockMode != "Standard" || dateMode != "Standard"

                val blurChanged = oldConfig?.blurAmount != config.blurAmount ||
                        oldConfig?.depthMode != config.depthMode ||
                        oldConfig?.dateBlurAmount != config.dateBlurAmount ||
                        oldConfig?.dateDepthMode != config.dateDepthMode

                if (bgChanged) {
                    backgroundBitmap?.recycle()
                    val rawBg = BitmapLoader.loadOptimizedBitmap(config.backgroundPath, canvasWidth, canvasHeight)
                    backgroundBitmap = GlassBitmapProcessor.centerCropToScreen(rawBg, canvasWidth, canvasHeight)
                }

                if (needsGlass) {
                    if (bgChanged || blurChanged || blurredBgShaderBitmap == null || sharpGlassBgBitmap == null) {
                        sharpGlassBgBitmap?.recycle()
                        blurredBgShaderBitmap?.recycle()
                        ambientMicaBitmap?.recycle()

                        backgroundBitmap?.let { bg ->
                            val rawBlur = max(
                                if (clockMode != "Standard") config.blurAmount else 1f,
                                if (dateMode != "Standard") config.dateBlurAmount else 1f
                            ).coerceIn(1f, 45f)

                            val lowBlur = (rawBlur * 0.12f).toInt().coerceIn(2, 5)
                            sharpGlassBgBitmap = GlassBitmapProcessor.createOpticalGlassBitmap(
                                bg, canvasWidth, canvasHeight, lowBlur, 1.18f
                            )

                            val activeBlurMode = if (clockMode != "Standard") clockMode else dateMode
                            val medBlur = when (activeBlurMode) {
                                "Acrylic" -> (rawBlur * 1.25f).toInt().coerceIn(18, 36)
                                "Aero" -> (rawBlur * 1.45f).toInt().coerceIn(22, 38)
                                else -> (rawBlur * 0.85f).toInt().coerceIn(12, 26)
                            }
                            val satBoost = if (activeBlurMode == "Acrylic") 1.48f else 1.55f
                            blurredBgShaderBitmap = GlassBitmapProcessor.createOpticalGlassBitmap(
                                bg, canvasWidth, canvasHeight, medBlur, satBoost
                            )

                            ambientMicaBitmap = GlassBitmapProcessor.createAmbientMicaBitmap(
                                bg, canvasWidth, canvasHeight
                            )
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
                    foregroundBitmap = GlassBitmapProcessor.centerCropToScreen(rawFg, canvasWidth, canvasHeight)
                }
            }
            clockAndDateRenderer.setupPaints(config, canvasWidth)
        }

        private fun recycleBitmaps() {
            backgroundBitmap?.recycle(); backgroundBitmap = null
            sharpGlassBgBitmap?.recycle(); sharpGlassBgBitmap = null
            blurredBgShaderBitmap?.recycle(); blurredBgShaderBitmap = null
            ambientMicaBitmap?.recycle(); ambientMicaBitmap = null
            foregroundBitmap?.recycle(); foregroundBitmap = null
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

        private fun updateCachedTimeStrings() {
            val nowMs = System.currentTimeMillis()
            val minuteBucket = nowMs / 60_000L
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
            } catch (_: Exception) {
                try { holder.lockCanvas() } catch (_: Exception) { null }
            } ?: return

            try {
                updateCachedTimeStrings()
                val elapsedSec = ((System.nanoTime() - musicStartNanoTime) / 1_000_000_000.0).toFloat()
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
                        clockAndDateRenderer.drawClockLayer(
                            canvas, canvasWidth, canvasHeight, screenBounds, config,
                            cachedHourStr, cachedMinStr, animProgress,
                            drawHoursBehind, drawMinutesBehind, normalVisibility,
                            sharpGlassBgBitmap, blurredBgShaderBitmap, ambientMicaBitmap
                        )
                    }

                    drawForeground(canvas, normalVisibility)

                    if (drawHoursFront || drawMinutesFront) {
                        clockAndDateRenderer.drawClockLayer(
                            canvas, canvasWidth, canvasHeight, screenBounds, config,
                            cachedHourStr, cachedMinStr, animProgress,
                            drawHoursFront, drawMinutesFront, normalVisibility,
                            sharpGlassBgBitmap, blurredBgShaderBitmap, ambientMicaBitmap
                        )
                    }

                    if (config.showDate) {
                        clockAndDateRenderer.drawDate(
                            canvas, canvasWidth, canvasHeight, screenBounds, config,
                            cachedDateStr, animProgress, normalVisibility,
                            backgroundBitmap, sharpGlassBgBitmap, blurredBgShaderBitmap, ambientMicaBitmap
                        )
                    }
                } else if (!isMusicFullyOpaque) {
                    drawForeground(canvas, normalVisibility)
                }

                if (mTrans > 0.01f) {
                    musicOverlayRenderer.drawMusicExperience(
                        canvas, canvasWidth, canvasHeight, mTrans, elapsedSec,
                        "$cachedHourStr:$cachedMinStr", cachedDateStr
                    )
                }
            } catch (e: Exception) {
                AppLogger.e(TAG, "Error drawing wallpaper", e)
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
                    canvas.drawRect(0f, 0f, canvasWidth.toFloat(), canvasHeight.toFloat(), dimPaint)
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

        private fun scheduleNextUpdate() {
            if (!isVisible) return
            val now = Calendar.getInstance()
            val delay = ((60 - now.get(Calendar.SECOND)) * 1000 - now.get(Calendar.MILLISECOND)).toLong()
            handler.postDelayed(updateRunnable, if (delay < 100L) 60000L else delay)
        }
    }
}
