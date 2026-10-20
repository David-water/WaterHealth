# Setup, builds and distribution

## Mac preview

Get the DMG or ZIP and `SHA256SUMS.txt` from the [preview release](https://github.com/David-water/WaterHealth/releases/tag/v1.0.0-preview.1). Check it before opening:

```sh
shasum -a 256 WaterHealth-macOS.dmg
```

Compare the printed hash with the release checksum. Open the DMG, drag WaterHealth into Applications and launch it. Requires macOS 14+, with arm64/x86_64 slices. This is an ad-hoc signed, non-notarized preview. If macOS blocks the first open, follow the system's Privacy & Security → Open Anyway flow after verifying the source. [Apple's instructions](https://support.apple.com/102445). Do not disable Gatekeeper.

If macOS says it does not support the application, make sure you downloaded the **macOS** package. An iOS simulator `.app` cannot be double-clicked as a Mac application.

## Native development

Install full Xcode 26+ and an iOS Simulator runtime, then open `ios/WaterHealth.xcodeproj`. Command Line Tools alone are insufficient. Schemes: `WaterHealth` for iPhone/iPad, `WaterHealthMac` for My Mac. Shared source lives in `ios/WaterHealth`.

```sh
make ios
xcrun simctl list devices available
# Start your chosen simulator first, then install the built app:
zsh scripts/run_simulator.sh DEVICE_UUID
```

Set `DEVELOPER_DIR` if your Xcode lives elsewhere. `WATERHEALTH_BUILD_DIR` controls the simulator build directory. To rebuild the checked-in Xcode project, run `python3 scripts/generate_project.py`.

## Tests

```sh
make check
make test
WATERHEALTH_SIMULATOR=DEVICE_UUID make ui-test
```

The test script selects an available iPhone simulator by default and saves result bundles under `.build/test-results/`. Use an iPad when running the landscape UI test. The long recording/marketing pipeline is intentionally excluded from this source repository.

## Mac source and packaging

```sh
make mac
make mac-package
```

The second command builds, validates the MacOSX bundle and both architectures, signs it locally and packages DMG/ZIP plus hashes under `.build/release/`. It does not publish or rewrite the website. Set `WATERHEALTH_SIGN_IDENTITY` to an identity you own for signing; notarization remains a separate step. Never commit certificates or private keys.

## iPhone/iPad devices and App Store

Choose your own Team and unique Bundle Identifier in Signing & Capabilities. Verify HealthKit entitlement and usage descriptions. Device mode is `zsh scripts/build_ios.sh device`; its unsigned output cannot be distributed as an installable app.

TestFlight/App Store distribution needs an Apple Developer team, signing, capabilities, real-device testing and store/privacy review. No public mobile installation link is currently available.

## Website

```sh
make web
# http://127.0.0.1:4173/
```

The `website/` directory is plain source HTML/CSS/JS; there is no bundler or npm install. Deploy its contents as a static site root. Assets use root-relative paths, so a subdirectory-hosted site requires adjusting its base paths. The download page points to published GitHub Release assets, whose hashes are recorded in `website/downloads/release.json`.

The existing public preview is [waterhealth.knowhappywater.chatgpt.site](https://waterhealth.knowhappywater.chatgpt.site). This repository does not include private hosting bindings or deployment credentials.
