# Important Reminders

Things that are pinned, forced, or worked-around to dodge upstream bugs.
Check this file periodically (e.g. when bumping Flutter SDK or running
`flutter pub upgrade`).

---

## Media3 `LogSessionId` crash workaround

**Where:**
- `android/gradle.properties` — `systemProp.com.android.tools.r8.disableHorizontalClassMerging=true` (the active workaround)
- `android/app/proguard-rules.pro` — keep rules, kept on disk but **inert** (not referenced from build.gradle.kts because minify is off). Insurance for if minify is ever re-enabled.

**The bug:** R8's horizontal class merging fuses Media3's
`androidx.media3.transformer.ExoPlayerAssetLoader$Factory` (which references
`android.media.metrics.LogSessionId`, API 31+) with another class reachable
on older Android. The merged class then fails to load on API ≤ 30 with:

```
java.lang.NoClassDefFoundError: Failed resolution of:
  Landroid/media/metrics/LogSessionId;
```

**Confirmed crashing:** Android 10 (build `QKQ1.200830.002`).

**It's NOT a Media3 bug** — it's an R8 bug. Affects Media3 1.8.x, 1.9.x,
and 1.10.x equally. Downgrading Media3 does not help.

**Upstream tracking:** https://github.com/androidx/media/issues/2535

**The workaround:** disabling R8's horizontal class merging via the
`gradle.properties` system prop. The merge pass is the specific R8
optimization that pulls API-31-only references into code reachable on
older Android. The flag works whether `isMinifyEnabled` is true or false.

**Side effects of the workaround:**
- Slight reduction in R8's optimization budget — APK size grows by
  maybe 1-2% on the parts of the codebase R8 would have merged.
- No effect on functionality, runtime perf, debugging, or other plugins.

**When to revisit:**

1. **R8 ships a fix** that detects/avoids this merge automatically. Watch
   AGP release notes for R8 version bumps.
2. **Media3 ships a workaround** (e.g. moving the `LogSessionId` reference
   into an `@RequiresApi(31)` inner class that R8 can't merge across).
   Watch the issue thread above and Media3 release notes.

**To remove the workaround:**

1. Remove the `systemProp.com.android.tools.r8.disableHorizontalClassMerging`
   line from `android/gradle.properties`.
2. Optionally delete `android/app/proguard-rules.pro` (currently inert).
3. Build a release APK and verify on a real Android < 12 device that
   opening the editor + rendering an edited video does not crash.

**iOS is unaffected** — `pro_video_editor` on iOS uses AVFoundation, which
has nothing to do with Media3 or `LogSessionId`. R8 doesn't apply on iOS.
