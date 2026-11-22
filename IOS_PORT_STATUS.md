# iOS port status

This branch contains the **original AbsentMotion source tree** imported from [Comett1225/AbsentMotion](https://github.com/Comett1225/AbsentMotion), with the existing speed-curve editor updated to draw diamond keyframe markers and allow per-keyframe speed-graph easing presets.

**Not an iOS port or an IPA.** The existing application builds for Android and desktop; the current Gradle project has no iOS target. The Kotlin UI uses Android Compose/resources/platform services and the media/graphics engine relies on platform-specific native libraries. An actual iOS port needs a supported iOS UI/runtime, native video decode/encode/audio backend, render engine bindings, platform file handling, project persistence and extensive device validation.

Existing speed features: keyframed speed map, graph easing/presets, speed curves, manual time remapping. These live in `shared/kotlin/app/absentmotion/model/SpeedCurve.kt`, `VideoTiming.kt`, and `ui/editor/panels/SpeedCurvePanel.kt`.

The GPL-3.0 upstream LICENSE and copyright notices are preserved. The prototype on this repository's `main` branch is a separate SwiftUI demo, not the source port.

## Implemented native iOS bridge

- `ios/native/AMEasingBridge.h` exposes stable C APIs for easing and speed map evaluation.
- `ios/native/AMEasingBridge.cpp` delegates to the **original upstream C++** `shared/cpp/easing.cpp`. It does not reimplement the curves in Swift.
- `ios/native/port_smoke.cpp` verifies representative curves and speed map values.
- `main:.github/workflows/absentmotion-native-ios.yml` builds the original easing C++ for real iOS arm64 and the iOS simulator, outputting `libAbsentMotionCore.a`. It also executes smoke tests on macOS.

This is an incremental reuse of the original native code and is **not** an iOS application, complete port, or installable IPA. UI, rendering, media, codec dependencies, project storage and device testing are still missing.
