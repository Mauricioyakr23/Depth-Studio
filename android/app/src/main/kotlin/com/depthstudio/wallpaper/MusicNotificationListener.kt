package com.depthstudio.wallpaper

import android.content.ComponentName
import android.content.Context
import android.content.SharedPreferences
import android.graphics.Bitmap
import android.graphics.Color
import android.media.MediaMetadata
import android.media.session.MediaController
import android.media.session.MediaSessionManager
import android.media.session.PlaybackState
import android.os.SystemClock
import android.service.notification.NotificationListenerService
import android.service.notification.StatusBarNotification
import java.util.Locale
import java.util.concurrent.CopyOnWriteArraySet

object MusicStateHolder {
    @Volatile var isPlaying: Boolean = false
    @Volatile var pausedSinceElapsedMs: Long = 0L
    @Volatile var albumArt: Bitmap? = null
    @Volatile var highResArt: Bitmap? = null
    @Volatile var trackId: String = ""
    @Volatile var title: String = ""
    @Volatile var artist: String = ""
    @Volatile var durationMs: Long = 0L
    @Volatile var positionMs: Long = 0L
    @Volatile var lastPositionUpdateElapsedMs: Long = 0L
    @Volatile var playbackSpeed: Float = 1f

    @Volatile var isMonochromeArt: Boolean = false
    @Volatile var primaryColor: Int = Color.WHITE
    @Volatile var secondaryColor: Int = Color.parseColor("#64D2FF")
    @Volatile var vibrantColor: Int = Color.parseColor("#FF9F0A")
    @Volatile var accentFourthColor: Int = Color.parseColor("#BF5AF2")
    @Volatile var darkColor: Int = Color.parseColor("#141418")

    private val listeners = CopyOnWriteArraySet<() -> Unit>()

    fun getCurrentPositionMs(): Long {
        if (durationMs <= 0L) return 0L
        if (!isPlaying) return positionMs.coerceIn(0L, durationMs)
        val elapsed = (SystemClock.elapsedRealtime() - lastPositionUpdateElapsedMs).coerceAtLeast(0L)
        val speed = if (playbackSpeed > 0f) playbackSpeed else 1f
        val estimated = positionMs + (elapsed * speed).toLong()
        return estimated.coerceIn(0L, durationMs)
    }

    fun addListener(listener: () -> Unit) {
        listeners.add(listener)
    }

    fun removeListener(listener: () -> Unit) {
        listeners.remove(listener)
    }

    fun notifyUpdate() {
        for (l in listeners) {
            try {
                l.invoke()
            } catch (_: Exception) {}
        }
    }
}

class MusicNotificationListener : NotificationListenerService() {

    companion object {
        private const val TAG = "MusicListener"
        private const val MIN_REFRESH_INTERVAL_MS = 1000L
        @Volatile
        private var instance: MusicNotificationListener? = null

        fun refreshNow() {
            instance?.refreshSessions()
        }

        fun togglePlayPause() {
            val ctrl = instance?.findTargetController() ?: return
            val state = ctrl.playbackState?.state
            if (state == PlaybackState.STATE_PLAYING || state == PlaybackState.STATE_BUFFERING) {
                ctrl.transportControls.pause()
            } else {
                ctrl.transportControls.play()
            }
        }

        fun skipToNext() {
            instance?.findTargetController()?.transportControls?.skipToNext()
        }

        fun skipToPrevious() {
            instance?.findTargetController()?.transportControls?.skipToPrevious()
        }

        fun seekTo(posMs: Long) {
            instance?.findTargetController()?.transportControls?.seekTo(posMs.coerceAtLeast(0L))
        }
    }

    private var mediaSessionManager: MediaSessionManager? = null
    private val activeControllers = mutableListOf<MediaController>()
    private var lastArtSignature: Int = 0
    private var lastRefreshElapsedMs: Long = 0L

    private val sessionListener = MediaSessionManager.OnActiveSessionsChangedListener { controllers ->
        registerControllers(controllers)
    }

    private val controllerCallback = object : MediaController.Callback() {
        override fun onPlaybackStateChanged(state: PlaybackState?) {
            evaluateCurrentMedia()
        }

        override fun onMetadataChanged(metadata: MediaMetadata?) {
            evaluateCurrentMedia()
        }
    }

