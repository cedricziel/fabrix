## Context

See proposal.md, Why. Fabrix today:

- `FactoryService` (`FabrixCore/FactoryService.swift`) has 8 methods. `projects(companyID:)` set the pattern for optional features: a default that throws `FactoryServiceError.unsupported`, a live implementation that maps `404` to it, and app state that hides the feature.
- `WorkItem` carries id, identifier, title, status, assignee, update time and project. The snapshot loads up to 500 issues with `GET /companies/{id}/issues?limit=500` and the company's 50 most recent runs.
- `TasksView` shows a board (regular) or a sectioned list (compact). Its `TaskDetailView` shows assignee, update time, the live run and Wake agent. `NewTaskSheet` is a placeholder; the toolbar's New task button already has ⌘N.
- `AppModel.swift` is 1,091 lines. Roadmap Phase 5 asks new areas to live in their own types.
- `ApprovalDesk` stages approval decisions for 8 seconds and commits them on timer, on background (`RootView` calls `commitStagedDecisions()`) and before a factory or company switch.
- Telemetry templates UUIDs, numbers and long ID-like segments in URL paths (`AttributeScrubber.template`), drops queries, and records no bodies. A document key such as `launch-plan` isn't templated today.
- The Phase 1 change `add-inbox` (PR 88) is being built at the same time in its own stack. It edits `FactoryService.swift`, `DemoFactoryService.swift`, `AppModel.swift`, `AppSection.swift`, the shells, `AttributeScrubber.swift` and the string catalogs. It never edits `Models.swift`.
- The design is 18 task artboards plus notes (in the Phase 2 design hand-over, not yet published to the design file). This document names their components.

Paperclip facts below were read at `890dcbdd` in `server/src/routes/issues.ts`, `server/src/routes/agents.ts`, `server/src/services/issues.ts`, `server/src/services/documents.ts`, `server/src/services/issue-run-presence.ts`, `server/src/app.ts`, `packages/shared/src/types/issue.ts`, `packages/shared/src/types/work-product.ts`, `packages/shared/src/validators/issue.ts` and `packages/shared/src/constants.ts`.

## Goals / Non-Goals

**Goals:**

- Every Phase 2 scope bullet and per-device bullet from `docs/roadmap.md`. The specs map them one to one; the runs bullet is delivered in part `[D3]`.
- `AppModel` grows by at most about 15 lines. Task state and actions live in `TaskStore`.
- Every new screen has demo data, a state on all three devices, and tests.
- Edits to files that `add-inbox` also edits are small, in places that lane doesn't touch, and named per slice.

**Non-Goals:**

- Editing documents, description, blockers, labels, goal or parent `[D11]`; multi-select `[D9]`; non-Me people as assignees `[D8]`; interrupting a run `[D4]`; run transcripts (Phase 3).
- Removing the 500-task cap (Phase 5). A task outside the loaded 500 can still be opened from the inbox or a link; it just isn't on the board.
- Drafts on disk `[D13]`.
- Snapshot tests (scheduled after Phase 1 lands, in their own change).

## Decisions

### 1. Where the types live

FabrixDesign keeps no dependency on FabrixCore. Each component takes strings, numbers, dates, closures and enums declared in FabrixDesign. FabrixFeatures maps Core models onto them. `DesignIndependenceTests.noCoreImport` from `add-inbox` slice 1 guards this.

