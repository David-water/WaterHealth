#!/bin/zsh
set -euo pipefail
TASK_ROOT="${0:A:h:h}"
export DEVELOPER_DIR="${DEVELOPER_DIR:-/Applications/Xcode.app/Contents/Developer}"
TASK_TARGET="${1:-simulator}"
TASK_BUILD_DIR="${WATERHEALTH_BUILD_DIR:-$TASK_ROOT/.build/$TASK_TARGET}"
if [[ "$TASK_TARGET" == device ]]; then
  TASK_DESTINATION='generic/platform=iOS'
  TASK_CONFIG=Release
else
  TASK_DESTINATION='generic/platform=iOS Simulator'
  TASK_CONFIG=Debug
fi
xcodebuild -project "$TASK_ROOT/ios/WaterHealth.xcodeproj" -scheme WaterHealth -configuration "$TASK_CONFIG" -destination "$TASK_DESTINATION" -derivedDataPath "$TASK_BUILD_DIR" CODE_SIGNING_ALLOWED=NO build
