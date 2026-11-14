## Decisions for the owner

Each item lists the options, the recommendation (marked **Rec**) and why. The specs, design and tasks follow the recommendations. Every place that changes with a different answer carries a marker `[D<n>]`, so a search for the number finds it.

1. **Card types Fabrix can't answer yet.** Paperclip has 16 card types. Options: (a) list all of them, answer 6 in place and give the other 10 an "Open in Paperclip" button; (b) hide the 10. **Rec: (a).** Hiding them would leave the badge counting cards the user can't see.
   - Answered in place: `board_approval`, `confirm`, `review_plan`, `review_deliverable`, `answer_questions`, `review_items`.
   - Open in Paperclip: `suggested_tasks`, `make_choice`, `join_request`, `tool_access`, `connect_service`, `review_task`, `failed_run`, `budget_stop`, `blocked_task`, `recovery`. Also a `confirm` card whose detail is a checkbox confirmation, and an `answer_questions` card with a text-only question (see 17).
2. **Decisions (`make_choice`).** Options: (a) Open in Paperclip in Phase 1; (b) answer in place, which needs Paperclip's decisions endpoints and one more slice. **Rec: (a).** The roadmap names approvals and interactions only. Choices get their own change once Phase 1 has shipped.
3. **Request revision.** Options: (a) treat it as a decision, with Face ID and the 8-second undo window; (b) send it at once. **Rec: (a).** It wakes the agent and can't be taken back.
4. **Withdraw.** Options: (a) a required reason, then a destructive confirmation, then Face ID when the setting is on, sent at once with no undo; (b) the same flow without Face ID; (c) the 8-second undo window instead of the confirmation. **Rec: (a).** Withdrawing closes the request for everyone, and the lock setting covers every decision that reaches someone else.
5. **Archive and snooze.** Options: (a) the same 8-second staged window as decisions, so nothing is sent before it ends; (b) send at once and undo through Paperclip's restore endpoint (`DELETE …/inbox-dismissals/{itemKey}`). **Rec: (a).** One mechanism, one fewer endpoint, and no dismissal key in a URL path.
6. **Claim and transfer on approvals.** The server allows them only on task-thread requests. Options: (a) hide the buttons where the card doesn't allow them; (b) show them disabled with a reason. **Rec: (a).** It follows principle 3: hidden, not broken.
7. **Who can receive a transfer.** Paperclip has `GET /companies/{id}/user-directory`. It needs only company access and lists active members with name, email and avatar. Options: (a) ship transfer with this list; (b) leave transfer out of Phase 1 and record it as not done. **Rec: (a).** The server still checks the recipient and answers `422` for someone who can't take the card. Fabrix shows that answer. The same list gives names for owner labels, receipts and "already decided".
8. **App icon badge with several factories.** Fabrix loads only the open factory. Summing needs a background request per saved factory, which is Phase 4 work. Options: (a) the badge shows the open company's `deskBadgeCount`; (b) sum over all signed-in factories now. **Rec: (a).** The sum arrives with Phase 4 background refresh and the Phase 6 cross-factory inbox. This differs from the drawn design.
9. **Receipts.** Options: (a) show "Answered by Priya for you" at the top of For you, with a dismiss button that calls Paperclip's dismissal endpoint; (b) leave receipts out. **Rec: (a).** The server already sends them with `view=mine`, and they explain why a card disappeared.
10. **Archived view and Everyone.** Options: (a) no Archived view and no Everyone view in Phase 1; (b) a read-only "Snoozed · n" row; (c) the Archived view with Restore. **Rec: (a).** A hidden card returns when it changes or its snooze ends, and the undo window catches mis-taps. Restore stays in the web UI. The design draws (b).
11. **Stale cards.** Options: (a) their own group with the reason, and no "Withdraw all stale"; (b) mixed in with the rest. **Rec: (a).** This matches the design. A bulk withdraw is too easy to misfire on a phone.
12. **Severity.** Options: (a) keep the server's order and show a "Critical" tag (text and icon) on critical cards only; (b) use severity for sorting only. **Rec: (a).** The server already ranks cards. A critical card needs a mark that isn't color alone.
13. **Offline.** Options: (a) disable the decide buttons and say why, with nothing queued; (b) queue decisions and send them on reconnect. **Rec: (a).** A queued decision could reach a card that someone else has already answered. Decisions that are already staged keep today's behavior.
14. **Mac keys.** The design draws ⌘⌫ for Reject, ⌃⌘S for Snooze, ⌘Z for Undo and ⌘R for Refresh. ⌘⌫ reads like Delete and, as a menu key equivalent, fires while a text field has focus. ⌃⌘S is macOS's Show/Hide Sidebar, and ⌘R is already Factory ▸ Refresh. Options: (a) Reject ⌥⌘⌫ and Snooze ⌥⌘S; Undo through the Edit menu's `UndoManager` and Refresh from the existing Factory menu; decide commands disabled while a text field has focus; single keys (J, K, S, E) only while the list has focus; (b) the drawn keys. **Rec: (a).** It keeps the system and app shortcuts working and stops a ⌘↩ or ⌥⌘⌫ meant for a reason field from deciding the card.
15. **Sidebar order.** Options: (a) Inbox first in the iPad and Mac sidebar; (b) Inbox where Approvals sits today. **Rec: (a).** The inbox is first on iPhone too.
16. **"Already decided" beyond the 409.** Paperclip sends the `409 attention_already_closed` body only from close, claim, transfer and approval withdraw. Approve and reject answer `422 "Only pending or revision requested approvals can be …"`, and request revision answers `422 "Only pending approvals can request revision"`. Interactions answer `409` with `interaction_already_resolved`, `interaction_superseded`, `interaction_stale_target` or `interaction_issue_closed`, and no resolver. Options: (a) treat all of these as "already closed": read the source once to learn who decided, refresh, and never retry; (b) handle only the 409 the roadmap names and show the others as generic errors. **Rec: (a).** The roadmap bullet can't be delivered as written for approvals and interactions. (a) delivers what it is for.
17. **Text answers.** Questions in the newer `paperclip.question_set.v1` format can be text-only (`answerMode: text`), and the source doesn't show how they are sent. Options: (a) cards with a text-only question open in Paperclip; (b) send the text as `otherText`. **Rec: (a)** until the sandbox confirms (b).
18. **App icon badge permission on iOS.** Setting the badge on iOS and iPadOS needs notification authorization for badges. On Mac it doesn't. Options: (a) a "Show count on app icon" switch in Settings, off by default, that asks for badge permission when turned on; (b) ask on first launch; (c) wait for Phase 4. **Rec: (a).** It doesn't spend the one-time permission prompt before Phase 4 needs it for alerts.
19. **Servers with `/attention` but without routing.** Paperclip added `view`, `viewCounts`, `audience`, `closeModes`, claim, transfer, close and history `scope` on 2026-11-11 (`8818402e7`). The feed itself dates from 2026-07-10. Options: (a) on such a server, show one list without the view switch, answer cards in place, hide snooze, archive, withdraw, claim and transfer, and read history without `scope`; (b) treat such a server like one without `/attention` and show the Approvals screen. **Rec: (a).** Every action is already gated per card, so this costs one mapping test and one screen state.
20. **Approval comments.** Options: (a) read and post comments, posted at once with sending and failed states, like a chat message; (b) read only. **Rec: (a).** A comment is how a board user answers without deciding. It decides nothing, so it needs no undo window.
21. **"Open task" before Phase 2.** Task detail arrives in Phase 2. Options: (a) the task context shows what the feed and the snapshot know (identifier, title, status, assignee, project), and "Open task" opens the task in Paperclip; (b) "Open task" jumps to the Tasks board. **Rec: (a).** The board has no task detail to land on. Phase 2 switches "Open task" to its own detail screen.
22. **Staged actions on a company or factory switch.** Today a staged approval is still sent after its window when the user switches company, and a factory switch sends staged decisions first. Options: (a) send what is staged right away, then switch; (b) drop it. **Rec: (a).** It matches today's behavior, and a decision the user made and didn't undo should reach the factory. Disconnect still drops what is staged, as it does today.
23. **Overview's "Waiting on you" count.** Today it counts pending approvals, which would disagree with the Inbox badge. Options: (a) on inbox factories show `deskBadgeCount`; (b) keep counting pending approvals, leaving out those staged in the inbox. **Rec: (a).** One number for "what waits for me" everywhere. The Overview list itself stays approvals.
24. **When Approvals gives way to the Inbox.** Options: (a) remember per factory whether its feed loaded. At launch the shell lays out from that answer. A factory never seen with a feed keeps Approvals until the first feed load succeeds. Only a loaded feed or a `404` "API route not found" changes the answer, so a network error never hides Approvals. (b) Show an Inbox loading state until the first answer. **Rec: (a).** The tab bar doesn't reshuffle at launch, and the user is never left without a way to approve.

