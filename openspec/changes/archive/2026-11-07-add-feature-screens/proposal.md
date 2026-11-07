## Why

The app shell only shows a placeholder list, so there is nothing to put on TestFlight. The first build needs the screens from the design canvas, running against the demo factory, with a clean place to plug in real server connections later.

## What Changes

- Navigation: a sidebar split view on macOS and iPadOS (factory, companies, Overview, Tasks, Agents, Org chart, Approvals, Activity) and four tabs on iOS (Factory, Tasks, Approvals, Agents). The toolbar has search, Pause company and a New task sheet (placeholder until the service can create tasks).
- Onboarding on first launch: connect a factory by address and sign-in method (Paperclip API key, OIDC, or OIDC in front of a Paperclip key), or explore the demo. Connecting goes through a connector that the app passes in; until one exists the form is shown but disabled.
- Approvals: Waiting and Decided lists with approve, reject and undo. Decisions wait out a short undo window before they reach the factory.
- Overview: metric cards, live runs with ticking timers, decisions waiting on the user, and recent activity.
- Task board: kanban columns by status on regular width, a grouped list on compact width.
- Agents: agent list, agent detail (current run, budget, recent runs, Pause and Wake now), and an org chart built from reporting lines on regular width.
- The root view keeps the loading, empty and failed states from `app-load-state`, and adds a way back to factory selection.

Platforms: macOS, iPadOS and iOS. Targets touched: FabrixFeatures and the app shells in `App/`. FabrixCore and FabrixDesign are unchanged, and the `FactoryService` protocol is unchanged.

## Capabilities

### New Capabilities

- `navigation`: how the user moves between factory sections on compact and regular width.
- `onboarding`: first launch, connecting a factory with a chosen sign-in method, and the demo.
- `approvals`: deciding approvals with undo.
- `company-overview`: the overview screen's metrics, live runs, decisions and activity.
- `task-board`: tasks grouped by status.
- `agent-control`: agent detail, pause and wake, and the org chart.

### Modified Capabilities

None. The `app-load-state` requirements still hold as written.

## Impact

- `Packages/FabrixKit/Sources/FabrixFeatures`: new screens, shells, logic types and interim components. `AppModel` gains onboarding, polling, staged approvals and lookups.
- `App/Shared/FabrixApp.swift`: default Mac window size.
- The paperclip-client work plugs in by passing a `FactoryConnector` to `AppModel`; the `FactoryAuth` cases map to its auth providers.
- The interim components in `FabrixFeatures/Interim` are replaced by FabrixDesign components when that work lands.
