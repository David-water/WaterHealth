#!/bin/zsh
set -euo pipefail
TASK_ROOT="${0:A:h:h}"
export DEVELOPER_DIR="${DEVELOPER_DIR:-/Applications/Xcode.app/Contents/Developer}"
TASK_DEVICE="${1:-booted}"
TASK_APP="${2:-${WATERHEALTH_BUILD_DIR:-$TASK_ROOT/.build/simulator}/Build/Products/Debug-iphonesimulator/WaterHealth.app}"
xcrun simctl install "$TASK_DEVICE" "$TASK_APP"
xcrun simctl launch "$TASK_DEVICE" com.waterhealth.app
