# Alight-motion- — iOS time-remap prototype

This repository hosts an **independent SwiftUI + AVFoundation iOS editor prototype**, not the original Alight Motion app and not a complete port of [AbsentMotion](https://github.com/Comett1225/AbsentMotion).

Included functions: import a video, speed keyframes (diamonds), six per-segment easing presets, playback preview, and MP4 export. The source code is packaged in `ios-prototype.tar.xz.b64` for extraction by the build workflow. An unsigned IPA is produced only after a **successful** GitHub Actions macOS build; it is not directly installable without signing.

Go to **Actions → Build iOS time-remap IPA** and check the latest run. Its **Artifacts** section will hold the IPA if compilation succeeds.