# Validation and limits

## Reproducible checks

- `make check`: local Markdown/HTML assets, release metadata and repository hygiene using Python's standard library.
- `make test`: six XCTest business tests for persistence, goals/cart, CSV atomic validation/units, invalid values, duplicate imports, unreadable archive preservation and assistant dose boundaries.
- `make mac`: native universal macOS Release compilation.
- `make ios`: unsigned iOS Simulator compilation.
- `make ui-test`: phone navigation/local chat and custom-goal smoke tests. The separate iPad landscape case needs an iPad destination.

The public CI workflow is the current source-of-truth for automated build/test status. It does not certify a clinical product or every device/OS combination. There is no configured Swift lint dependency; do not describe lint as having passed.

## Clean source export — 2026-10-20

Locally checked with Xcode 27.1: `make check`, all six business tests (zero failures), and a fresh universal macOS Release build passed. The Mac installer is rebuilt from this clean source export. Remote CI results are shown by the README badge rather than a claimed universal-device pass rate.

## Existing evidence

The project's prior local validation used Xcode 27.1, passed six business tests and separately recorded actual iPad/iPhone journeys. Completed promotional and walkthrough files were decoded and independently checked. Recordings use fictional data and simulator hardware; they are not real-device HealthKit tests.

## Not verified or not shipped

- App Store/TestFlight distribution, Developer ID notarization, Intel hardware and minimum macOS 14 hardware testing.
- Real-device HealthKit permissions, actual health reads and notification delivery across permission/lock states.
- Cloud accounts/sync/backup, cloud LLMs, OCR, JSON restore, payment/fulfillment or clinical age/risk calculation.
- Clinical efficacy, adoption, retention, revenue, star growth or other business outcomes. No such metrics are claimed.

The Mac preview is locally signed; use its release instructions. Exports may contain sensitive data and need separate backup. Proposed work is listed in [roadmap](roadmap.md), not presented as completed.