| Type                                                                                                                                                                                                                                                                                                                                                     | Target         | File                                                                                      |
| -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | -------------- | ----------------------------------------------------------------------------------------- |
| `TaskPriority` (`critical`, `high`, `medium`, `low`)                                                                                                                                                                                                                                                                                                     | FabrixCore     | `Tasks/TaskModels.swift` (new)                                                            |
| `WorkItem.priority: TaskPriority = .medium`                                                                                                                                                                                                                                                                                                              | FabrixCore     | `Models.swift` (one stored property and one init parameter with a default)                |
| `TaskDetail`, `TaskAncestor`, `TaskRelation`, `TaskLabel`, `TaskAssignee` (`.agent(id)`, `.user(id)`, `.none`), `Embedded<T>` (`.absent`, `.present(T)`), `TaskComment`, `CommentAuthor`, `TaskDocument`, `DocumentRevision`, `WorkProduct` (with `Kind`, `Health`, `opening`), `TaskRunPresence`, `LinkedRun`, `TaskDraft`, `TaskChange`, `Refusal`     | FabrixCore     | `Tasks/TaskModels.swift`                                                                  |
| `FactoryServiceError.refused(Refusal)`                                                                                                                                                                                                                                                                                                                   | FabrixCore     | `FactoryService.swift` (one case)                                                         |
| 12 new protocol requirements                                                                                                                                                                                                                                                                                                                             | FabrixCore     | `FactoryService.swift`, in one `// MARK: Tasks` block placed after `snapshot(companyID:)` |
| Their defaults                                                                                                                                                                                                                                                                                                                                           | FabrixCore     | `Tasks/FactoryService+Tasks.swift` (new)                                                  |
| `IssueDetailDTO`, `IssueCommentDTO`, `IssueDocumentDTO`, `DocumentRevisionDTO`, `WorkProductDTO`, `RunPresenceDTO`, `CreateIssueBody`, `UpdateIssueBody`, `ValidationErrorDTO`, the mapping                                                                                                                                                              | FabrixCore     | `Paperclip/TaskDTOs.swift`, `Paperclip/TaskMapping.swift` (new)                           |
| Live methods                                                                                                                                                                                                                                                                                                                                             | FabrixCore     | `Paperclip/PaperclipFactoryService+Tasks.swift` (new)                                     |
| `PaperclipClient.download(path:)` (same origin only)                                                                                                                                                                                                                                                                                                     | FabrixCore     | `Paperclip/PaperclipClient+Download.swift` (new)                                          |
| Demo state and methods                                                                                                                                                                                                                                                                                                                                   | FabrixCore     | `DemoTaskWork.swift`, `DemoFactoryService+Tasks.swift` (new)                              |
| `TaskStatusStyle`, `TaskStatusPill`, `PriorityMark`, `PriorityLevel`, `TaskCard`, `BoardColumn`, `DropVerdict`, `ParentChain`, `RelationRow`, `FieldRow`, `RunRow`, `RunOutcome`, `WorkProductRow`, `WorkProductGlyph`, `DocumentRow`, `RevisionRow`, `RevisionBanner`, `MarkdownView`, `CommentComposer`, `PinnedActionButton`, `TaskDetailPlaceholder` | FabrixDesign   | `Tasks/*.swift` (new folder)                                                              |
| `TaskStore`, `TaskEditDesk`, `TaskContext`, `TaskCardModel` (Core to Design mapping), `DropRules`, the detail, thread, documents, work products, runs and create views, `TaskCommands`, `TaskWindow`                                                                                                                                                     | FabrixFeatures | `Tasks/*.swift` (new folder)                                                              |
| Task window scene                                                                                                                                                                                                                                                                                                                                        | App shell      | `App/Shared/FabrixApp.swift` (`WindowGroup(for: TaskWindowID.self)`, macOS only)          |

The existing private `TaskCard` and `ColumnHeader` in `TasksView.swift` are replaced by the FabrixDesign ones.

Phase 1 components reused, from `add-inbox` slice 1: `CommentRow` (gains Retry, Edit and Delete draft in its failed state), `UndoBar`, `KeyHint`, `OwnerLabel` (Unassigned on cards and in the assignee menu), `PlaceholderRow` (under `TaskDetailPlaceholder`). `ReasonField` isn't used.

### 2. Endpoints, requests and responses

All paths are relative to `/api`. Every call goes through `PaperclipClient`, never from a view.