    override fun onListenerConnected() {
        super.onListenerConnected()
        AppLogger.init(applicationContext)
        instance = this
        refreshSessions()
    }

    override fun onListenerDisconnected() {
        super.onListenerDisconnected()
        if (instance == this) instance = null
        try {
            mediaSessionManager?.removeOnActiveSessionsChangedListener(sessionListener)
            clearControllers()
        } catch (_: Exception) {}
    }

    override fun onNotificationPosted(sbn: StatusBarNotification?) {
        if (activeControllers.isEmpty()) {
            val now = SystemClock.elapsedRealtime()
            if (now - lastRefreshElapsedMs >= MIN_REFRESH_INTERVAL_MS) {
                lastRefreshElapsedMs = now
                refreshSessions()
            }
        }
    }

    override fun onNotificationRemoved(sbn: StatusBarNotification?) {
        evaluateCurrentMedia()
    }

    fun refreshSessions() {
        synchronized(this) {
            try {
                lastRefreshElapsedMs = SystemClock.elapsedRealtime()
                if (mediaSessionManager == null) {
                    mediaSessionManager = getSystemService(Context.MEDIA_SESSION_SERVICE) as MediaSessionManager
                }
                val comp = ComponentName(this, MusicNotificationListener::class.java)
                try {
                    mediaSessionManager?.removeOnActiveSessionsChangedListener(sessionListener)
                } catch (_: Exception) {}
                mediaSessionManager?.addOnActiveSessionsChangedListener(sessionListener, comp)
                val controllers = mediaSessionManager?.getActiveSessions(comp)
                registerControllers(controllers)
            } catch (e: Exception) {
                AppLogger.e(TAG, "Error refreshing media sessions", e)
            }
        }
    }

    private fun clearControllers() {
        for (c in activeControllers) {
            try {
                c.unregisterCallback(controllerCallback)
            } catch (_: Exception) {}
        }
        activeControllers.clear()
    }

    private fun registerControllers(controllers: List<MediaController>?) {
        clearControllers()
        if (controllers == null) {
            evaluateCurrentMedia()
            return
        }
        for (c in controllers) {
            try {
                c.registerCallback(controllerCallback)
                activeControllers.add(c)
            } catch (_: Exception) {}
        }
        evaluateCurrentMedia()
    }

    private fun findTargetController(): MediaController? {
        val prefs = getSharedPreferences(MainActivity.PREFS_NAME, Context.MODE_PRIVATE)
        val targetPackage = prefs.getString("musicTargetPackage", "all") ?: "all"

        val playing = activeControllers.firstOrNull { controller ->
            val state = controller.playbackState?.state
            val pkgMatches = targetPackage == "all" || controller.packageName.contains(targetPackage, ignoreCase = true)
            pkgMatches && (state == PlaybackState.STATE_PLAYING || state == PlaybackState.STATE_BUFFERING)
        }
        if (playing != null) return playing

        val paused = activeControllers.filter { controller ->
            val pkgMatches = targetPackage == "all" || controller.packageName.contains(targetPackage, ignoreCase = true)
            pkgMatches && controller.playbackState?.state == PlaybackState.STATE_PAUSED
        }.maxByOrNull { it.playbackState?.lastPositionUpdateTime ?: 0L }
        if (paused != null) return paused

        if (targetPackage != "all") {
            return activeControllers.firstOrNull { controller ->
                controller.packageName.contains(targetPackage, ignoreCase = true)
            }
        }

        return null
    }

    private fun selectBestArtBitmap(meta: MediaMetadata?): Bitmap? {
        if (meta == null) return null
        val candidates = listOfNotNull(
            meta.getBitmap(MediaMetadata.METADATA_KEY_ART),
            meta.getBitmap(MediaMetadata.METADATA_KEY_ALBUM_ART),
            meta.getBitmap(MediaMetadata.METADATA_KEY_DISPLAY_ICON)
        ).filter { !it.isRecycled && it.width > 0 && it.height > 0 }

        return candidates.maxByOrNull { it.width * it.height }
    }

