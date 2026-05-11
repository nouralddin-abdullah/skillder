# ──────────────────────────────────────────────────────────────────────────
# Media3 LogSessionId crash workaround (Android < 12 / API < 31).
#
# Source: https://github.com/androidx/media/issues/2535
#
# R8's horizontal class merging fuses a Media3 transformer factory class
# (which references android.media.metrics.LogSessionId, API 31+) with
# another class that's reachable on older Android. The merged class then
# fails to load on API <= 30 with:
#   java.lang.NoClassDefFoundError: Failed resolution of:
#     Landroid/media/metrics/LogSessionId;
#
# Confirmed crashing on Android 10 (Xiaomi/Samsung devices reported in
# the issue thread; reproduced on our own Android 10 build QKQ1.200830.002).
# Affects Media3 1.8.x, 1.9.x, 1.10.0 — downgrading doesn't help.
#
# Fix: tell R8 not to touch the affected classes. The android.media.metrics
# rules are not needed for symbol preservation (framework classes are never
# obfuscated) but they DO prevent R8 from making class-merge decisions based
# on the reference, which is what triggers the bug.
# ──────────────────────────────────────────────────────────────────────────

-keep class android.media.metrics.LogSessionId { *; }
-keep class android.media.metrics.** { *; }
-keep class androidx.media3.** { *; }
-keep interface androidx.media3.** { *; }
-dontwarn android.media.metrics.**