| Use           | Request                                                                                                                                                                              | Response (fields Fabrix reads)                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            | Errors                                                                                                                                                                                                                                                                                                                                                                                                                                        |
| ------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Detail        | `GET issues/{i}`                                                                                                                                                                     | `Issue`: `id`, `identifier`, `title`, `description`, `status`, `priority`, `assigneeAgentId`, `assigneeUserId`, `projectId`, `project{id,name,color}`, `goalId`, `goal{id,title}`, `parentId`, `ancestors[]{id,identifier,title,status,priority}`, `blockedBy[]` and `blocks[]` `{id,identifier,title,status,priority,assigneeAgentId,assigneeUserId}`, `labels[]{id,name,color}`, `createdAt`, `updatedAt`, `completedAt`, `cancelledAt`, and when present `planDocument` (with `body`), `documentSummaries[]`, `legacyPlanDocument{key,body}`, `workProducts[]` `[D15]`. It does not embed `activeRun`. | `404 "Issue not found"`: `PaperclipError.notFound`. `404 "API route not found"`: `.unsupported`.                                                                                                                                                                                                                                                                                                                                              |
| Comments      | `GET issues/{i}/comments?order=desc&limit=100[&after={commentId}]`                                                                                                                   | `[IssueComment]`: `id`, `authorType` (`user`, `agent`, `system`), `authorAgentId`, `authorUserId`, `body`, `createdByRunId`, `createdAt`, `deletedAt` (deleted comments are skipped)                                                                                                                                                                                                                                                                                                                                                                                                                      | `404` route: `.unsupported`. The server caps `limit` at 500.                                                                                                                                                                                                                                                                                                                                                                                  |
| Post comment  | `POST issues/{i}/comments` `{ "body", "clientRequestId": UUID }`                                                                                                                     | `201` (or `201` with the existing comment when the same `clientRequestId` is replayed by a board user): the `IssueComment`                                                                                                                                                                                                                                                                                                                                                                                                                                                                                | `400` empty body: `.refused`. Fabrix never sends `reopen`, `resume` or `interrupt` `[D4]`. A board comment on a closed or unblocked Blocked task assigned to an agent moves it to Todo and wakes the agent regardless `[D5]`.                                                                                                                                                                                                                 |
| Documents     | `GET issues/{i}/documents`                                                                                                                                                           | `[IssueDocument]` with `key`, `title`, `latestRevisionNumber`, `updatedByAgentId`, `updatedByUserId`, `updatedAt`, `body`. System documents are left out unless `includeSystem=true`, which Fabrix never sends.                                                                                                                                                                                                                                                                                                                                                                                           | `404` route: `.unsupported`.                                                                                                                                                                                                                                                                                                                                                                                                                  |
| Document      | `GET issues/{i}/documents/{key}`                                                                                                                                                     | `IssueDocument` with `body`, `latestRevisionNumber`, `latestRevisionId`                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   | `404 "Document not found"`: `.notFound`. `400 "Invalid document key"`.                                                                                                                                                                                                                                                                                                                                                                        |
| Revisions     | `GET issues/{i}/documents/{key}/revisions`                                                                                                                                           | `[DocumentRevision]`, newest first: `id`, `revisionNumber`, `title`, `body`, `changeSummary`, `createdByAgentId`, `createdByUserId`, `createdByRunId`, `createdAt`                                                                                                                                                                                                                                                                                                                                                                                                                                        | `404` route: `.unsupported` (the history button hides).                                                                                                                                                                                                                                                                                                                                                                                       |
| Work products | `GET issues/{i}/work-products`                                                                                                                                                       | `[IssueWorkProduct]`: `id`, `type` (`pull_request`, `branch`, `commit`, `preview_url`, `runtime_service`, `artifact`, `document`), `provider`, `title`, `url`, `status`, `reviewState`, `isPrimary`, `healthStatus`, `summary`, `metadata.downloadPath` and `metadata.contentType` for stored files, `createdByRunId`                                                                                                                                                                                                                                                                                     | `404` route: `.unsupported`. Unknown types map to `.other` and show without an action.                                                                                                                                                                                                                                                                                                                                                        |
| Stored file   | `GET {metadata.downloadPath}` through `PaperclipClient.download`, only when the path resolves to the factory's origin (`SameOriginRedirects.Origin`)                                 | file bytes, written to a temporary file named after `originalFilename`                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    | Another origin: no request; the row offers the browser instead `[D20]`.                                                                                                                                                                                                                                                                                                                                                                       |
| Active run    | `GET issues/{i}/active-run`                                                                                                                                                          | `200` with `null`, or `{ id, status, agentId, agentName, adapterType, startedAt, createdAt }`                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             | `404` route: `.unsupported`.                                                                                                                                                                                                                                                                                                                                                                                                                  |
| Live runs     | `GET issues/{i}/live-runs`                                                                                                                                                           | `[{ id, status ("queued" or "running"), agentId, agentName, startedAt, createdAt }]`                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      | `404` route: `.unsupported`.                                                                                                                                                                                                                                                                                                                                                                                                                  |
| Create        | `POST companies/{c}/issues` `{ "title", "description"?, "status"?, "priority", "assigneeAgentId"?, "assigneeUserId"? (Me only), "projectId"?, "parentId"?, "idempotencyKey": UUID }` | `201` with the new `Issue`, or `200` with the existing one and `deduplicated: true` when the key or a recent duplicate title matched                                                                                                                                                                                                                                                                                                                                                                                                                                                                      | `400 {error:"Validation error", details:[{path,message,code}]}`: `.refused` with the field paths. `422`, `409`: `.refused`.                                                                                                                                                                                                                                                                                                                   |
| Update        | `PATCH issues/{i}` with only the changed keys: `status`, `priority`, `assigneeAgentId` and `assigneeUserId` (one set, the other `null`), `projectId`                                 | the full updated `Issue` plus `changes` and `comment`. This is the new state; Fabrix reads nothing else.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  | `422 "in_progress issues require an assignee"`, `422 "Issue is blocked by unresolved blockers"` (`details.unresolvedBlockers`), `422 "Entering blocked requires unresolved blockers, a pending interaction/approval, or unblockDescriptor"`, `409 "Cannot assign work to terminated agents"` / `"…pending approval agents"` / invalid org chain, `404 "Agent not found"`, `404 "Project not found"`: all `.refused(Refusal)` with the reason. |
| Me            | `GET cli-auth/me`                                                                                                                                                                    | `userId`                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  | Any failure: `.unsupported`; Me and "You" are hidden `[D8]`.                                                                                                                                                                                                                                                                                                                                                                                  |