    private fun computeBitmapSignature(bmp: Bitmap): Int {
        if (bmp.isRecycled) return 0
        val w = bmp.width
        val h = bmp.height
        if (w <= 0 || h <= 0) return 0
        var hash = (w * 31) + h
        hash = hash * 31 + bmp.getPixel(w / 2, h / 2)
        hash = hash * 31 + bmp.getPixel(w / 4, h / 4)
        hash = hash * 31 + bmp.getPixel((w * 3) / 4, (h * 3) / 4)
        hash = hash * 31 + bmp.getPixel(w / 4, (h * 3) / 4)
        hash = hash * 31 + bmp.getPixel((w * 3) / 4, h / 4)
        return hash
    }

    private fun replaceAlbumArt(small: Bitmap, hiRes: Bitmap) {
        MusicStateHolder.albumArt = small
        MusicStateHolder.highResArt = hiRes
    }

    private fun clearAlbumArt() {
        MusicStateHolder.albumArt = null
        MusicStateHolder.highResArt = null
    }

    private fun isSpanishLanguage(prefs: SharedPreferences): Boolean {
        val lang = prefs.getString("appLanguage", null) ?: Locale.getDefault().language
        return lang.startsWith("es", ignoreCase = true)
    }

    private fun evaluateCurrentMedia() {
        synchronized(this) {
            val prefs = getSharedPreferences(MainActivity.PREFS_NAME, Context.MODE_PRIVATE)
            val musicEnabled = prefs.getBoolean("musicModeEnabled", true)
            val targetPackage = prefs.getString("musicTargetPackage", "all") ?: "all"

            if (!musicEnabled) {
                if (MusicStateHolder.isPlaying || MusicStateHolder.albumArt != null || MusicStateHolder.trackId.isNotEmpty()) {
                    MusicStateHolder.isPlaying = false
                    MusicStateHolder.pausedSinceElapsedMs = 0L
                    clearAlbumArt()
                    MusicStateHolder.trackId = ""
                    lastArtSignature = 0
                    MusicStateHolder.notifyUpdate()
                }
                return
            }

            var playingController: MediaController? = null
            var pausedController: MediaController? = null

            for (c in activeControllers) {
                val state = c.playbackState?.state
                val pkgMatches = targetPackage == "all" || c.packageName.contains(targetPackage, ignoreCase = true)
                if (!pkgMatches) continue

                if (state == PlaybackState.STATE_PLAYING || state == PlaybackState.STATE_BUFFERING) {
                    playingController = c
                    break
                } else if (state == PlaybackState.STATE_PAUSED && pausedController == null) {
                    pausedController = c
                }
            }

            val activeController = playingController ?: pausedController
            if (activeController == null) {
                if (MusicStateHolder.isPlaying || MusicStateHolder.pausedSinceElapsedMs != 0L) {
                    MusicStateHolder.isPlaying = false
                    MusicStateHolder.pausedSinceElapsedMs = 0L
                    MusicStateHolder.notifyUpdate()
                }
                return
            }

            val isCurrentlyPlaying = playingController != null
            val pbState = activeController.playbackState
            MusicStateHolder.positionMs = (pbState?.position ?: 0L).coerceAtLeast(0L)
            MusicStateHolder.lastPositionUpdateElapsedMs = if ((pbState?.lastPositionUpdateTime ?: 0L) > 0L) {
                pbState!!.lastPositionUpdateTime
            } else {
                SystemClock.elapsedRealtime()
            }
            MusicStateHolder.playbackSpeed = pbState?.playbackSpeed ?: 1f

            val fallbackTitle = if (isSpanishLanguage(prefs)) "Música" else "Music"
            val meta = activeController.metadata
            val title = meta?.getString(MediaMetadata.METADATA_KEY_TITLE)
                ?: meta?.getString(MediaMetadata.METADATA_KEY_DISPLAY_TITLE)
                ?: fallbackTitle
            val artist = meta?.getString(MediaMetadata.METADATA_KEY_ARTIST)
                ?: meta?.getString(MediaMetadata.METADATA_KEY_ALBUM_ARTIST)
                ?: meta?.getString(MediaMetadata.METADATA_KEY_AUTHOR)
                ?: ""
            val album = meta?.getString(MediaMetadata.METADATA_KEY_ALBUM) ?: ""
            val duration = meta?.getLong(MediaMetadata.METADATA_KEY_DURATION) ?: 0L

            MusicStateHolder.title = title
            MusicStateHolder.artist = artist
            MusicStateHolder.durationMs = duration.coerceAtLeast(0L)

            val newTrackId = "$title|$artist|$album|${activeController.packageName}"
            val rawArt = selectBestArtBitmap(meta)

            var trackChanged = false
            var artChanged = false

            if (rawArt != null && !rawArt.isRecycled) {
                try {
                    val newSig = computeBitmapSignature(rawArt)
                    trackChanged = newTrackId != MusicStateHolder.trackId || MusicStateHolder.albumArt == null
                    artChanged = newSig != 0 && newSig != lastArtSignature

                    if (trackChanged || artChanged) {
                        val safeCopy = rawArt.copy(Bitmap.Config.ARGB_8888, false)
                        val targetHiRes = 1200
                        val hiRes = if (safeCopy.width > targetHiRes || safeCopy.height > targetHiRes) {
                            val scale = targetHiRes.toFloat() / maxOf(safeCopy.width, safeCopy.height).toFloat()
                            val dstW = (safeCopy.width * scale).toInt().coerceAtLeast(1)
                            val dstH = (safeCopy.height * scale).toInt().coerceAtLeast(1)
                            Bitmap.createScaledBitmap(safeCopy, dstW, dstH, true)
                        } else {
                            safeCopy
                        }

                        val smallArt = Bitmap.createScaledBitmap(safeCopy, 160, 160, true)

                        extractVibrantOrbPalette(smallArt)
                        replaceAlbumArt(smallArt, hiRes)
                        MusicStateHolder.trackId = newTrackId
                        lastArtSignature = newSig
                    }
                } catch (e: Exception) {
                    AppLogger.e(TAG, "Error processing album art", e)
                }
            }

            val wasPlaying = MusicStateHolder.isPlaying
            val hasValidArt = MusicStateHolder.albumArt != null
            val nextPlaying = isCurrentlyPlaying && hasValidArt

            if (nextPlaying) {
                MusicStateHolder.pausedSinceElapsedMs = 0L
            } else if (wasPlaying && hasValidArt) {
                MusicStateHolder.pausedSinceElapsedMs = SystemClock.elapsedRealtime()
            } else if (!hasValidArt) {
                MusicStateHolder.pausedSinceElapsedMs = 0L
            }

            MusicStateHolder.isPlaying = nextPlaying

            if (trackChanged || artChanged || wasPlaying != nextPlaying) {
                MusicStateHolder.notifyUpdate()
            }
        }
    }

