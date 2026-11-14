package com.depthstudio.wallpaper

import android.content.Context
import android.content.pm.ApplicationInfo
import android.util.Log

object AppLogger {
    @Volatile
    private var isDebugBuild: Boolean = false

    fun init(context: Context) {
        val flags = context.applicationInfo?.flags ?: 0
        isDebugBuild = (flags and ApplicationInfo.FLAG_DEBUGGABLE) != 0
    }

    fun d(tag: String, msg: String) {
        if (isDebugBuild) {
            Log.d(tag, msg)
        }
    }

    fun e(tag: String, msg: String, throwable: Throwable? = null) {
        if (isDebugBuild) {
            if (throwable != null) {
                Log.e(tag, msg, throwable)
            } else {
                Log.e(tag, msg)
            }
        }
    }
}