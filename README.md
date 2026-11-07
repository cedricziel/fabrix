# Fabrix

Fabrix is a native control room for [Paperclip](https://github.com/paperclipai/paperclip) agent factories on macOS, iPadOS and iOS. With it you can:

- watch agent runs live
- approve hire, strategy and budget requests
- wake or pause agents
- work the task board
- browse the org chart

Demo mode loads sample data, so you can try the app without a server. The current beta runs on the demo only; connecting your own server and most of the screens above are still in review.

## Try it on TestFlight

Join the public beta: https://testflight.apple.com/join/uQU3veF3

The beta covers iPhone, iPad and Mac.

## Connect your factory (planned)

Fabrix will connect to a self-hosted Paperclip server. Sign in with either:

- a Paperclip board API key, or
- OIDC, including when an OIDC proxy sits in front of Paperclip.

## Development

Requirements: Xcode 26 or later, [XcodeGen](https://github.com/yonaskolb/XcodeGen), and Ruby for fastlane.

```sh
# Generate the Xcode project (edit project.yml; the .xcodeproj is gitignored)
xcodegen generate

# Run the package tests
xcrun swift test --package-path Packages/FabrixKit

# Build the iOS and Mac apps
xcodebuild build -project Fabrix.xcodeproj -scheme FabrixiOS -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO
xcodebuild build -project Fabrix.xcodeproj -scheme FabrixMac -destination 'generic/platform=macOS' CODE_SIGNING_ALLOWED=NO
```

Use `xcrun swift`, not bare `swift`, so the toolchain matches the Xcode SDK.

Layout:

- `App/Shared`, `App/iOS`, `App/macOS`: thin app shells.
- `Packages/FabrixKit`: all app logic, split into `FabrixCore` (models and the `FactoryService` protocol), `FabrixDesign` (tokens and components) and `FabrixFeatures` (screens).
- `openspec/`: [OpenSpec](https://github.com/Fission-AI/OpenSpec) specs and change proposals.

Split larger work into stacked PRs with `gh stack`. PRs merge with merge commits, not squash. CI uploads builds to TestFlight.

## License

MIT. See [LICENSE](LICENSE).
