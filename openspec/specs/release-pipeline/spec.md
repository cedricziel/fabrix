# release-pipeline Specification

## Purpose

Builds reach TestFlight for iOS (iPhone and iPad) and macOS from CI, signed with match, without manual steps.
## Requirements
### Requirement: TestFlight upload from CI

CI SHALL build, sign and upload the iOS IPA and the macOS PKG to TestFlight under bundle ID `com.cedricziel.fabrix`.

#### Scenario: Manual dispatch

- **WHEN** the TestFlight workflow is dispatched
- **THEN** it uploads one iOS build and one macOS build, each built from the same commit

#### Scenario: Release created

- **WHEN** release-please creates a release on main
- **THEN** the TestFlight workflow runs for that commit with only the signing, App Store Connect, App Review contact and telemetry ingest secrets

#### Scenario: Telemetry key baked in

- **WHEN** the TestFlight workflow builds with the `OTLP_ENDPOINT` and `OTLP_API_KEY` secrets
- **THEN** the uploaded builds export telemetry, the key never appears in xcodebuild arguments or the repository, and the secrets file is deleted after the build

#### Scenario: Debug build on a machine that made a release

- **WHEN** a Debug build runs after a local release lane
- **THEN** it does not read the secrets file and runs with telemetry off

### Requirement: Build numbers

The build number SHALL be the count of commits reachable from HEAD, and the marketing version SHALL come from `project.yml`, which release-please bumps.

#### Scenario: Two builds from later commits

- **WHEN** a build is made from a commit that descends from an earlier build's commit
- **THEN** its build number is higher

### Requirement: Signing

Signing SHALL use match App Store profiles from the certificates repo, read-only in CI, including the Mac installer certificate for the PKG.

#### Scenario: CI cannot create certificates

- **WHEN** match runs in CI
- **THEN** it runs read-only and fails instead of creating certificates or profiles

