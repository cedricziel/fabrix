## 1. Navigation shell and onboarding (PR 1)

- [x] 1.1 Format elapsed time and dollar amounts (`Logic/Formatting.swift`); tests `FormattingTests`
- [x] 1.2 Budget fraction and near-cap rule (`Logic/Budget.swift`); tests `BudgetTests`
- [x] 1.3 Factory connection, sign-in methods and form validation (`Logic/Connecting.swift`); tests `ConnectFormTests`
- [x] 1.4 AppModel: onboarding, demo memory, load states, polling, company selection, search and lookups (`AppModel.swift`); tests `AppModelTests`, `AppModelLoadStateTests`
- [x] 1.5 Navigator routing for split and tab layouts (`Shell/AppSection.swift`); tests `NavigatorTests`
- [x] 1.6 Interim components, tokens and display text (`Interim/`, `Display.swift`); no test, visual only
- [x] 1.7 Split and tab shells, toolbar, New task sheet, Activity, onboarding screen, root view (`Shell/`, `Screens/ActivityView.swift`, `Screens/NewTaskSheet.swift`, `Screens/OnboardingView.swift`, `RootView.swift`, `App/Shared/FabrixApp.swift`); covered by the model tests above, checked in both app builds

## 2. Approvals (PR 2)

- [x] 2.1 Stage decisions with undo (`Logic/ApprovalDesk.swift`); tests `ApprovalDeskTests`
- [x] 2.2 AppModel decide, undo and commit after the window or on background (`AppModel.swift`, `RootView.swift`); tests `ApprovalFlowTests`
- [x] 2.3 Approvals screen and badges (`Screens/ApprovalsView.swift`, `Shell/`); no test, visual only

## 3. Overview (PR 3)

- [ ] 3.1 Company metrics (`Logic/OverviewMetrics.swift`); tests `OverviewMetricsTests`
- [ ] 3.2 Overview screen with live runs, decisions and activity (`Screens/OverviewView.swift`); no test, visual only

## 4. Task board (PR 4)

- [ ] 4.1 Group tasks into status columns (`Logic/TaskBoard.swift`); tests `TaskBoardTests`
- [ ] 4.2 Board, compact list and task details (`Screens/TasksView.swift`); no test, visual only

## 5. Agents and org chart (PR 5)

- [ ] 5.1 Build the org tree from reporting lines (`Logic/OrgTree.swift`); tests `OrgTreeTests`
- [ ] 5.2 Agent list and detail with pause and wake (`Screens/AgentsView.swift`); covered by `AppModelTests`, visual otherwise
- [ ] 5.3 Org chart with inspector (`Screens/OrgChartView.swift`); no test, visual only
- [ ] 5.4 Archive the change and sync specs
