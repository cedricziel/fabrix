# Fabrix roadmap

This is the plan for turning Fabrix from a monitor into the app a board user runs a Paperclip factory from, on iPhone, iPad and Mac. It is directional. Each phase becomes one or more OpenSpec changes before any code is written, and the order can change as we learn.

Written against Fabrix 0.4.0 and Paperclip `890dcbdd` (main on 2026-11-14). Endpoint names come from Paperclip's `docs/api` and `server/src/routes`.

## Where Fabrix is today

Fabrix reads a company snapshot every 20 seconds and shows it in seven sections: overview, projects, tasks, agents, org chart, approvals and activity. A user can do three things. They can approve or reject an approval, wake or pause an agent, and pause a company.

What works well and must stay that way:

- Views only talk to `FactoryService`. The demo factory and the live server sit behind the same protocol.
- Credentials live in the Keychain. Fabrix sends them over plain HTTP only to private networks and never follows a redirect to another origin.
- Approval decisions wait 8 seconds before they reach the server, so a mis-tap can be undone.
- Stale responses can't overwrite newer state, even across factory switches.

What is missing:

- A task is a card. There is no detail view, no comments, and no way to create or change one. `NewTaskSheet` is a placeholder.
- Agents ask humans questions inside task threads. Fabrix doesn't show them.
- Nothing tells the user they are needed unless the app is open.
- A run is a row with a timer. The user can't see what the agent is doing or why it failed.
- Each poll makes about nine requests and downloads up to 500 full issues. Factories with more tasks lose the rest without notice.

## What each device is for

One codebase, but the devices have different jobs. Every phase below says what it means for each.

| Device | Job                                                                   | What that asks of the design                                                                                   |
| ------ | --------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------- |
| iPhone | Triage. Answer what is waiting, check that nothing is on fire, leave. | One-handed. The inbox is the first screen. Every decision is reachable from a notification.                    |
| iPad   | Review. Read a plan, compare it with the task, decide.                | Split view with the list beside the detail. Drag and drop on the board. Works with a keyboard and without one. |
| Mac    | Operate. Keep the factory open all day beside other work.             | Multiple windows, a menu bar item, keyboard shortcuts for everything, dense tables.                            |

## Principles

1. Fabrix is for triage and steering. Configuration stays in Paperclip's web UI. See "What we leave to the web UI".
2. Any action a user can't take back waits for an undo window or asks for confirmation. Approvals already work this way. Stopping a run and withdrawing a request follow the same rule.
3. A feature the server lacks is hidden, not broken. Self-hosted factories run different Paperclip versions. Projects already fall back with `FactoryServiceError.unsupported`. Every new endpoint gets the same treatment.
4. Each feature ships on all three devices in the same release, laid out for that device. No iPhone-only or Mac-only data features. Platform extras such as widgets and the menu bar item are the exception.
5. VoiceOver, Dynamic Type, Reduce Motion and the string catalogs are part of each feature's definition of done.

## Phase 0: fix what is promised

Small, and first, because these are defects in what already ships.

- `AppModel.followStoreChanges()` swaps in the new service when another window signs in again, but leaves `signedOutReason` set. The window stays on the signed-out screen. Call `renew(_:)` there and add the missing test.
- The README says "work the task board" and "watch agent runs live". Neither is true yet. Reword until phases 2 and 7 land.
- Several doc comments in `AppModel` sit above the wrong function. The two messages in `signInFailure` skip the string catalog.
- `CLAUDE.md` doesn't list the `FabrixTelemetry` target.

## Phase 1: the inbox

Replace the Approvals section with an inbox of everything that waits for the user.

Paperclip's web UI has moved from an approvals list to an attention inbox. It merges approvals, decisions and the questions agents ask in task threads, and routes each to a person. Fabrix shows four approval types and none of the rest, so a Fabrix user misses most of what their agents are waiting on.

Scope:

- List the cards from `GET /companies/{id}/attention` with the views mine, unassigned and company.
- Answer each kind of card in place. Approvals keep approve and reject. Interactions add accept, reject with a reason, answer questions, and per-item verdicts through `/issues/{id}/interactions/{id}/accept|reject|respond|verdicts`.
- Claim, transfer, snooze, archive and withdraw.
- Decision history from `/attention/history`.
- Show the approval's full payload and its comments. Add "request revision" with a note.
- When the server answers `409` with `attention_already_closed`, say who decided and refresh. Don't retry.
- Badge the tab and the app icon with `deskBadgeCount`.