`Refusal` carries `status`, the server's `error` sentence, field paths from `details[].path`, and the identifiers from `details.unresolvedBlockers` when present. `PaperclipClient.perform` already keeps the `error` string; `TaskMapping` decodes `details` from the body leniently. It does not depend on `add-inbox`'s `ErrorBodyDTO.code/details` change; when both land, slice 12 folds the two decoders into one.

Unknown route versus missing resource: Paperclip answers an unknown `/api` route with `404 {"error":"API route not found"}` (`server/src/app.ts`). That body, or a `404` without a JSON error body, means `.unsupported`. Any other `404` means the resource is gone. Each unsupported answer is remembered for the factory session.

### 3. New `FactoryService` methods

Each has a default in `Tasks/FactoryService+Tasks.swift` that throws `FactoryServiceError.unsupported`. `DemoFactoryService` and `PaperclipFactoryService` implement all of them.

```swift
// MARK: Tasks
func taskDetail(taskID: WorkItem.ID) async throws -> TaskDetail
func boardUserID() async throws -> String
func comments(taskID: WorkItem.ID, after: TaskComment.ID?, limit: Int) async throws -> [TaskComment]
func addComment(taskID: WorkItem.ID, body: String, clientRequestID: UUID) async throws -> TaskComment
func documents(taskID: WorkItem.ID) async throws -> [TaskDocument]
func document(taskID: WorkItem.ID, key: String) async throws -> TaskDocument
func documentRevisions(taskID: WorkItem.ID, key: String) async throws -> [DocumentRevision]
func workProducts(taskID: WorkItem.ID) async throws -> [WorkProduct]
func workProductFile(_ product: WorkProduct) async throws -> URL
func taskRuns(taskID: WorkItem.ID) async throws -> TaskRunPresence
func createTask(companyID: Company.ID, draft: TaskDraft, idempotencyKey: UUID) async throws -> WorkItem
func updateTask(taskID: WorkItem.ID, change: TaskChange) async throws -> WorkItem
```

