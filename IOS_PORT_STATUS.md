# iOS port status

This branch contains the **original AbsentMotion source tree** imported from [Comett1225/AbsentMotion](https://github.com/Comett1225/AbsentMotion), with the existing speed-curve editor updated to draw diamond keyframe markers and allow per-keyframe speed-graph easing presets.

**Partial iOS port, not feature complete.** The upstream application builds for Android and desktop; the original Gradle project has no iOS target. A new experimental iOS host now exists under `ios/App`, and builds unsigned IPA via `main:.github/workflows/absentmotion-ios-app.yml`. The Kotlin UI uses Android Compose/resources/platform services and the media/graphics engine relies on platform-specific native libraries. An actual iOS port needs a supported iOS UI/runtime, native video decode/encode/audio backend, render engine bindings, platform file handling, project persistence and extensive device validation.

Existing speed features: keyframed speed map, graph easing/presets, speed curves, manual time remapping. These live in `shared/kotlin/app/absentmotion/model/SpeedCurve.kt`, `VideoTiming.kt`, and `ui/editor/panels/SpeedCurvePanel.kt`.

The GPL-3.0 upstream LICENSE and copyright notices are preserved. The prototype on this repository's `main` branch is a separate SwiftUI demo, not the source port.

## Implemented native iOS bridge

- `ios/native/AMEasingBridge.h` exposes stable C APIs for easing and speed map evaluation.
- `ios/native/AMEasingBridge.cpp` delegates to the **original upstream C++** `shared/cpp/easing.cpp`. It does not reimplement the curves in Swift.
- `ios/native/port_smoke.cpp` verifies representative curves and speed map values.
- `main:.github/workflows/absentmotion-native-ios.yml` builds the original easing C++ for real iOS arm64 and the iOS simulator, outputting `libAbsentMotionCore.a`. It also executes smoke tests on macOS.

The iOS app now links **original native source** (easing and scene XML), provides a SwiftUI video preview/trim-speed graph and an AVFoundation MP4 export path, plus basic XML scene inspection. The native timeline implementation uses upstream easing to integrate speed over source time and passed smoke tests. This is a **partial port**, not a full AbsentMotion editor. Multi-layer compositing, full original effects, masks, the full project UI, audio/video pipeline parity, iOS device/runtime testing and app signing remain missing. The IPA is unsigned and must be signed for installation.

## iOS build

- Source: `ios/App/AbsentMotionIOS.swift`, `ios/project.yml`
- Native source: `shared/cpp/easing.cpp`, `shared/cpp/xml.cpp` and `ios/native/*Bridge.cpp`, `AMVideoTiming.cpp`
- Build workflow: [experimental iOS app](https://github.com/Matwey181/Alight-motion-/actions/workflows/absentmotion-ios-app.yml)
- CI proves compilation and IPA packaging, **not** full-feature correctness or device launch.
