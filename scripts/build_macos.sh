#!/bin/zsh
# Build a genuine universal macOS release; never package the iOS Simulator app as a Mac app.
set -euo pipefail
TASK_ROOT="${0:A:h:h}"
TASK_BUILD="${WATERHEALTH_MAC_BUILD_DIR:-$TASK_ROOT/.build/macos}"
export DEVELOPER_DIR="${DEVELOPER_DIR:-/Applications/Xcode.app/Contents/Developer}"
cd "$TASK_ROOT"
xcodebuild -project ios/WaterHealth.xcodeproj -scheme WaterHealthMac \
  -configuration Release -destination 'generic/platform=macOS' \
  -derivedDataPath "$TASK_BUILD" ARCHS='arm64 x86_64' ONLY_ACTIVE_ARCH=NO \
  CODE_SIGNING_ALLOWED=NO build
if [[ "${1:-}" != --build-only ]]; then
  python3 scripts/package_macos.py --build-dir "$TASK_BUILD"
fi