`TaskChange` is `.status(TaskStatus)`, `.priority(TaskPriority)`, `.assignee(TaskAssignee)` or `.project(Project.ID?)`. `taskRuns` reads `active-run` and `live-runs` in parallel and returns `{ active: LinkedRun?, queued: [LinkedRun] }`.

How each screen treats `.unsupported`:

| Method                  | Screen behavior                                                                                                                                          |
| ----------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `taskDetail`            | The detail shows today's content (assignee, updated, live run, Wake agent). Other parts don't load. Edits through menus still work if `updateTask` does. |
| `boardUserID`           | Me is hidden from the assignee menu; own comments read "Board member".                                                                                   |
| `comments`              | No thread and no composer.                                                                                                                               |
| `addComment`            | Thread read-only; the composer says this factory doesn't accept comments from Fabrix.                                                                    |
| `documents`, `document` | No documents section (embedded `planDocument` still shows when present).                                                                                 |
| `documentRevisions`     | No History button.                                                                                                                                       |
| `workProducts`          | No work products section (embedded ones still show).                                                                                                     |
| `workProductFile`       | Stored files open in the browser instead.                                                                                                                |
| `taskRuns`              | Runs section shows only the finished runs from the snapshot.                                                                                             |
| `createTask`            | New task shows the "not available on this factory" sheet.                                                                                                |
| `updateTask`            | Field rows, drag, context-menu edits and Task menu edits are hidden; the detail is read-only.                                                            |

### 4. Where state lives

`TaskStore` is a `@MainActor @Observable final class` in `FabrixFeatures/Tasks/`. It holds, per task ID: detail load state, comments, pending comments (sending or failed, keyed by `clientRequestID`), composer drafts `[D13]`, documents, revisions, work products, run presence and download progress; the set of unsupported methods; the board user ID; and a `TaskEditDesk`.

It reads the current service, factory ID, company ID and a generation number through a `TaskContext` value that `AppModel` builds. Every response is applied only if its context's generation still matches, so nothing from a previous factory or company lands. When the generation changes, `TaskStore` drops its caches on its next access, so `AppModel.use(_:)` and `select(_:)` need no new call.

`AppModel` changes are limited to these, in two hunks:

- next to the other stored properties: `let taskStore = TaskStore()` and a `var taskContext: TaskContext` computed from `service`, `factory`, `selectedCompanyID` and `generation` (about 8 lines);
- in `commitStagedDecisions()`: `await taskStore.commitStaged(taskContext)` (1 line), added in slice 8.

Overlay: the board and the detail read tasks through `taskStore.overlay(model.visibleTasks)`, which applies held edits and the last server answers. A server answer stays in the overlay until a snapshot arrives whose task `updatedAt` is at least as new. That way a 20-second poll that started before the PATCH can't move the card back.

`TaskEditDesk` is pure, like `ApprovalDesk`: task ID → `StagedEdit { change, previous, stagedAt, generation }`, with `stage`, `undo`, `beginCommit`, `finish` and `restage`. A second change to the same task while one is held replaces it and keeps the original `previous`. It doesn't depend on `add-inbox`'s `InboxDesk`; both follow `ApprovalDesk`'s tested semantics. Folding the three is a Phase 5 refactor.

