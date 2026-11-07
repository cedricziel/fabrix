## 1. Core: model, service, Paperclip mapping, demo (PR 1, FabrixCore)

- [ ] 1.1 Add `ProjectStatus`, `ProjectRepository` and `Project` to `FabrixCore/Models.swift`, plus `WorkItem.projectID` and `ActivityEvent.taskID`/`projectID` with `nil` defaults. Test: `ProjectModelTests.activeStatuses` (backlog, planned and in progress are active; completed and cancelled aren't). Touches FabrixCore.
- [ ] 1.2 Add `projects(companyID:)` to `FactoryService`, with a default that throws the new `FactoryServiceError.unsupported`. Test: `ProjectModelTests.defaultProjectsIsUnsupported`, using a minimal conformer. Touches `FactoryService.swift`.
- [ ] 1.3 Record sandbox payloads as fixtures (`Tests/FabrixCoreTests/Fixtures/projects-list.json`, `issues-with-project.json`, `activity-project.json`). No test; they are inputs for 1.4–1.6.
- [ ] 1.4 Add `ProjectDTO`/`ProjectWorkspaceDTO` and the `Project(paperclip:)` mapping: status, unknown status → backlog, target date as calendar date, colour, goals, git and folder workspaces, primary flag. Tests: `PaperclipProjectMappingTests` (`mapsRecordedList`, `unknownStatusIsBacklog`, `gitAndFolderRepositories`, `targetDateHasNoTimeZoneShift`). Touches `PaperclipDTOs.swift`, `PaperclipMapping.swift`.
- [ ] 1.5 Map `IssueDTO.projectId` → `WorkItem.projectID`, and activity `entityType` issue/project → `taskID`/`projectID`. Tests: `PaperclipFactoryServiceTests.taskCarriesProject` and `activityCarriesSubject`. Touches `PaperclipDTOs.swift`, `PaperclipMapping.swift`.
- [ ] 1.6 Implement `PaperclipFactoryService.projects(companyID:)` on `GET companies/{id}/projects`, with 404 → `.unsupported` and other errors passed through. Tests: `PaperclipFactoryServiceTests.projectsFromServer`, `projectsNotFoundIsUnsupported`, `projectsForbiddenIsAnError`. Touches `PaperclipFactoryService.swift`.
- [ ] 1.7 Add demo projects to `DemoFactoryService`: Mobile app, Platform, Launch, Billing (no lead, no repos) and a completed Onboarding v0, and assign demo tasks to them. Test: `DemoFactoryServiceTests.demoHasProjects`. Touches `DemoFactoryService.swift`.
- [ ] 1.8 Add a sandbox contract test that creates a project with a repository URL and an issue in it, then checks `projects(companyID:)` and `WorkItem.projectID`. Extend `scripts/paperclip-sandbox-seed.sh` with one project, a repository URL and one issue in it. Test: `SandboxContractTests.projects` (skipped without `FABRIX_SANDBOX_URL`). Touches `SandboxContractTests.swift`, the seed script.

## 2. Design components (PR 2, FabrixDesign)

- [ ] 2.1 Add `ProjectSwatch` and `ProjectChip`, which take a name and a hex string, fall back to `Palette.idle` for a missing or invalid hex, and keep the text in neutral ink. Test: `ProjectChipTests.invalidHexFallsBackToIdle` and `parsesHex`. Touches `FabrixDesign/Projects.swift`.
- [ ] 2.2 Add `ProjectStatusStyle` and `ProjectStatusPill`, with the same shape as the status pill. Test: `StatusStyleTests.projectStatusContrast` (ink on tint ≥ 4.5:1 in light and dark). Touches `FabrixDesign/Projects.swift`.
- [ ] 2.3 Add `TaskCountsBar(open:blocked:done:)` with its text line, and the bar hidden from accessibility. Test: `ProjectChipTests.countsBarFractions` (widths sum to 1; an all-zero project yields an empty bar). Touches `FabrixDesign/Projects.swift`.

## 3. Features: state, list, navigation (PR 3, FabrixFeatures, after #35/#37)

- [ ] 3.1 Add `ProjectBoard` (counts, active and completed lists, tasks by status, activity, lead resolution). Tests: `ProjectBoardTests` (`countsSkipCancelled`, `taskWithoutProjectCountsNowhere`, `activityIncludesTaskEvents`, `leadOutsideCompany`, `archivedNotListed`). Touches `FabrixFeatures/Logic/ProjectBoard.swift`.
- [ ] 3.2 `AppModel.projectsState`: load beside the snapshot under the same request generation; first load `.loading`; failure → `.failed` with the last list; `.unsupported` passes through; reset on company switch. Tests: `AppModelProjectsTests` (`loadsBesideSnapshot`, `failureKeepsCompanyUsable`, `refreshFailureKeepsLastList`, `unsupportedHidesProjects`, `switchCompanyResetsProjects`, `staleProjectsDropped`). Touches `AppModel.swift`, `GatedService.swift`.
- [ ] 3.3 Regular-width sidebar: a Projects group with All projects and project rows (open and blocked counts), hidden when unsupported, and `SidebarItem` selection. Test: `NavigatorTests.projectSelectionSurvivesRefresh` and `projectSelectionClearsOnCompanySwitch`. Touches `Shell/AppSection.swift`, `Shell/SplitShell.swift`.
- [ ] 3.4 Compact width: Projects in the Factory tab's More menu, and a Projects card on the overview (up to three projects, See all). Test: `NavigatorTests.compactProjectsOpenInFactoryTab`. Touches `Shell/AppSection.swift`, `Shell/CompactShell.swift`, `Screens/OverviewView.swift`.
- [ ] 3.5 `ProjectsView`: Active/Completed, rows with swatch, status pill, lead, counts bar, target date and repository count; loading, empty, error-with-retry and unsupported states. No test (view only); its logic is covered by 3.1–3.2. Touches `Screens/ProjectsView.swift`.

## 4. Features: detail, filter, chip (PR 4, FabrixFeatures)

- [ ] 4.1 `ProjectDetailView`: header, counts, tasks by status, repositories (git opens its URL; folder doesn't), activity, lead outside the company, and the "project is gone" state. Test: `ProjectBoardTests.detailGoneWhenProjectMissing`. Touches `Screens/ProjectDetailView.swift`, `Shell/AppSection.swift` (route).
- [ ] 4.2 `AppModel.taskProjectFilter` (`.all`, `.project`, `.none`) applied in `visibleTasks`, and reset on company switch. Tests: `TaskBoardTests.filterByProject`, `filterNoProject`, `filterResetsOnCompanySwitch`. Touches `AppModel.swift`, `Logic/TaskBoard.swift`.
- [ ] 4.3 Tasks UI: a filter menu in the toolbar, a token that clears it, a "Project details" link when filtered, and a `ProjectChip` on cards and rows only when unfiltered. Test: `TaskBoardTests.chipOnlyWhenUnfiltered` (the `TaskBoard` row value carries the chip). Touches `Screens/TasksView.swift`, `Logic/TaskBoard.swift`.
- [ ] 4.4 Check against the sandbox (`/validate`), take a Mac screenshot on the demo factory, and run the iOS and Mac builds. No test (verification).

## 5. Docs and archive (PR 5)

- [ ] 5.1 Add a Projects section to `docs/paperclip-api.md`: endpoints, the status mapping, workspaces → repositories, 404 → unsupported, and the cross-company lead. No test (docs).
- [ ] 5.2 Archive OpenSpec change `add-projects` as the last commit. No test.
