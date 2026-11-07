## Context

`AppModel` already loads one company through `FactoryService` and exposes a load state (see `app-load-state`). FabrixDesign only has `Palette`; the components the screens need are being built in a parallel change. Server connections and auth providers are also being built in parallel.

## Goals / Non-Goals

**Goals:**

- Ship every v1 screen against `DemoFactoryService`, on all three platforms.
- Keep view logic in small, testable value types.
- Leave a seam for connecting real factories that needs only a few lines once the client exists.

**Non-Goals:**

- Networking, auth flows and credential storage.
- Dark mode (Palette has no dark variants yet).
- Creating tasks (the service cannot yet).

## Decisions

- **Ownership.** All new types live in FabrixFeatures. FabrixDesign is untouched and still has no FabrixCore dependency. Components the design system will provide (`StatusPill`, `MetricCard`, `BudgetBar`, `AvatarBadge`, `KindTag`, button styles, card chrome) are built under `FabrixFeatures/Interim` with the same names, so swapping means deleting files. Colors Palette doesn't name yet live in `Interim/Tokens.swift` as a `Palette` extension.
- **Logic types.** `TaskBoard` (columns by status), `OrgTree` (tree from `reportsToID`, cycles and orphans become roots), `ApprovalDesk` (staged decisions with undo), `OverviewMetrics` (counts), `Budget` (fraction and near-cap at 90%), `Elapsed`/`Money` (formatting) and `ConnectForm` (validation) are plain values with unit tests. Views only lay them out.
- **Undo for approvals.** The factory has no undo, so a decision is staged in `ApprovalDesk` and committed after an 8 second window, or immediately when the app leaves the foreground. Alternative considered: send immediately and offer a reverse decision; rejected because Paperclip doesn't allow flipping a decided approval.
- **Connector seam.** `AppModel(connector:)` takes a `FactoryConnector` that turns a base URL and a `FactoryAuth` (`paperclip`, `oidc`, `oidcWithPaperclip`) into a `FactoryConnection` (factory plus service). The app passes none today, so the form is disabled with a note; the demo is the only path. Alternative considered: a closure; a protocol lets the client's store conform directly.
- **Navigation.** `Navigator` owns the selected section, the split view's path, the iPhone tab and each tab's path. Screens call `navigator.open(_:)` and each shell decides how to get there: switching the sidebar section, or picking a tab and pushing sections that have no tab (Org chart, Activity) onto the Factory tab.
- **Freshness.** `AppModel.keepFresh()` loads immediately and then polls every 20 seconds while the scene is active. Snapshots are only assigned when they changed, and per-snapshot lookups (agents by ID, live run by task, runs by agent) are built once.

## Risks / Trade-offs

- [Polling misses changes for up to 20 seconds] → Pull to refresh on every stack; replace with server push when the client supports it.
- [A staged decision is lost if the app is killed inside the undo window] → Commit on leaving the foreground; the window is short.
- [Light-only appearance on devices in dark mode] → Isolated in one modifier (`lightUntilPaletteAdapts`) to remove when Palette adapts.