### 5. Undo window and confirmations

| Action                             | Confirmation                                                | Undo                                   | Why                                                                                |
| ---------------------------------- | ----------------------------------------------------------- | -------------------------------------- | ---------------------------------------------------------------------------------- |
| Status change (drag, menu, keys)   | none                                                        | held 8 s, then sent `[D1]` `[D2]`      | can wake the assignee, dependents or parent                                        |
| Assignee change                    | none                                                        | held 8 s, then sent `[D1]`             | wakes the new assignee                                                             |
| Priority, project                  | none                                                        | sent at once; Undo sends the old value | wakes nobody                                                                       |
| Comment                            | none                                                        | none; sending and failed states `[D6]` | the user's deliberate message                                                      |
| Comment that reopens a closed task | "Sending reopens this task and wakes {agent}" dialog `[D5]` | none                                   | changes status and wakes an agent                                                  |
| Create, New subtask                | the form's Create button                                    | none                                   | creates something new; Paperclip has no delete for a board user that Fabrix offers |
| Open a stored file                 | none                                                        | none                                   | read only                                                                          |

No task action asks for Face ID `[D17]`. Held edits are sent when the window ends, on Send now, when the app leaves the foreground (through `commitStagedDecisions()`, which `RootView` already calls), and before a factory or company switch. A held edit rejected with `401` stays held until the user signs in again, as approvals do. An edit held for a company that is no longer selected is sent before the switch, never after it.

### 6. Refusals and reverting

When `updateTask` throws `.refused(refusal)`:

1. The overlay entry for that task is removed, so the card and the detail show the snapshot's state. On the board the card moves back (fades back with Reduce Motion) and shows the refused outline for 2 seconds.
2. The undo bar turns into a notice: the plain sentence for known reasons ("Assign this task before moving it to In progress", "Blocked by ATL-140 and ATL-141", "This agent can't take work: {server reason}") or the server's sentence in quotes. It is a live region.
3. Nothing is retried. The store refreshes that task's detail.

A transport error removes the overlay entry and offers Retry, which stages the same change again. Before anything is sent, `DropRules` refuses drops that Paperclip would refuse `[D18]`: In progress for an unassigned task, and Blocked unless the task's loaded detail lists an unresolved blocker. Offline (no connection or signed out), every edit is disabled with the reason and nothing is queued.

### 7. Drag and drop, menus and keyboard

- **iPad and Mac:** each `TaskCard` is `.draggable(TaskDragItem(id))` (a `Transferable` with a custom UTType, so it never drops as text into other apps). Each `BoardColumn` has `.dropDestination(for: TaskDragItem.self)` and shows `DropVerdict` (`.moves(to:)`, `.refused(reason)`, `.none`) while targeted. A drop stages a status change.
- **iPhone:** no drag between sections. Long press opens the context menu.
- **Every card:** a context menu with Move to (each status, Cancelled last `[D19]`), Assign, Set priority, Set project, Comment, New subtask, and on Mac Open in new window. The same verbs are VoiceOver custom actions, so nothing needs a drag.
- **Task menu** (`TaskCommands`, using `FocusedValue` for the selected task): New task ⌘N (the existing toolbar shortcut moves here), New subtask ⇧⌘N, Open in new window ⌘O (macOS), Comment ⌥⌘C, Plan history ⇧⌘H, Assign ⇧⌘A, Set project ⇧⌘P, status ⌃⌘1–7 `[D16]`, priority ⌃⌥1–4, Undo ⌘Z inside the window. ⌘1–9 stay company switching. Each slice adds the commands for what it ships.
- **Mac windows:** `WindowGroup(for: TaskWindowID.self)` where `TaskWindowID` is `{ factoryID, companyID, taskID }`. The window reads the shared `AppModel` and `TaskStore`. When the open factory or company no longer matches, it shows "This task belongs to a factory that's no longer open" with Close.

