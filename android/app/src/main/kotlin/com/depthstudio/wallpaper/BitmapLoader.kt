package com.depthstudio.wallpaper

import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Matrix
import android.media.ExifInterface
import android.util.Log
import java.io.File
import kotlin.math.max

object BitmapLoader {
    private const val TAG = "BitmapLoader"

    fun loadOptimizedBitmap(path: String?, targetWidth: Int, targetHeight: Int): Bitmap? {
        if (path.isNullOrEmpty()) return null
        val file = File(path)
        if (!file.exists()) {
            Log.e(TAG, "File does not exist: $path")
            return null
        }

        return try {
            val options = BitmapFactory.Options().apply {
                inJustDecodeBounds = true
            }
            BitmapFactory.decodeFile(path, options)

            val srcWidth = options.outWidth
            val srcHeight = options.outHeight

            if (srcWidth <= 0 || srcHeight <= 0) {
                Log.e(TAG, "Invalid image dimensions for: $path")
                return null
            }

            val orientation = readExifOrientation(path)
            val isRotated90Or270 = orientation == ExifInterface.ORIENTATION_ROTATE_90 ||
                    orientation == ExifInterface.ORIENTATION_ROTATE_270 ||
                    orientation == ExifInterface.ORIENTATION_TRANSPOSE ||
                    orientation == ExifInterface.ORIENTATION_TRANSVERSE

            val effectiveSrcWidth = if (isRotated90Or270) srcHeight else srcWidth
            val effectiveSrcHeight = if (isRotated90Or270) srcWidth else srcHeight

            options.inSampleSize = calculateInSampleSize(
                effectiveSrcWidth,
                effectiveSrcHeight,
                targetWidth,
                targetHeight
            )
            options.inJustDecodeBounds = false
            options.inPreferredConfig = Bitmap.Config.ARGB_8888

            val decodedBitmap = BitmapFactory.decodeFile(path, options) ?: return null
            val orientedBitmap = applyExifOrientation(decodedBitmap, orientation)

            val maxTargetDim = max(targetWidth, targetHeight).coerceAtLeast(1)
            val maxDecodedDim = max(orientedBitmap.width, orientedBitmap.height)
            if (maxDecodedDim > maxTargetDim * 1.5f) {
                val scale = (maxTargetDim * 1.25f) / maxDecodedDim.toFloat()
                val scaledW = (orientedBitmap.width * scale).toInt().coerceAtLeast(1)
                val scaledH = (orientedBitmap.height * scale).toInt().coerceAtLeast(1)
                val downscaled = Bitmap.createScaledBitmap(orientedBitmap, scaledW, scaledH, true)
                if (downscaled !== orientedBitmap) {
                    orientedBitmap.recycle()
                }
                downscaled
            } else {
                orientedBitmap
            }
        } catch (e: OutOfMemoryError) {
            Log.e(TAG, "OutOfMemoryError loading bitmap: $path", e)
            null
        } catch (e: Exception) {
            Log.e(TAG, "Error loading bitmap: $path", e)
            null
        }
    }

    private fun readExifOrientation(path: String): Int {
        return try {
            val exif = ExifInterface(path)
            exif.getAttributeInt(
                ExifInterface.TAG_ORIENTATION,
                ExifInterface.ORIENTATION_NORMAL
            )
        } catch (_: Exception) {
            ExifInterface.ORIENTATION_NORMAL
        }
    }

    private fun applyExifOrientation(bitmap: Bitmap, orientation: Int): Bitmap {
        val matrix = Matrix()
        when (orientation) {
            ExifInterface.ORIENTATION_FLIP_HORIZONTAL -> matrix.setScale(-1f, 1f)
            ExifInterface.ORIENTATION_ROTATE_180 -> matrix.setRotate(180f)
            ExifInterface.ORIENTATION_FLIP_VERTICAL -> {
                matrix.setRotate(180f)
                matrix.postScale(-1f, 1f)
            }
            ExifInterface.ORIENTATION_TRANSPOSE -> {
                matrix.setRotate(90f)
                matrix.postScale(-1f, 1f)
            }
            ExifInterface.ORIENTATION_ROTATE_90 -> matrix.setRotate(90f)
            ExifInterface.ORIENTATION_TRANSVERSE -> {
                matrix.setRotate(-90f)
                matrix.postScale(-1f, 1f)
            }
            ExifInterface.ORIENTATION_ROTATE_270 -> matrix.setRotate(-90f)
            else -> return bitmap
        }

        return try {
            val transformed = Bitmap.createBitmap(
                bitmap,
                0,
                0,
                bitmap.width,
                bitmap.height,
                matrix,
                true
            )
            if (transformed !== bitmap) {
                bitmap.recycle()
            }
            transformed
        } catch (_: OutOfMemoryError) {
            bitmap
        }
    }

    private fun calculateInSampleSize(
        srcWidth: Int,
        srcHeight: Int,
        reqWidth: Int,
        reqHeight: Int
    ): Int {
        var inSampleSize = 1
        if (srcWidth > reqWidth * 2 || srcHeight > reqHeight * 2) {
            val halfWidth = srcWidth / 2
            val halfHeight = srcHeight / 2
            while (halfWidth / inSampleSize >= reqWidth || halfHeight / inSampleSize >= reqHeight) {
                inSampleSize *= 2
            }
        }
        return inSampleSize
    }
}