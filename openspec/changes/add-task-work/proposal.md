## Decisions for the owner

Each item lists the options, the recommendation (marked **Rec**) and why. The specs, design and tasks follow the recommendations. Every place that changes with a different answer carries a marker `[D<n>]`, so a search for the number finds it. Items 1–14 answer the 14 open questions in the Phase 2 design notes (their numbers are in brackets); the rest came up while checking Paperclip's source at `890dcbdd`.

1. **Undo for status and assignee changes** (design question 1). Paperclip wakes the assignee when a task is assigned to it, and when its status leaves Backlog, goes from Blocked, Done or Cancelled to Todo, or goes from In review to Todo. Moving a task to Done wakes the tasks it blocks and its parent. A PATCH back clears `completedAt`, but it can't take back a wake. Options: (a) hold every status and assignee change in the undo window and send it when the window ends; send priority and project changes at once, and have Undo send the old value back; (b) the design's plan: send every drop at once, Undo sends the old status back, and only drops on Done or Cancelled wait; (c) hold only the changes that Paperclip's current rules say wake someone. **Rec: (a).** One rule covers every change that can wake an agent, and it doesn't copy wake rules that change upstream.
2. **Length of the undo window.** Options: (a) 8 seconds, the same as approvals and the inbox; (b) 6 seconds, as drawn. **Rec: (a).** One undo bar that behaves the same everywhere.
3. **Runs on a task** (design question 2). The roadmap asks for "linked runs, with the live one on top". Paperclip has no run history per task: `GET /companies/{id}/heartbeat-runs` filters by agent, not by task. Options: (a) the live and queued runs from `/issues/{id}/active-run` and `/issues/{id}/live-runs` on top, then the finished runs of this task found among the company's 50 most recent runs, which Fabrix already loads, with a line saying older runs aren't listed; (b) also read each run that a comment, revision or work product names (`createdByRunId`) with `GET /heartbeat-runs/{id}`, one request each; (c) live runs only. **Rec: (a)**, and send Paperclip a pull request for an `issueId` filter on `heartbeat-runs`. The bullet can't be delivered in full as written: finished runs older than the company's last 50 are missing until that filter exists.
4. **Interrupt from the composer** (design question 3). A board comment may cancel the active run (`interrupt`). Options: (a) not in Phase 2; (b) a "Stop the run and read this now" toggle with a confirmation. **Rec: (a).** Stopping a run is Phase 3 and gets its own confirmation there.
5. **A comment reopens a closed task** (design question 4). The design proposed a "Reopen the task" toggle, off by default. Paperclip doesn't allow that: a board user's comment on a Done or Cancelled task, or on a Blocked task with no unresolved blockers, that is assigned to an agent always moves it to Todo and wakes the agent. `reopen: false` doesn't stop it. Options: (a) the composer says "Sending reopens this task and wakes {agent}", and Send asks for confirmation; (b) the same notice without a confirmation; (c) no composer on closed tasks. **Rec: (a).** It wakes an agent and changes the status, so principle 2 asks for a confirmation.
6. **Plain comments.** A comment usually wakes the assignee. Options: (a) send at once, with sending and failed states, like the inbox's approval comments (`add-inbox` D20); (b) hold each comment in the undo window. **Rec: (a).** Steering the agent is the point of a comment, the user pressed Send on purpose, and a comment that lands 8 seconds later reads out of order.
7. **Title required** (design question 5). The server accepts a description alone. Options: (a) Fabrix asks for a title; (b) title or description. **Rec: (a).** The board always has something to show.
8. **People as assignees** (design question 6). Options: (a) agents, Me and Unassigned; (b) also every company member from `add-inbox`'s people list, sent as `assigneeUserId`. **Rec: (a).** It needs nothing from Phase 1, and Me covers the common case. "Me" comes from `GET /cli-auth/me` and is hidden when that is unavailable.
9. **Several cards at once** (design question 7). Options: (a) not in Phase 2; (b) multi-select with context-menu edits on Mac and iPad, one PATCH per task and one Undo for the batch, as drawn. **Rec: (a).** No roadmap bullet asks for it, and partial failures in a batch need their own design. It can follow as its own change.
10. **Status change with a note** (design question 8). PATCH takes `comment`. Options: (a) not in Phase 2; comments and edits stay separate; (b) an optional note on each change. **Rec: (a).** Same as the design.
11. **Blockers, labels, description, goal and parent** (design question 9). Options: (a) shown read-only; (b) editable. **Rec: (a).** The roadmap lists only status, priority, assignee and project as editable. The source shows that `GET /issues/{id}` always carries `labels`, so labels are shown as chips.
12. **Markdown** (design question 10). Options: (a) Foundation's `AttributedString(markdown:)` with its block structure (`PresentationIntent`), drawn by a small SwiftUI renderer in FabrixDesign, with no new package; (b) Apple's swift-markdown package; (c) a third-party Markdown view. **Rec: (a).** It covers headings, lists, code, quotes, tables and links without a dependency. Images show as links, because the factory may need credentials to serve them.
13. **Drafts** (design question 11). Options: (a) unsent comments and new-task forms are kept in memory per task while the app runs; (b) also written to a data-protected file, as drawn. **Rec: (a).** Phase 5 adds the encrypted on-disk cache. Drafts move there with it, so this change adds no file storage.
14. **Create on iPhone** (design question 12). Options: (a) + in the Tasks toolbar and New subtask in a task's menu, nothing in the inbox; (b) also in the inbox. **Rec: (a).** Same as the design.
15. **Detail from one request** (design question 13). `GET /issues/{id}` embeds the plan (`planDocument`, with its body), `documentSummaries`, `legacyPlanDocument` (a plan kept in the description) and `workProducts`. The design notes said it also embeds `activeRun`. The source shows it doesn't. Options: (a) use the embedded fields when present and fall back to the separate endpoints when they are missing; always read runs separately; (b) always use the separate endpoints. **Rec: (a).** One request fills most of the detail on current servers, and older servers still work.
16. **Mac keys** (design question 14). ⌃1–7 collides with "Switch to Desktop n" when that is turned on. Options: (a) ⌃⌘1–7 for status, ⌃⌥1–4 for priority; (b) keep ⌃1–7. **Rec: (a).** ⌘1–9 stay company switching, and ⌘O opens the selected task in its own window (in the inbox, ⌘O stays "Open task").
17. **Face ID on task edits.** Options: (a) no; (b) "Confirm approvals" also covers Done and Cancelled. **Rec: (a).** Edits aren't approvals, the undo window covers mis-taps, and `add-inbox` already rewrites that requirement.
18. **Drops the server would refuse.** Paperclip refuses In progress without an assignee (`422 "in_progress issues require an assignee"`) and Blocked without an unresolved blocker or a pending request (`422 "Entering blocked requires unresolved blockers, a pending interaction/approval, or unblockDescriptor"`). Options: (a) the column shows "Assign it first" or "Blocked comes from blockers in Paperclip" and refuses the drop before anything is sent; the server's answer still decides in every other case; (b) send it and show the refusal. **Rec: (a).** A refusal the app can see coming shouldn't cost a round trip and a bouncing card.
19. **Cancelled.** The board hides cancelled tasks today. Options: (a) Cancel stays off the board and is offered in the status menu, context menu and Task menu; (b) a Cancelled column. **Rec: (a).** The board keeps six columns, and cancelling stays a deliberate menu choice.
20. **Work products** (design notes, unverified items). Options: (a) a link (`url` with `http` or `https`) opens in the browser; an artifact stored by Paperclip (metadata with `downloadPath`) is downloaded through Fabrix's own connection and shown in Quick Look; (b) everything opens in the browser. **Rec: (a).** A Paperclip-stored file needs the board credential, which the browser may not have.
21. **Names of people in the thread.** A comment's user author is an ID. Names come from `add-inbox`'s people list. Options: (a) before that lands, the thread says "You" for the signed-in user and "Board member" for others; the last slice switches to names; (b) the thread slice waits for `add-inbox` slice 2. **Rec: (a).** It keeps the two lanes independent until the last slice.
22. **Long threads.** Options: (a) load the newest 100 comments, show them oldest first, and load new ones on refresh with `after`; older ones open in Paperclip; (b) load up to the server's maximum of 500. **Rec: (a).** It keeps the thread fast on a phone. How `after` pages backwards isn't clear from the source; the sandbox checks it (task 12.2).