### 8. Markdown

`MarkdownView` parses with `AttributedString(markdown:options:)` using `.full` interpreted syntax and walks the runs' `presentationIntent` to group blocks: headings, paragraphs, ordered and unordered lists (nested), code blocks, block quotes, thematic breaks and tables. Inline styles come from the attributed runs. Each block is a SwiftUI view using the Fabrix type styles, so Dynamic Type applies. Links call an `openLink` closure; FabrixFeatures opens `http` and `https` links and task links (`/ATL-142`) in-app. Images become links with their alt text `[D12]`. If parsing throws, the raw text shows. No package is added; `Package.swift` doesn't change. Parsing runs off the main actor for bodies over 20 KB.

### 9. Runs on a task

The runs section merges three sources `[D3]`: `taskRuns` (active run first, then queued), and the finished runs among `snapshot.runs` whose task is this one. The snapshot's runs already carry their task, and the snapshot loads the company's 50 most recent. The section ends with "Older runs aren't shown" when the oldest loaded company run is newer than the task's creation. Phase 3 turns each row into a link to the run's transcript. A Paperclip pull request for `?issueId=` on `/companies/{id}/heartbeat-runs` is the follow-up that removes the gap.

### 10. Work products

`WorkProduct.opening` is `.browser(URL)` for an `http` or `https` `url`, `.quickLook(path)` for an artifact whose `metadata.downloadPath` resolves to the factory origin, and `.none` otherwise `[D20]`. Quick Look uses `QLPreviewController` on iOS and iPadOS and `QLPreviewPanel` on macOS, wrapped in FabrixFeatures. Downloads go to the app's temporary directory with complete file protection and are deleted when the detail closes. The demo's stored file is a bundled Markdown file.

### 11. Demo factory

`DemoTaskWork` (new file) holds the demo's task data; `DemoFactoryService` gains one stored property `var taskWork: DemoTaskWork` and its initialization at the end of `init`, and `tasks` loses `private` so the extension in `DemoFactoryService+Tasks.swift` can apply edits. Data:

- Priorities on every task (ATL-142 Critical, ATL-147 High, ATL-160 Low, the rest Medium), applied by ID at the end of `init`.
- ATL-142: description with a list and a code block, parent ATL-100 "Sync reliability" under root ATL-90 "Platform v2", blocked by ATL-147, labels "backend" and "sync", a thread with CTO, You, Priya (a user, shown as "Board member" until slice 11) and a system comment, a plan with 3 revisions and a "notes" document, work products: a pull request (healthy), a preview URL (unhealthy), a branch and a stored file, and runs: live (r1), queued, and finished ones.
- ATL-151: a plan and a pull request; ATL-160: no assignee, so In progress is refused locally and by the demo `[D18]`.
- ATL-152 is the marked task whose move to In progress the demo refuses like the server, to reach the refusal path even with an assignee.
- `createTask` and `updateTask` change the demo state; created tasks get `ATL-161` and up.

### 12. Telemetry

No new spans or attributes. URL session spans for task routes are already templated, except document keys. Slice 4 changes `AttributeScrubber.template(_:)` so the segment after `documents` is replaced by `{key}` (`/api/issues/{id}/documents/{key}/revisions`). It doesn't touch `scrub(attributes:)`, which `add-inbox` slice 2 changes. Request and response bodies, where titles, descriptions, comments, document bodies and work product links travel, are never recorded. `TaskStore` logs failures with the status code and the method name only. Tests: `AttributeScrubberTests.documentKeyIsTemplated` (slice 4) and `ScrubbingExporterTests.taskErrorLogsCarryNoText` (slice 3: a failed comment post and a refused edit log no comment text, title or reason).

### 13. Accessibility

