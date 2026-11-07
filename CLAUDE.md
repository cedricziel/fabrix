# Fabrix

Native control room for [Paperclip](https://github.com/paperclipai/paperclip) agent factories: macOS, iPadOS, iOS. One SwiftUI codebase, two app targets (`FabrixiOS` for iPhone + iPad, `FabrixMac`), one bundle ID `com.cedricziel.fabrix` (universal purchase).

Design: https://claude.ai/artifact/WdCVLSSBv9BTT8uwioNNMP (artboards for Mac overview, task board, iPad org chart, iPhone approvals/agent, Foundations tokens).

## Commands

- Package tests: `xcrun swift test --package-path Packages/FabrixKit` (always `xcrun swift`, never bare `swift`)
- Generate project: `xcodegen generate` (the `.xcodeproj` is gitignored; edit `project.yml`)
- Build: `xcodebuild build -project Fabrix.xcodeproj -scheme FabrixiOS -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO` (and `-scheme FabrixMac -destination 'generic/platform=macOS'`)
- fastlane locally: `scripts/fastlane-local.sh <lane>` reads credentials from 1Password. Lanes: `ios build|release`, `mac build|release`, `register_bundle_id`, `bootstrap_signing`.
- CI secrets: `scripts/setup-ci-secrets.sh`

## Layout

- `App/Shared`, `App/iOS`, `App/macOS`: thin app shells; all logic lives in the package.
- `Packages/FabrixKit`:
  - `FabrixCore`: models, `FactoryService` protocol (the UI/server seam), `DemoFactoryService`; the Paperclip API client lands here next.
  - `FabrixDesign`: tokens (`Palette`, type) and reusable components. No dependency on Core.
  - `FabrixFeatures`: screens and `AppModel`. Depends on Core + Design.

## Rules

- PRs merge with merge commits (no squash). Split larger work into native stacked PRs with `gh stack` (`gh stack init`, `gh stack add`, `gh stack submit`, `gh stack sync`).
- GitHub has no auto-merge for stacked PRs. The macOS CI job runs only on a stack's top PR and its lowest unmerged PR. Run `gh stack sync` so both are current, then merge with `gh stack merge <pr> --merge --yes`. Never merge a middle layer on its own; its CI was skipped.

- Views talk to `FactoryService` only, never to the HTTP client directly.
- Reusable visuals go in `FabrixDesign`; feature folders compose them.
- Every behavior change gets a Swift Testing test in the package.
- TestFlight uploads happen from CI (`testflight.yml`, also run on each release-please release). Build number = commit count.