## Why

A task in Fabrix is a card. The user can't read it, talk to its agent, see its plan, create a task or move one. Comments are how a board user steers an agent, so today steering means leaving the app. Roadmap Phase 2 turns the task board into something the user works from on iPhone, iPad and Mac.

## What Changes

- **Task detail** from `GET /issues/{id}`: description (Markdown), status, priority, assignee, project, goal, labels, parent chain, and the tasks that block it or that it blocks `[D11]`. Detail pushes onto the stack on iPhone, opens beside the board on iPad and Mac, and opens in its own window on Mac.
- **The thread**: comments read with `GET /issues/{id}/comments` and written with `POST /issues/{id}/comments`, with the composer one tap away. Comments send at once `[D6]`. Commenting on a closed task asks first, because it reopens the task `[D5]`.
- **Documents**: the plan and other keyed documents as rendered Markdown, with revision history, read-only `[D12]` `[D15]`.
- **Work products** from `GET /issues/{id}/work-products`, opened in the browser or in Quick Look `[D20]`.
- **Runs**: the live run on top, then queued runs, then the recent finished runs Fabrix knows about `[D3]`.
- **Create** with `POST /companies/{id}/issues`, replacing the `NewTaskSheet` placeholder, plus New subtask `[D7]` `[D14]`.
- **Edit** status, priority, assignee and project with `PATCH /issues/{id}`. The response is the new state, so nothing is read twice. Status and assignee changes wait for the undo window `[D1]` `[D2]`. A refused change puts the card back and says why.
- **Board**: priority on every card; drag and drop between columns on iPad and Mac with a non-drag path for VoiceOver and keyboards `[D18]` `[D19]`; a context menu on every card; a Task menu with shortcuts on Mac and on iPad with a keyboard `[D16]`.
- **Inbox**: "Open task" opens the new task detail once `add-inbox` has landed.
- Every new call falls back: a server without an endpoint hides that part of the screen, and nothing shows as broken.
- The demo factory gets details, threads, documents with revisions, work products and runs for its tasks.
- `docs/paperclip-api.md` gains a Tasks section, updated in the same PR as each call.