Per device:

- iPhone. The inbox becomes the first tab. Swipe to snooze or archive. Decisions keep the Face ID confirmation and the undo window.
- iPad. List on the left, the card with its task context on the right.
- Mac. Same split, with shortcuts for next, previous, approve, reject and snooze.

Fallback: a server without `/attention` keeps today's Approvals screen.

## Phase 2: tasks you can work

Scope:

- Task detail from `GET /issues/{id}`: description, status, priority, assignee, project, goal, parent chain, blockers.
- The thread. Read and write comments with `/issues/{id}/comments`. Comments are how a board user steers an agent, so the composer is always one tap away.
- Documents. Show the plan and other keyed documents from `/issues/{id}/documents/{key}` as rendered Markdown, with revision history. Read-only at first.
- Work products from `/issues/{id}/work-products`, opened in the browser or Quick Look.
- Create a task with `POST /companies/{id}/issues`. This replaces the `NewTaskSheet` placeholder.
- Edit status, priority, assignee and project with `PATCH /issues/{id}`. The response is the new state, so no second read.
- Linked runs, with the live one on top, from `/issues/{id}/active-run`.

Per device:

- iPhone. Detail pushes onto the stack. Status and assignee change from a menu.
- iPad. Drag cards between columns. Detail opens beside the board.
- Mac. Drag and drop, a context menu on every card, Cmd-N for a new task, and a task can open in its own window.

## Phase 3: runs and agents you can read

Scope:

- Run detail. The transcript from `/heartbeat-runs/{id}/events` and `/log`, with tool calls collapsed by default. Cost, duration and exit reason.
- Stop a live run with `/heartbeat-runs/{id}/cancel`. Retry a stopped task with `POST /issues/{id}/retry`, sending an idempotency key and the run the user saw.
- Agent detail. Role and reporting line, current task, recent runs, spend against its budget, and instructions read-only.
- For an agent in the error state, show the last failed run's reason on the agent row. The user shouldn't need three taps to learn why.

Per device:

- iPhone. Transcript in a sheet, newest at the bottom.
- iPad and Mac. Transcript in a third column or an inspector, so the task stays visible beside it. On Mac, text in the transcript is selectable and searchable.

## Phase 4: know without opening the app

Paperclip has no push support, so this phase has two steps.

Step one needs no server:

- Background refresh on iOS and iPadOS asks `/attention/summary` for each saved factory and posts a local notification when the count for the user rises. Timing is up to the system, so the copy must not promise instant alerts.
- On Mac, the app keeps polling while it runs and posts the same notifications.
- Notification actions for approve and reject, behind Face ID or Touch ID, using the same undo window.
- Notification settings per factory and per kind: needs me, agent error, budget threshold.

Step two is a decision, not a task. Real push needs a relay that the factory calls and that talks to APNs. Someone has to run it, and it sees notification metadata. See "Open decisions".

## Phase 5: lighter and complete loading

Do this before the native extras in phase 8, because widgets and background refresh need cheap requests.

- Overview reads `GET /companies/{id}/dashboard`. One request replaces most of the snapshot for that screen.
- The board loads `issues?view=index` for order and status, then fetches visible rows in batches of up to 50 with `ids`. This removes the 500-task cap.
- Page activity and runs. Use `/live-runs` for the live strip.
- Split `CompanySnapshot` so each section loads and fails on its own, the way projects already do.
- Cache the last good state on disk, encrypted with the device, so the app opens to content and marks it as stale. Staged decisions already survive a signed-out period; they should survive a relaunch too.
- Break up `AppModel`, which is 1,091 lines. Sign-in, loading, the inbox and actions become separate types behind the same observable model. Do this as the phases touch each area, not as one big refactor.

## Phase 6: find things and see the money