## Why

Paperclip's web UI now routes everything that waits for a person through one attention inbox: approvals, task-thread requests (confirmations, questions, item reviews) and problems. Fabrix shows four approval types and nothing else, so a Fabrix user misses most of what their agents are waiting on. Roadmap Phase 1 replaces the Approvals section with that inbox on iPhone, iPad and Mac.

## What Changes

- An Inbox section reads `GET /companies/{id}/attention`, with the views For you (`mine`), Unassigned and Company. It has a Stale group, receipts at the top of For you, and a "Critical" tag `[D12]`. Every card shows its kind, requester, task, age, title, summary and owner.
- Cards are answered in place: approvals (approve, reject, request revision with a note `[D3]`, the full payload, comments that can be read and posted `[D20]`), confirmations (accept, reject with a reason), questions (single, multiple and other) and item verdicts (approve, reject or defer each item). The other card types open in Paperclip `[D1]` `[D2]` `[D17]`.
- Snooze, archive `[D5]`, withdraw `[D4]`, claim and transfer `[D6]` `[D7]`, as the server allows them per card.
- Decision history from `GET /companies/{id}/attention/history`.
- Every decision keeps the Face ID confirmation and the 8-second undo window. Withdraw asks for confirmation. A card that someone else closed first shows who decided, then refreshes, and is never retried `[D16]`.
- The tab, the sidebar row and the app icon show `deskBadgeCount` `[D8]` `[D18]`.
- iPhone: the Inbox is the first tab and replaces the Approvals tab, with swipe to snooze or archive. iPad and Mac: Inbox first in the sidebar `[D15]`, with a split of the list and the card with its task context `[D21]`. Mac and iPad with a keyboard: an Inbox menu with shortcuts for next, previous, approve, reject and snooze, none of which reuse a key the app or macOS already binds `[D14]`.
- Fallback: a server without `/attention` keeps today's Approvals screen. A server with the feed but without routing gets one list without the view switch `[D19]`.
- No Phase 1 screen is empty in the demo factory. It has an example of every card kind, a receipt, history and people.
- `docs/paperclip-api.md` gains an Inbox section, updated in the same PR as each call.

