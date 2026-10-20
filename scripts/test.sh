#!/bin/zsh
set -euo pipefail
TASK_ROOT="${0:A:h:h}"
export DEVELOPER_DIR="${DEVELOPER_DIR:-/Applications/Xcode.app/Contents/Developer}"
TASK_MODE="${1:-unit}"
if [[ "$TASK_MODE" != unit && "$TASK_MODE" != ui ]]; then
  print -u2 'Usage: zsh scripts/test.sh [unit|ui]'; exit 2
fi
TASK_DEVICE="${WATERHEALTH_SIMULATOR:-}"
if [[ -z "$TASK_DEVICE" ]]; then
  TASK_DEVICE="$(xcrun simctl list devices available --json | python3 "$TASK_ROOT/scripts/select_simulator.py")"
fi
TASK_RESULTS="$TASK_ROOT/.build/test-results/$TASK_MODE-$(date +%Y%m%d-%H%M%S).xcresult"
TASK_SELECTION=(-only-testing:WaterHealthTests)
if [[ "$TASK_MODE" == ui ]]; then
  TASK_SELECTION=(-only-testing:WaterHealthUITests/WaterHealthUITests/testCoreNavigationAndLocalChat -only-testing:WaterHealthUITests/WaterHealthUITests/testNewGoalIsUsable)
fi
xcodebuild test -project "$TASK_ROOT/ios/WaterHealth.xcodeproj" -scheme WaterHealth   -destination "platform=iOS Simulator,id=$TASK_DEVICE"   -derivedDataPath "$TASK_ROOT/.build/tests" -resultBundlePath "$TASK_RESULTS"   -parallel-testing-enabled NO "${TASK_SELECTION[@]}" CODE_SIGNING_ALLOWED=NO