- Search across tasks, comments, documents, agents and projects with `GET /companies/{id}/search`. Cmd-K on Mac and iPad, pull-down on iPhone.
- Index recently seen tasks and agents in Spotlight. Register `fabrix://` links for tasks, agents and approvals so links from Slack and email open the right screen.
- Costs with Swift Charts: spend by agent, project and provider from `/costs/by-agent`, `/costs/by-project`, `/costs/by-provider`, and budgets from `/budgets/overview`. Add a simple month-end forecast from the current burn rate.
- An inbox across every saved factory and company, so a user with three factories has one list.
- Goals as a read-only section, since tasks and projects already reference them.

## Phase 7: live

The event stream exists at `/api/companies/{id}/events/ws` and carries run status, logs, tool progress, agent status and activity. Fabrix can't use it on most factories. The socket checks a bearer token only against agent keys, so it rejects board keys. Without a token it works only on a `local_trusted` server.

- Send Paperclip a pull request that accepts board API keys on the socket.
- Then subscribe while the app is in the foreground, apply events to the loaded state, and fall back to polling when the socket drops or the server is older.
- Stream the transcript in run detail.
- Restore "watch agent runs live" in the README.

This phase waits on upstream, so it can move earlier or later without blocking anything else.

## Phase 8: native extras

Each of these reads the cheap endpoints from phases 4 and 5.

- Widgets for the Home Screen, Lock Screen and Mac desktop: waiting for me, running agents, budget used.
- A Live Activity for a run the user chose to follow. Needs phase 7 or frequent background updates to be honest about progress.
- A menu bar item on Mac with factory status and the top inbox cards.
- App Intents for Siri, Shortcuts and Spotlight: "what's waiting for me", "pause the factory", "wake an agent". Focus filters that pick which factories may notify.
- Mac polish. A command palette, a shortcut for every action, a window per company, and tables with sortable columns where lists get long.
- iPad polish. Pointer and keyboard parity with the Mac, and Stage Manager window sizes.

## Work that runs through every phase

- Version tolerance. Each new `FactoryService` method has a default that throws `.unsupported`, and each screen has a state for it. The sandbox contract tests run against the pinned image and against `latest`.
- Testing. Every behavior change gets a Swift Testing test in the package. Add snapshot tests for the main screens at compact and regular width once phase 1 lands, since layout bugs are the ones logic tests miss.
- The demo factory grows with each phase. A new screen that is empty in the demo is not done.
- Design. Each phase starts with artboards for iPhone, iPad and Mac in the design file before the OpenSpec proposal.
- `docs/paperclip-api.md` lists every endpoint Fabrix calls. Update it in the same PR that adds the call.
- Telemetry stays scrubbed. New spans must not carry task titles, comment text or transcript content.

## What we leave to the web UI

Skills and Skill Studio, secrets, connections and connected apps, plugins, environments and workspaces, routine editing, company import and export, access and member management, instance settings, board chat, agent chat and voice sessions.

These are setup or are changing fast upstream. A native copy would lag behind and add little. Where Fabrix shows something that links to one of them, it opens the web UI at the right page.

## Open decisions

1. Push relay. Do we run one, publish one for self-hosters to run, or stay with background refresh? This decides how far phase 4 goes.
2. Minimum Paperclip version. Which release do we test against and name in the README as supported?
3. Editing documents. Phase 2 is read-only. Editing plans on iPad is attractive but needs conflict handling with `baseRevisionId`.
4. Agent chat. Left to the web for now. If Paperclip's chat settles, a chat with the CEO agent may be the best iPhone feature we don't have.

## Order at a glance

| Phase | Result                                          | Depends on             |
| ----- | ----------------------------------------------- | ---------------------- |
| 0     | What ships today is correct                     | nothing                |
| 1     | Inbox replaces approvals                        | nothing                |
| 2     | Task detail, comments, create, edit             | nothing                |
| 3     | Run transcripts, stop, retry, agent detail      | 2 for navigation       |
| 4     | Local notifications and actions                 | 1                      |
| 5     | Lighter loading, no 500-task cap, offline open  | nothing, best before 8 |
| 6     | Search, costs, cross-factory inbox              | 1, 5                   |
| 7     | Live event stream                               | upstream PR            |
| 8     | Widgets, menu bar, App Intents, platform polish | 4, 5                   |