Not in this change: decisions between options (`make_choice`), suggested tasks, join requests, tool access, the Archived and Everyone views, a cross-factory inbox, notifications (Phase 4) and task detail (Phase 2).

Platforms: iOS, iPadOS and macOS ship together. Targets: FabrixCore, FabrixDesign, FabrixFeatures and the shared app shell (`App/Shared/FabrixApp.swift`, menu commands for Mac and iPad keyboards). FabrixTelemetry gets one fix: `paperclip.api.route` also comes from `url.full`. The `FactoryService` change is additive. It adds 15 methods, each with a default that throws `FactoryServiceError.unsupported`, and one new error case, `FactoryServiceError.alreadyClosed`. No existing method changes.

## Capabilities

### New Capabilities

- `inbox`: the attention inbox. It covers views, cards, answering each card kind in place, closing, routing, history, the 409 path, badges, the fallback, keyboard shortcuts and accessibility.

### Modified Capabilities

- `factory-service`: the attention feed and history, approval detail, comments and revision, task-thread requests, close, claim and transfer, the company people list, the already-closed error, and demo inbox data.
- `navigation`: Inbox replaces Approvals in the sidebar and tab bar when the server supports it, with its badge.
- `approvals`: the Approvals screen is now the fallback for servers without `/attention`.
- `company-overview`: Approve and Open on the overview's waiting approvals use the inbox when the factory has it.
- `app-lock`: "Confirm approvals" covers every inbox decision and withdraw.
- `design-system`: inbox components that take plain values only.
- `telemetry`: inbox requests carry no titles, comment text, answers or payloads.

## Impact

- FabrixCore:
  - New inbox model types in `Inbox/InboxModels.swift`. `Models.swift` is not edited.
  - New `FactoryService` methods and the `alreadyClosed` error.
  - Attention, approval and interaction DTOs and their mapping in `Paperclip/`.
  - `PaperclipError` gains `.alreadyClosed` and `.interactionClosed` for the coded `409` bodies. `FactoryServiceError` conforms to `LocalizedError`, so the fallback Approvals message stays the same.
  - Demo inbox data in `DemoFactoryService+Inbox.swift`.
  - Sandbox contract tests.
- FabrixDesign: the 16 components listed in `design.md`, with previews and catalog strings.
- FabrixFeatures:
  - A new `Inbox/` folder holding `InboxStore` (state and actions), `InboxDesk` (the staged-action logic), the screens and the commands.
  - `AppModel` gains only an `inbox` property, `inboxBadgeCount`, and hooks for refresh, commit and reset. A company switch commits staged actions before the reset `[D22]`, and disconnect resets.
  - Shell changes for the Inbox section, tab, sidebar and badges.
- App shells: `.commands { InboxCommands() }` in `App/Shared/FabrixApp.swift`, beside `FactoryCommands`.
- Docs: `docs/paperclip-api.md`.
- Test doubles that conform to `FactoryService` keep compiling, because every new method has a default.
- Seed script: `scripts/paperclip-sandbox-seed.sh` gains approvals, interactions and a second board user.