Not in this change: editing documents (roadmap open decision 3), editing description, blockers, labels, goal or parent `[D11]`, multi-select `[D9]`, people other than Me as assignees `[D8]`, interrupting a run `[D4]`, run transcripts (Phase 3), drafts on disk `[D13]`.

Platforms: iOS, iPadOS and macOS ship together in every slice. Targets: FabrixCore, FabrixDesign, FabrixFeatures, FabrixTelemetry (the document key in URL paths is templated) and the app shell (`App/Shared/FabrixApp.swift` gains a task window scene on macOS).

`FactoryService` changes are additive. It gains 12 methods, each with a default that throws `FactoryServiceError.unsupported`, and one error case, `FactoryServiceError.refused(String)`, which carries the server's reason for a refused edit. No existing method changes. `WorkItem` gains a `priority` with a default, so every existing initializer call still compiles.

## Capabilities

### New Capabilities

- `task-detail`: reading a task: detail, thread and composer, documents and revisions, work products, runs, and their fallbacks.
- `task-editing`: creating a task, editing status, priority, assignee and project, the undo window, refusals, drag and drop, context menus, Mac windows and keyboard commands.

### Modified Capabilities

- `task-board`: cards show priority; the board's detail is the new task detail; tasks move between columns.
- `navigation`: New task creates a task instead of showing a placeholder.
- `factory-service`: task detail, comments, documents, work products, runs, create, update, the signed-in user, the refused error and demo task data.
- `design-system`: task components that take plain values only, including a Markdown view.
- `telemetry`: task requests carry no titles, descriptions, comment text, document bodies or document keys.
- `inbox` (added by `add-inbox`): "Open task" opens the task detail. This delta applies only after `add-inbox` is archived, and its slice is last in the stack.

## Impact

- FabrixCore:
  - New task model types in `Tasks/TaskModels.swift`. `Models.swift` changes by one stored property on `WorkItem` (`priority`, default `.medium`).
  - The new `FactoryService` requirements sit in one `// MARK: Tasks` block in `FactoryService.swift`. Their defaults live in `Tasks/FactoryService+Tasks.swift`.
  - DTOs and mapping in `Paperclip/TaskDTOs.swift` and `Paperclip/TaskMapping.swift`; live methods in `Paperclip/PaperclipFactoryService+Tasks.swift`.
  - Demo task data in `DemoFactoryService+Tasks.swift` and `DemoTaskWork.swift`. `DemoFactoryService.swift` changes by a few lines.
  - Sandbox contract tests.
- FabrixDesign: 16 components listed in `design.md`, with previews and catalog strings.
- FabrixFeatures:
  - A new `Tasks/` folder: `TaskStore` (state and actions), `TaskEditDesk` (staged edits, pure), the detail, thread, documents, create and command views.
  - `AppModel` gains only a `taskStore` property, a context accessor and one line in `commitStagedDecisions()`.
  - `TasksView` gets priority, drag and drop and context menus. `NewTaskSheet` is replaced.
- FabrixTelemetry: `AttributeScrubber.template` replaces the document key in `/documents/{key}` paths.
- App shell: a task window scene on macOS.
- Docs: `docs/paperclip-api.md`.
- Test doubles that conform to `FactoryService` keep compiling, because every new method has a default.
- Seed script: `scripts/paperclip-sandbox-seed.sh` gains a task with comments, a plan with two revisions, a work product and a blocker.
- No new package dependency `[D12]`.
