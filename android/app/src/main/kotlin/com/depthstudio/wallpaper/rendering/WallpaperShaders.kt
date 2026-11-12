package com.depthstudio.wallpaper.rendering

import android.graphics.RuntimeShader
import android.os.Build
import android.util.Log

class WallpaperShaders {
    companion object {
        private const val TAG = "WallpaperShaders"

        val AGSL_PLAYER_CARD_SHADER = """
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

        val AGSL_CLOCK_CLEAR_SHADER = """
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
    }

    private var cachedPlayerCardShader: RuntimeShader? = null
    private var playerCardShaderFailed: Boolean = false

    private var cachedClockClearShader: RuntimeShader? = null
    private var clockClearShaderFailed: Boolean = false

    fun getPlayerCardShader(): RuntimeShader? {
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

    fun getClockClearShader(): RuntimeShader? {
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
}