    private fun extractVibrantOrbPalette(bitmap: Bitmap) {
        val w = bitmap.width
        val h = bitmap.height
        val pixels = IntArray(w * h)
        bitmap.getPixels(pixels, 0, w, 0, 0, w, h)

        val domWeight = FloatArray(12)
        val domH = FloatArray(12)
        val domS = FloatArray(12)
        val domV = FloatArray(12)
        val vibWeight = FloatArray(12)
        val vibH = FloatArray(12)
        val vibS = FloatArray(12)
        val vibV = FloatArray(12)

        val hsv = FloatArray(3)
        var totalSampled = 0
        var chromaticPixels = 0

        for (i in pixels.indices step 2) {
            val c = pixels[i]
            val r = Color.red(c)
            val g = Color.green(c)
            val b = Color.blue(c)
            Color.colorToHSV(c, hsv)
            totalSampled++

            val channelSpread = maxOf(r, g, b) - minOf(r, g, b)
            if (hsv[2] < 0.10f || hsv[1] < 0.12f || channelSpread < 18) continue

            chromaticPixels++
            val idx = (hsv[0].toInt() / 30) % 12

            val dW = 1f + hsv[2] * 0.6f
            domWeight[idx] += dW
            domH[idx] += hsv[0] * dW
            domS[idx] += hsv[1] * dW
            domV[idx] += hsv[2] * dW

            val vW = (hsv[1] * hsv[1]) * hsv[2] * 3.0f
            vibWeight[idx] += vW
            vibH[idx] += hsv[0] * vW
            vibS[idx] += hsv[1] * vW
            vibV[idx] += hsv[2] * vW
        }

        val chromaticRatio = if (totalSampled > 0) chromaticPixels.toFloat() / totalSampled.toFloat() else 0f
        if (chromaticRatio < 0.06f) {
            MusicStateHolder.isMonochromeArt = true
            MusicStateHolder.primaryColor = Color.parseColor("#ECEFF4")
            MusicStateHolder.secondaryColor = Color.parseColor("#C2C9D6")
            MusicStateHolder.vibrantColor = Color.parseColor("#8A929E")
            MusicStateHolder.accentFourthColor = Color.parseColor("#D8DEE9")
            MusicStateHolder.darkColor = Color.parseColor("#121316")
            return
        }

        MusicStateHolder.isMonochromeArt = false
        val domSorted = (0 until 12).sortedByDescending { domWeight[it] }
        val vibSorted = (0 until 12).sortedByDescending { vibWeight[it] }

        val dom1 = domSorted[0]
        val dom2 = domSorted.firstOrNull { it != dom1 && domWeight[it] > domWeight[dom1] * 0.18f } ?: dom1
        val vib1 = vibSorted.firstOrNull { vibWeight[it] > 0.5f } ?: dom1
        val vib2 = vibSorted.firstOrNull { it != vib1 && vibWeight[it] > vibWeight[vib1] * 0.12f } ?: dom2

        val hDom1 = if (domWeight[dom1] > 0f) (domH[dom1] / domWeight[dom1]) % 360f else 28f
        val sDom1 = if (domWeight[dom1] > 0f) (domS[dom1] / domWeight[dom1]).coerceIn(0.22f, 0.90f) else 0.60f
        val vDom1 = if (domWeight[dom1] > 0f) (domV[dom1] / domWeight[dom1]).coerceIn(0.35f, 0.95f) else 0.78f

        val hDom2 = if (domWeight[dom2] > 0f) (domH[dom2] / domWeight[dom2]) % 360f else hDom1
        val sDom2 = if (domWeight[dom2] > 0f) (domS[dom2] / domWeight[dom2]).coerceIn(0.22f, 0.88f) else sDom1
        val vDom2 = if (domWeight[dom2] > 0f) (domV[dom2] / domWeight[dom2]).coerceIn(0.32f, 0.92f) else vDom1

        val hVib1 = if (vibWeight[vib1] > 0f) (vibH[vib1] / vibWeight[vib1]) % 360f else hDom1
        val sVib1 = if (vibWeight[vib1] > 0f) (vibS[vib1] / vibWeight[vib1]).coerceIn(0.45f, 0.98f) else sDom1
        val vVib1 = if (vibWeight[vib1] > 0f) (vibV[vib1] / vibWeight[vib1]).coerceIn(0.65f, 0.98f) else 0.88f

        val hVib2 = if (vibWeight[vib2] > 0f) (vibH[vib2] / vibWeight[vib2]) % 360f else hDom2
        val sVib2 = if (vibWeight[vib2] > 0f) (vibS[vib2] / vibWeight[vib2]).coerceIn(0.45f, 0.96f) else sDom2

        MusicStateHolder.primaryColor = Color.HSVToColor(
            floatArrayOf(hDom1, (sDom1 * 1.05f).coerceIn(0.25f, 0.88f), (vDom1 * 1.08f).coerceIn(0.55f, 0.94f))
        )
        MusicStateHolder.secondaryColor = Color.HSVToColor(
            floatArrayOf(hDom2, (sDom2 * 1.02f).coerceIn(0.24f, 0.85f), (vDom2 * 0.92f).coerceIn(0.42f, 0.86f))
        )
        MusicStateHolder.vibrantColor = Color.HSVToColor(
            floatArrayOf(hVib1, (sVib1 * 1.18f).coerceIn(0.55f, 0.98f), (vVib1 * 1.10f).coerceIn(0.75f, 0.98f))
        )
        MusicStateHolder.accentFourthColor = Color.HSVToColor(
            floatArrayOf(hVib2, (sVib2 * 1.12f).coerceIn(0.50f, 0.94f), 0.92f)
        )
        MusicStateHolder.darkColor = Color.HSVToColor(
            floatArrayOf(hDom1, (sDom1 * 0.85f).coerceIn(0.25f, 0.78f), 0.20f)
        )
    }
}