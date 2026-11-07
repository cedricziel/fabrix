## 1. Core: model, service, Paperclip mapping, demo (PR 1, FabrixCore)

- [x] 1.1 Add `ProjectStatus`, `ProjectRepository` and `Project` to `FabrixCore/Models.swift`, plus `WorkItem.projectID` and `ActivityEvent.taskID`/`projectID` with `nil` defaults. Test: `ProjectModelTests.activeStatuses` (backlog, planned and in progress are active; completed and cancelled aren't). Touches FabrixCore.
- [x] 1.2 Add `projects(companyID:)` to `FactoryService`, with a default that throws the new `FactoryServiceError.unsupported`. Test: `ProjectModelTests.defaultProjectsIsUnsupported`, using a minimal conformer. Touches `FactoryService.swift`.
- [x] 1.3 Record sandbox payloads as fixtures in `Tests/FabrixCoreTests/Support/PaperclipFixtures.swift` (`projects`, plus a `projectId` on an issue and a project activity row), following the file's existing inline style. No test; they are inputs for 1.4–1.6.
- [x] 1.4 Add `ProjectDTO`/`ProjectWorkspaceDTO` and the `Project(paperclip:)` mapping: status, unknown status → backlog, target date as calendar date, colour, goals, git and folder workspaces, primary flag. Tests: `PaperclipProjectMappingTests` (`mapsRecordedList`, `unknownStatusIsBacklog`, `gitAndFolderRepositories`, `targetDateHasNoTimeZoneShift`). Touches `PaperclipDTOs.swift`, `PaperclipMapping.swift`.
- [x] 1.5 Map `IssueDTO.projectId` → `WorkItem.projectID`, and activity `entityType` issue/project → `taskID`/`projectID`. Tests: `PaperclipFactoryServiceTests.taskCarriesProject` and `activityCarriesSubject`. Touches `PaperclipDTOs.swift`, `PaperclipMapping.swift`.
- [x] 1.6 Implement `PaperclipFactoryService.projects(companyID:)` on `GET companies/{id}/projects`, with 404 → `.unsupported` and other errors passed through. Tests: `PaperclipFactoryServiceTests.projectsFromServer`, `projectsNotFoundIsUnsupported`, `projectsForbiddenIsAnError`. Touches `PaperclipFactoryService.swift`.
- [x] 1.7 Add demo projects to `DemoFactoryService`: Mobile app, Platform, Launch, Billing (no lead, no repos) and a completed Onboarding v0, and assign demo tasks to them. Test: `DemoFactoryServiceTests.demoHasProjects`. Touches `DemoFactoryService.swift`.
- [x] 1.8 Add a sandbox contract test that creates a project with a repository URL and an issue in it, then checks `projects(companyID:)` and `WorkItem.projectID`. Extend `scripts/paperclip-sandbox-seed.sh` with one project, a repository URL and one issue in it. Test: `SandboxContractTests.projects` (skipped without `FABRIX_SANDBOX_URL`). Touches `SandboxContractTests.swift`, the seed script.

## 2. Design components (PR 2, FabrixDesign)

- [x] 2.1 Add `ProjectSwatch` and `ProjectChip`, which take a name and a hex string, fall back to `Palette.idle` for a missing or invalid hex, and keep the text in neutral ink. Test: `ProjectComponentTests.invalidHexFallsBack` and `parsesHex`. Touches `FabrixDesign/Projects.swift`.
- [x] 2.2 Add `ProjectStatusStyle` and `ProjectStatusPill`, with the same shape as the status pill. Test: `ProjectComponentTests.statusStyle` (labels and tones; tones reuse the ink/tint pairs `ContrastTests` already checks). Touches `FabrixDesign/Projects.swift`.
- [x] 2.3 Add `TaskCountsBar(open:blocked:done:)` with its text line, and the bar hidden from accessibility. Test: `ProjectComponentTests.countsBarFractions` and `emptyProjectHasEmptyBar`. Touches `FabrixDesign/Projects.swift`.

## 3. Features: project state (PR 3, FabrixFeatures)

- [x] 3.1 Add `ProjectBoard` (counts, active and completed lists, tasks by status, activity, lead resolution). Tests: `ProjectBoardTests` (`countsSkipCancelled`, `taskWithoutProjectCountsNowhere`, `activityIncludesTaskAndProjectEvents`, `leadResolution`, `archivedNotListedAndCompletedSplitOut`). Touches `FabrixFeatures/Logic/ProjectBoard.swift`.
- [x] 3.2 `AppModel.projectsState`: load beside the snapshot under the same request generation; first load `.loading`; failure → `.failed` with the last list; `.unsupported` passes through; reset on company switch. Tests: `AppModelProjectsTests` (`loadsBesideSnapshot`, `failureKeepsCompanyUsable`, `refreshFailureKeepsLastList`, `retryAfterFailure`, `unsupportedHidesProjects`, `switchCompanySwapsProjects`). Touches `AppModel.swift`, a `ProjectsFactory` test double.

## 4. Features: projects screens and navigation (PR 4, FabrixFeatures)

- [x] 4.1 Regular-width sidebar: a Projects group with All projects and project rows (open and blocked counts), hidden when unsupported, and `SidebarItem` selection. Tests: `NavigatorTests.regularLayoutShowsAPickedProjectInPlaceOfTheSection`, `companySwitchLeavesTheProject`. Touches `Shell/AppSection.swift`, `Shell/SplitShell.swift`.
- [x] 4.2 Compact width: Projects in the Factory tab's More menu, and a Projects card on the overview (up to three projects, See all). Test: `NavigatorTests.compactProjectsOpenInFactoryTab`. Touches `Shell/AppSection.swift`, `Shell/CompactShell.swift`, `Screens/OverviewView.swift`.
- [x] 4.3 `ProjectsView`: Active/Completed, rows with swatch, status pill, lead, counts bar, target date and repository count; loading, empty, error-with-retry and unsupported states. No test (view only); its logic is covered by 3.1–3.2. Touches `Screens/ProjectsView.swift`.
- [x] 4.4 `ProjectDetailView`: header, counts, tasks by status, repositories (git opens its URL; folder doesn't), activity, lead outside the company, and the "project is gone" state. No separate test: the gone state follows `ProjectBoard.project(_:)` returning nil, covered by `ProjectBoardTests.archivedNotListedAndCompletedSplitOut`. Touches `Screens/ProjectDetailView.swift`, `Shell/AppSection.swift` (route).

## 5. Features: task project filter and chip (PR 5, FabrixFeatures)

- [x] 5.1 `AppModel.taskProjectFilter` (`.all`, `.project`, `.none`) applied in `visibleTasks`, and reset on company switch. Tests: `TaskProjectFilterTests.filterByProject`, `filterNoProject`, `filterCombinesWithSearch`, `filterResetsOnCompanySwitch`. Touches `AppModel.swift`.
- [x] 5.2 Tasks UI: a filter menu in the toolbar, a token that clears it, a "Project details" link when filtered, and a `ProjectChip` on cards and rows only when unfiltered. Test: `TaskProjectFilterTests.chipOnlyWhenUnfiltered` (`AppModel.chipProject(for:)`). Touches `Screens/TasksView.swift`, `AppModel.swift`.
- [ ] 5.3 Check against the sandbox (`/validate`), take a Mac screenshot on the demo factory, and run the iOS and Mac builds. No test (verification).

## 6. Docs and archive (PR 6)

- [x] 6.1 Add a Projects section to `docs/paperclip-api.md`: endpoints, the status mapping, workspaces → repositories, 404 → unsupported, and the cross-company lead. No test (docs).
- [ ] 6.2 Archive OpenSpec change `add-projects` as the last commit. No test.

## 7. Review fixes (folded into PRs 1–5)

- [x] 7.1 Core: lenient row decoding, unknown status → `.other`, web-only repository URLs, `Project.taskCount`, `CompanySnapshot.formerAgentIDs`. Tests: `PaperclipProjectMappingTests` (`unknownStatusIsNotActive`, `badWorkspaceIsDropped`, `onlyWebURLsAreKept`, `keepsServerTaskCount`), `PaperclipFactoryServiceTests.malformedProjectRowIsSkipped`, `snapshotRemembersTerminatedAgents`.
- [x] 7.2 Design: `ProjectStatusPill` replaced by `StatusPill(_:title:)`. Test: `ProjectComponentTests.statusStyle`.
- [x] 7.3 State: parallel projects load, unsupported remembered per factory, reload after a failed switch, former lead, unloaded task count. Tests: `AppModelProjectsTests.unsupportedIsNotAskedAgain`, `failedSwitchReloadsTheShownCompanysProjects`, `ProjectBoardTests.terminatedLeadIsFormer`, `unloadedTasksBeyondTheWindow`.
- [x] 7.4 Screens: leave projects when unsupported, unloaded-tasks note, active badge, wording fixes. Test: `NavigatorTests.factoryWithoutProjectsLeavesThem`.
- [x] 7.5 Filter: reset when its project goes away. Test: `TaskProjectFilterTests.filterResetsWhenItsProjectDisappears`.
