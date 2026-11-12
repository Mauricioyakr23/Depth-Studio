package com.depthstudio.wallpaper

import android.content.ComponentName
import android.content.Context
import android.graphics.Bitmap
import android.graphics.Color
import android.media.MediaMetadata
import android.media.session.MediaController
import android.media.session.MediaSessionManager
import android.media.session.PlaybackState
import android.os.SystemClock
import android.service.notification.NotificationListenerService
import android.service.notification.StatusBarNotification
import android.util.Log
import kotlin.math.abs

object MusicStateHolder {
    @Volatile var isPlaying: Boolean = false
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

    private val listeners = mutableSetOf<() -> Unit>()

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
        for (l in listeners.toList()) {
            l.invoke()
        }
    }
}

class MusicNotificationListener : NotificationListenerService() {

    companion object {
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
            refreshSessions()
        }
    }

    override fun onNotificationRemoved(sbn: StatusBarNotification?) {
        evaluateCurrentMedia()
    }

    fun refreshSessions() {
        synchronized(this) {
            try {
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
                Log.e("MusicListener", "Error refreshing media sessions", e)
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
        val prefs = getSharedPreferences("wallpaper_config", Context.MODE_PRIVATE)
        val targetPackage = prefs.getString("musicTargetPackage", "all") ?: "all"

        for (c in activeControllers) {
            val state = c.playbackState?.state
            val isActive = state == PlaybackState.STATE_PLAYING || state == PlaybackState.STATE_BUFFERING
            val pkgMatches = targetPackage == "all" || c.packageName.contains(targetPackage, ignoreCase = true)
            if (pkgMatches && isActive) return c
        }
        for (c in activeControllers) {
            val pkgMatches = targetPackage == "all" || c.packageName.contains(targetPackage, ignoreCase = true)
            if (pkgMatches) return c
        }
        return activeControllers.firstOrNull()
    }

    private fun computeBitmapSignature(bmp: Bitmap): Int {
        val w = bmp.width
        val h = bmp.height
        if (w <= 0 || h <= 0) return 0
        var hash = (w * 31) + h
        try {
            hash = hash * 31 + bmp.getPixel(w / 2, h / 2)
            hash = hash * 31 + bmp.getPixel(w / 4, h / 4)
            hash = hash * 31 + bmp.getPixel((w * 3) / 4, (h * 3) / 4)
            hash = hash * 31 + bmp.getPixel(w / 4, (h * 3) / 4)
            hash = hash * 31 + bmp.getPixel((w * 3) / 4, h / 4)
        } catch (_: Exception) {}
        return hash
    }

    private fun replaceAlbumArt(small: Bitmap, hiRes: Bitmap) {
        MusicStateHolder.albumArt?.let { if (it !== small && !it.isRecycled) it.recycle() }
        MusicStateHolder.highResArt?.let { if (it !== hiRes && !it.isRecycled) it.recycle() }
        MusicStateHolder.albumArt = small
        MusicStateHolder.highResArt = hiRes
    }

    private fun clearAlbumArt() {
        MusicStateHolder.albumArt?.let { if (!it.isRecycled) it.recycle() }
        MusicStateHolder.highResArt?.let { if (!it.isRecycled) it.recycle() }
        MusicStateHolder.albumArt = null
        MusicStateHolder.highResArt = null
    }

    private fun evaluateCurrentMedia() {        val prefs = getSharedPreferences("wallpaper_config", Context.MODE_PRIVATE)
        val musicEnabled = prefs.getBoolean("musicModeEnabled", true)
        val targetPackage = prefs.getString("musicTargetPackage", "all") ?: "all"

        if (!musicEnabled) {
            if (MusicStateHolder.isPlaying || MusicStateHolder.albumArt != null || MusicStateHolder.trackId.isNotEmpty()) {
                MusicStateHolder.isPlaying = false
                clearAlbumArt()
                MusicStateHolder.trackId = ""
                lastArtSignature = 0
                MusicStateHolder.notifyUpdate()
            }
            return
        }

        var playingController: MediaController? = null
        for (c in activeControllers) {
            val state = c.playbackState?.state
            val isActiveState = state == PlaybackState.STATE_PLAYING || state == PlaybackState.STATE_BUFFERING
            val pkgMatches = targetPackage == "all" || c.packageName.contains(targetPackage, ignoreCase = true)
            if (pkgMatches && isActiveState) {
                playingController = c
                break
            }
        }

        if (playingController == null) {
            if (MusicStateHolder.isPlaying) {
                MusicStateHolder.isPlaying = false
                MusicStateHolder.notifyUpdate()
            }
            return
        }

        val pbState = playingController.playbackState
        MusicStateHolder.positionMs = (pbState?.position ?: 0L).coerceAtLeast(0L)
        MusicStateHolder.lastPositionUpdateElapsedMs = if ((pbState?.lastPositionUpdateTime ?: 0L) > 0L) {
            pbState!!.lastPositionUpdateTime
        } else {
            SystemClock.elapsedRealtime()
        }
        MusicStateHolder.playbackSpeed = pbState?.playbackSpeed ?: 1f

        val meta = playingController.metadata
        val title = meta?.getString(MediaMetadata.METADATA_KEY_TITLE)
            ?: meta?.getString(MediaMetadata.METADATA_KEY_DISPLAY_TITLE)
            ?: "Apple Music"
        val artist = meta?.getString(MediaMetadata.METADATA_KEY_ARTIST)
            ?: meta?.getString(MediaMetadata.METADATA_KEY_ALBUM_ARTIST)
            ?: meta?.getString(MediaMetadata.METADATA_KEY_AUTHOR)
            ?: ""
        val album = meta?.getString(MediaMetadata.METADATA_KEY_ALBUM) ?: ""
        val duration = meta?.getLong(MediaMetadata.METADATA_KEY_DURATION) ?: 0L

        MusicStateHolder.title = title
        MusicStateHolder.artist = artist
        MusicStateHolder.durationMs = duration.coerceAtLeast(0L)

        val newTrackId = "$title|$artist|$album|${playingController.packageName}"

        val rawArt = meta?.getBitmap(MediaMetadata.METADATA_KEY_ALBUM_ART)
            ?: meta?.getBitmap(MediaMetadata.METADATA_KEY_ART)
            ?: meta?.getBitmap(MediaMetadata.METADATA_KEY_DISPLAY_ICON)

        val newSig = if (rawArt != null) computeBitmapSignature(rawArt) else 0
        val trackChanged = newTrackId != MusicStateHolder.trackId ||
                (rawArt != null && MusicStateHolder.albumArt == null)
        val artChanged = rawArt != null && newSig != 0 && newSig != lastArtSignature

        if (rawArt != null && (trackChanged || artChanged)) {
            try {
                val safeCopy = rawArt.copy(Bitmap.Config.ARGB_8888, false)

                val targetHiRes = 640
                val hiRes = if (safeCopy.width > targetHiRes || safeCopy.height > targetHiRes) {
                    Bitmap.createScaledBitmap(safeCopy, targetHiRes, targetHiRes, true)
                } else {
                    safeCopy
                }

                val smallArt = Bitmap.createScaledBitmap(safeCopy, 160, 160, true)
                if (safeCopy !== rawArt && safeCopy !== hiRes && safeCopy !== smallArt) {
                    safeCopy.recycle()
                }

                extractVibrantOrbPalette(smallArt)

                replaceAlbumArt(smallArt, hiRes)
                MusicStateHolder.trackId = newTrackId
                lastArtSignature = newSig
            } catch (e: Exception) {
                Log.e("MusicListener", "Error processing album art", e)
            }
        }

        val wasPlaying = MusicStateHolder.isPlaying
        MusicStateHolder.isPlaying = MusicStateHolder.albumArt != null

        if (trackChanged || artChanged || !wasPlaying) {
            MusicStateHolder.notifyUpdate()
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

            val maxCh = maxOf(r, g, b)
            val minCh = minOf(r, g, b)
            val channelSpread = maxCh - minCh

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