- **VoiceOver:** a card is one element read as "identifier, title, status, priority, assignee, running". Its custom actions match the context menu. The undo bar and refusal notices are live regions. A comment reads author, time, text. After a refused create, focus moves to the first field the server named.
- **Dynamic Type:** on iPhone, field rows stack label above value, pills wrap one per line, and the composer's arrow becomes a labelled Send button. At accessibility sizes the iPad and Mac board becomes the grouped list, with the detail beside it.
- **Reduce Motion:** refused cards fade back, lifted cards don't tilt, placeholders are static, countdowns are text, new comments fade in (`fabrixTransition`).
- **Color:** status has a dot shape and a word, priority bars and a word, refusals say what happened in text.

### 14. Avoiding conflicts with `add-inbox`

Both lanes edit some files at the same time. Rules:

- New code goes in new files (`Tasks/` folders in Core, Design and Features).
- `FactoryService.swift`: Phase 2 adds its requirements in one `// MARK: Tasks` block directly after `snapshot(companyID:)`, and later slices add lines only inside that block. `add-inbox` appends after `projects(companyID:)`, so the hunks don't touch. Defaults go in a new file. The one new error case goes directly after `case unsupported`.
- `Models.swift`: only Phase 2 edits it.
- `DemoFactoryService.swift`: Phase 2 edits the `tasks` declaration, adds one stored property after it, and one line at the end of `init`. Everything else is in new files.
- `AppModel.swift`: two hunks, about 9 lines (section 4).
- `AppSection.swift`: one appended `.navigationDestination(for: TaskRoute.self)` in `fabrixDestinations()` (slice 2).
- `AttributeScrubber.swift`: only `template(_:)` (slice 4).
- String catalogs: after a rebase, conflicts are resolved by re-running `scripts/sync-string-catalogs.sh`, never by hand.
- Only one open session at a time edits each of these files across both lanes. The slice table in tasks.md says which slice touches which.

### 15. Docs

Each slice adds its endpoints to a new "Tasks" section of `docs/paperclip-api.md`, in the same PR as the call: the request, fields read, error mapping, fallback and version notes (the missing `activeRun` in the detail, the implicit reopen on comments, the lack of per-task run history).

## Risks / Trade-offs

- [The detail endpoint is heavy on the server (about 15 joined reads)] → It's read once per opened task and on refresh while open, not per poll for every task. `view=core` exists for a lighter read but lacks relations; not used.
- [Held status changes look done before they are] → The undo bar counts down in text and says "Moved" when sent. A refusal reverts with a reason.
- [A poll can race a PATCH] → The overlay keeps the server's answer until a newer snapshot arrives (section 4).
- [A comment on a closed task reopens it and wakes the agent] → Confirmation `[D5]`, and `docs/paperclip-api.md` records the server rule.
- [Finished runs older than the company's last 50 are missing] → The list says so `[D3]`, and the upstream filter is the fix.
- [Stored files may live on another host] → Credentials are sent only to the factory origin; otherwise the browser opens the link.
- [Two staged-action desks plus `ApprovalDesk`] → Same semantics and tests; folding them is Phase 5 work.
- [Lane conflicts in shared files] → Section 14, and the slice table names each touch.

## Migration Plan

The change is additive and ships as the 12-slice stack in tasks.md. Every layer can ship:

- After slice 2, the board shows priority and opens a read-only task detail.
- Slices 3–6 add the thread, documents, work products and runs.
- Slices 7–8 add create and edit; slices 9–10 add drag and drop, menus, keys and windows.
- Slice 11 connects the inbox once `add-inbox` has landed.

To roll back, revert the stack. Servers without an endpoint never see that part.

## Open Questions

None that change the specs or tasks. Items Paperclip's source didn't settle are checked in the sandbox in task 12.2:

- how `after` pages comments with `order=desc`;
- whether a stored file's `downloadPath` needs the board key or is public;
- the exact `409` wording for each assignee refusal on the pinned image;
- what servers older than the pinned image answer for `active-run`, `live-runs`, documents, revisions and work products;
- the keys inside `usageJson` (run cost), which the run rows leave out until Phase 3.
