<p align="center"><img src="website/assets/app-icon.png" width="88" alt="WaterHealth icon"></p>
<h1 align="center">WaterHealth</h1>
<p align="center"><strong>Your health records. Your device.</strong><br>Native SwiftUI apps for iPhone, iPad and Mac. Local storage. No backend. No API keys.</p>
<p align="center"><a href="https://waterhealth.knowhappywater.chatgpt.site">Website</a> · <a href="https://github.com/David-water/WaterHealth/releases/tag/v1.0.0-preview.1">Download Mac preview</a> · <a href="#demo">Watch demo</a> · <a href="README.zh-CN.md">简体中文</a></p>
<p align="center"><a href="https://github.com/David-water/WaterHealth/actions/workflows/ci.yml"><img src="https://github.com/David-water/WaterHealth/actions/workflows/ci.yml/badge.svg" alt="CI"></a> <a href="LICENSE"><img src="https://img.shields.io/badge/license-MIT-blue.svg" alt="MIT license"></a></p>

WaterHealth brings health readings, trends, personal goals and original reports into one native interface. It also serves as a small reference project for **local-first SwiftUI architecture**: shared business logic, platform-specific capabilities, atomic persistence and no third-party app packages.

The current app UI and narrated videos are in **Simplified Chinese**. English documentation is available here; app localization is a proposed contribution area.

## Demo

[![Watch the 60-second WaterHealth demo](docs/images/demo-cover.webp)](https://github.com/David-water/WaterHealth/releases/download/v1.0.0-preview.1/WaterHealth-demo-landscape.mp4)

**[Watch / download the 60-second demo](https://github.com/David-water/WaterHealth/releases/download/v1.0.0-preview.1/WaterHealth-demo-landscape.mp4)** · [Portrait version](https://github.com/David-water/WaterHealth/releases/download/v1.0.0-preview.1/WaterHealth-demo-portrait.mp4) · [Full native walkthrough](https://github.com/David-water/WaterHealth/releases/download/v1.0.0-preview.1/WaterHealth-walkthrough.mp4)

Actual native simulator recordings, fictional demo records. The Mac screenshots below come from the native macOS app. Videos and installers live in Releases, keeping `git clone` small.

## A look inside

| Body systems | Reports & trends | Goals & check-ins |
|:--:|:--:|:--:|
| <img src="website/assets/iphone-twin.webp" width="190" alt="Body-system view"> | <img src="website/assets/iphone-reports.webp" width="190" alt="Health readings and trends"> | <img src="website/assets/iphone-goals.webp" width="190" alt="Goals and check-in history"> |
| Nutrition checklist | Local assistant | Profile |
| <img src="website/assets/iphone-nutrition.webp" width="190" alt="Nutrition checklist"> | <img src="website/assets/iphone-assistant.webp" width="190" alt="Rule-based local assistant"> | <img src="website/assets/iphone-profile.webp" width="190" alt="Local profile"> |

<details>
<summary><strong>See the iPad and Mac layouts</strong></summary>

| iPad | Native Mac |
|:--:|:--:|
| <img src="website/assets/ipad-twin.webp" width="430" alt="iPad landscape layout"> | <img src="website/assets/mac-twin.webp" width="430" alt="Native macOS window"> |

</details>

## What works today

- **Records and trends:** categorized readings, dates, units, sources and manual measurement entry.
- **Goals:** create, edit and delete plans; record progress, undo check-ins and review history.
- **Local files:** attach original PDFs, validate CSV imports as a batch, skip duplicate readings and export the archive as JSON.
- **Local assistant:** deterministic summaries of existing records and goals. No LLM service or network key.
- **Platform adaptation:** compact phone navigation, wide iPad layouts and a genuine macOS target.
- **Local data handling:** Codable state, atomic writes, corrupted-archive protection, iOS file protection and Mac App Sandbox.

**Demo boundaries:** body artwork is illustrative; age/risk readings are fictional, not clinical estimates. The nutrition shop and orders are local simulations without payments or fulfillment. PDF attachments have no OCR; JSON export has no restore/import yet. Goals accumulate within a plan rather than resetting at midnight. Devices do not sync automatically. This is not a diagnostic tool.

## Try it

### Mac: no Xcode needed

Download **[WaterHealth-macOS.dmg](https://github.com/David-water/WaterHealth/releases/download/v1.0.0-preview.1/WaterHealth-macOS.dmg)**, drag the app into Applications, then launch it and select the demo profile.

Requires **macOS 14+**; universal **Apple silicon + Intel** binary. The preview is **ad-hoc signed, not Developer ID signed or notarized**. Read [first-open instructions](docs/quickstart.md#mac-preview) and verify the release checksum. Intel hardware and the minimum OS version have not been tested separately.

### iPhone / iPad: run the source

Requires full **Xcode 26+** and an installed iOS Simulator runtime. The deployment target is **iOS / iPadOS 17+**.

```sh
git clone https://github.com/David-water/WaterHealth.git
cd WaterHealth
open ios/WaterHealth.xcodeproj
```

Choose the **WaterHealth** scheme and an iPhone/iPad simulator, then Run. Choose **WaterHealthMac / My Mac** for native Mac development. Select the demo profile on first launch.

There is no TestFlight or App Store install link yet. Device deployment requires your own Apple signing configuration. HealthKit reads and notification delivery need real-device validation; the Mac target does not offer these integrations.

## Developer commands

```sh
make check          # repository, documentation and static website checks
make test           # six business tests; chooses an available iPhone simulator
make ios            # unsigned simulator build
make mac            # unsigned universal macOS Release build
make mac-package    # ad-hoc sign and create DMG / ZIP under .build/release/
make web            # http://127.0.0.1:4173; no npm or bundler
```

No `.env`, server, database, CocoaPods or Swift Package setup is required. Use `WATERHEALTH_SIMULATOR=UUID make test` to pick a simulator. Build products stay in ignored `.build/`.

## Architecture

```text
SwiftUI views → @MainActor HealthStore → Codable AppState → local JSON + attachments
                          ↑
                 validated CSV / iOS HealthKit
```

```text
ios/WaterHealth/       Core, Design, Features, assets and privacy manifest
ios/WaterHealthTests/  Business tests
ios/WaterHealthUITests/ Representative native UI tests
macos/                 Mac metadata and sandbox entitlements
website/               Plain HTML, CSS, JavaScript and shared screenshots
scripts/               Build, package, test and project-generation helpers
docs/                  Architecture, setup, usage, validation and media credits
.github/               CI, issue forms and pull-request template
```

[Architecture](docs/architecture.md) · [Setup & signing](docs/quickstart.md) · [Chinese user guide](docs/user-guide.zh-CN.md) · [Validation & limits](docs/validation.md)

## Contribute

Useful starting points include app localization, real-device HealthKit/notification validation, accessibility reviews and a versioned JSON restore flow. These are **proposed improvements**, not shipped capabilities. See the [roadmap](docs/roadmap.md) and [contributing guide](CONTRIBUTING.md).

Please use fictional health data in issues and screenshots. If the project is useful to you, a star helps other SwiftUI developers find it.

## License & credits

[MIT](LICENSE) for the source and original project assets; see [NOTICE](NOTICE.md) for reference-design attribution and third-party scope. Visual direction references **ClyHealth by George Railean**; this is an independent project with no affiliation or endorsement. Media credits are [documented separately](docs/media-credits.md).
