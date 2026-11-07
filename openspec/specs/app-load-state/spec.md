# app-load-state Specification

## Purpose

The app shows a clear state while loading a factory, when the factory has no companies, and when it cannot be reached.

## Requirements

### Requirement: Load states

`AppModel` SHALL expose a load state of loading, loaded, empty or failed, and the root view SHALL render each.

#### Scenario: Factory with companies

- **WHEN** the service returns at least one company and its snapshot
- **THEN** the load state is loaded and the first company's snapshot is shown

#### Scenario: Factory without companies

- **WHEN** the service returns no companies
- **THEN** the load state is empty, any previous snapshot is cleared, and the user sees "No companies yet"

#### Scenario: Unreachable factory on first load

- **WHEN** the first refresh throws
- **THEN** the load state is failed with the error message, and the user sees "Can't reach the factory" with a "Try again" button that refreshes

#### Scenario: Refresh fails after a successful load

- **WHEN** a later refresh throws while a snapshot is shown
- **THEN** the snapshot stays visible and the error is recorded in `lastError`
