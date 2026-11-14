## Context

See proposal.md, Why. Fabrix today:

- `FactoryService` (`FabrixCore/FactoryService.swift`) has 8 methods. `projects(companyID:)` set the pattern for optional features: a default that throws `FactoryServiceError.unsupported`, a live implementation that maps `404` to it, and an app state that hides the feature.
- `PaperclipClient.perform` turns a non-2xx response into `PaperclipError(status:message:)` and keeps only the body's `error` string.
- Approval decisions go through `ApprovalDesk` (`FabrixFeatures/Logic`), which `AppModel` holds. A decision is staged, a timer sends it after `undoWindow` (8 s), `commitStagedDecisions()` sends everything when the app goes to the background, and a decision rejected because the user was signed out stays staged. `AppModel.decide(_:approve:confirmingWith:)` (`Lock/AppLock+Approvals.swift`) asks `AppLock.confirmDecision()` first.
- `AppModel.swift` is 1,091 lines. Roadmap Phase 5 asks for the inbox to become its own type behind the same observable model.
- Telemetry already templates IDs in URL paths and drops queries (`AttributeScrubber.template`). It records no request or response bodies.
- The design is 14 artboards plus notes (in the design hand-over, not yet published to the design file). The notes list 16 FabrixDesign components, the card-type table and the accessibility behavior. This document refers to them by name.

Paperclip facts below were read at `890dcbdd`. They come from `packages/shared/src/types/attention.ts`, `issue.ts`, `validators/*`, `server/src/routes/attention.ts`, `approvals.ts`, `issues.ts`, `access.ts`, `inbox-dismissals.ts`, `middleware/error-handler.ts` and `docs/api/attention.md`.

## Goals / Non-Goals

**Goals:**

- Every Phase 1 scope bullet, per-device bullet and the fallback from `docs/roadmap.md`. The specs map them one to one.
- `AppModel` grows by at most about 40 lines. Inbox state and actions live in `InboxStore`.
- Each card kind has demo data, a screen state on all three devices, and a test.
- Version tolerance: no `/attention`, `/attention` without routing, and the full routed feed.

**Non-Goals:**

- The Archived and Everyone views, bulk withdraw of stale cards, and restoring a hidden card `[D10]` `[D11]`.
- Answering `make_choice`, `suggested_tasks`, `join_request`, `tool_access`, `connect_service`, problem cards and `review_task` `[D1]` `[D2]`.
- Pagination beyond what a scroll needs. The first page is 100 cards, and the next page loads when the list reaches its end.
- Snapshot tests. The roadmap schedules them for after Phase 1 lands. They need a new dependency and get their own change.
- Changing how the existing Approvals screen behaves.

## Decisions

### 1. Where the types live

FabrixDesign gets no dependency on FabrixCore. Each component takes strings, numbers, dates, closures and enums declared in FabrixDesign. FabrixFeatures maps Core models onto them.

| Type                                                                                                                                                                                                                                                                                                                                                                                                                                                     | Target                                     | File                                                                |
| -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------ | ------------------------------------------------------------------- |
| `AttentionView`, `AttentionSource`, `AttentionCardType`, `AttentionAnswer`, `AttentionItem`, `AttentionAudience`, `AttentionFeed`, `AttentionReceipt`, `AttentionCloseMode`, `AttentionClosure`, `DecisionRecord`, `DecisionHistoryPage`, `ApprovalDetail`, `ApprovalField`, `ApprovalComment`, `ThreadRequest` (with `Confirmation`, `Question`, `QuestionOption`, `VerdictItem`), `QuestionAnswer`, `ItemVerdict`, `Verdict`, `Person`, `RequesterRef` | FabrixCore                                 | `Inbox/InboxModels.swift` (new; `Models.swift` is not edited)       |
| `FactoryServiceError.alreadyClosed(AttentionClosure)`, the 15 new protocol methods and their defaults                                                                                                                                                                                                                                                                                                                                                    | FabrixCore                                 | `FactoryService.swift`                                              |
| `AttentionFeedDTO`, `AttentionItemDTO`, `DecisionHistoryDTO`, `ApprovalCommentDTO`, `InteractionDTO`, `UserDirectoryDTO`, `ErrorBodyDTO.code/details`, the mapping                                                                                                                                                                                                                                                                                       | FabrixCore                                 | `Paperclip/AttentionDTOs.swift`, `Paperclip/AttentionMapping.swift` |
| `PaperclipError.alreadyClosed(AttentionClosure)`, `PaperclipError.code` for 409/422 bodies                                                                                                                                                                                                                                                                                                                                                               | FabrixCore                                 | `Paperclip/PaperclipError.swift`, `PaperclipClient.swift`           |
| `InboxRow`, `CountedPicker`, `CountBadge`, `OwnerLabel`, `ReceiptRow`, `KeyValueList`, `CommentRow`, `ChoiceRow`, `VerdictPicker`, `ReasonField`, `DecisionBar`, `UndoBar`, `ResolvedNotice`, `HistoryRow`, `PlaceholderRow`, `KeyHint`, the `KindTag` tone, and enums such as `InboxRowTone`, `HistoryOutcome`, `VerdictChoice`, `UndoPhase`, `ResolverKind`                                                                                            | FabrixDesign                               | `Inbox/*.swift` (new folder)                                        |
| `InboxStore` (observable state and actions), `InboxDesk` (staged actions, pure), `InboxCard` (Core to Design mapping), `SnoozePreset`, the screens, `InboxCommands`, `AppIconBadge`                                                                                                                                                                                                                                                                      | FabrixFeatures                             | `Inbox/*.swift` (new folder)                                        |
| Inbox menu wiring                                                                                                                                                                                                                                                                                                                                                                                                                                        | App shell (`App/macOS`) and FabrixFeatures | `.commands { InboxCommands() }`                                     |

`Package.swift` keeps FabrixDesign's dependency list as it is. A test in slice 1 fails if a FabrixDesign file imports FabrixCore (`DesignIndependenceTests.noCoreImport`, a source scan).

### 2. Endpoints, requests and responses

All paths are relative to `/api`. "Live" means `PaperclipFactoryService`.

| Use              | Request                                                                                                                                                                                                      | Response (fields Fabrix reads)                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                               | Errors                                                                                                                                                                                                                                                                                           |
| ---------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| Feed             | `GET companies/{c}/attention?view=mine\|unassigned\|company&limit=100[&cursor=…]`                                                                                                                            | `AttentionFeed`: `deskBadgeCount`, `viewCounts?` (`mine`, `unassigned`, `company`), `nextCursor`, `items[]`, `receipts?[]` (mine only). Item: `id`, `sourceKind`, `subject{kind,id,title,identifier,status,href,metadata{kind,issueId,isPlanTarget,requestKind}}`, `detail{kind,…excerpt,questionCount,itemCount,optionCount}`, `severity`, `createdAt`, `activityAt`, `relatedIssue{id,identifier,title,status,href}`, `audience?{kind,userId,reason,transferredByUserId}`, `stale?{reason}`, `closeModes?[]`, `changeFingerprint?`, `dismissalKey`, `obligationKey`, `obligationLeadId`, `project{id,name,color}`, `requester?{kind,id,name}`, `originAgentName`, `whyNow` | `404` "API route not found" means `.unsupported`. `403` with "Board user context required" means `.unsupported` (no person to route to). Other errors pass through.                                                                                                                              |
| History          | `GET companies/{c}/attention/history?limit=50[&scope=mine][&cursor=…]`                                                                                                                                       | `{ items[], nextCursor }`. Item: `id`, `sourceKind`, `sourceId`, `issueIdentifier`, `issueTitle`, `agentName`, `title`, `outcome`, `resultOutcome?`, `action?{outcome,detail}`, `reason?`, `resolvedAt`, `resolvedByUserId`, `resolvedByAgentId`, `handledForUserId?`, `href`                                                                                                                                                                                                                                                                                                                                                                                                | `scope` is sent only when the feed had `viewCounts` `[D19]`. Older servers answer `400` to it, because their query schema is `.strict()`. `404` means `.unsupported`.                                                                                                                            |
| Approval         | `GET approvals/{a}` and `GET approvals/{a}/comments`, in parallel                                                                                                                                            | `Approval`: `type`, `status`, `payload` (object), `decisionNote`, `decidedByUserId`, `decidedAt`, `requestedByAgentId`, `requestedByUserId`. Comment: `id`, `authorAgentId`, `authorUserId`, `body`, `createdAt`                                                                                                                                                                                                                                                                                                                                                                                                                                                             | `404` means the card is gone, so refresh.                                                                                                                                                                                                                                                        |
| Comment          | `POST approvals/{a}/comments` `{ "body": "…" }`                                                                                                                                                              | the new `ApprovalComment`                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    | `400` for an empty body.                                                                                                                                                                                                                                                                         |
| Approve / reject | `POST approvals/{a}/approve\|reject` `{}` (existing `decide`)                                                                                                                                                | ignored                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      | `422` "Only pending or revision requested approvals can be …": read `GET approvals/{a}` and throw `.alreadyClosed` `[D16]`. A repeat of the same verdict answers `200` and counts as success.                                                                                                    |
| Request revision | `POST approvals/{a}/request-revision` `{ "decisionNote": "…" }`                                                                                                                                              | ignored                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      | `422` "Only pending approvals can request revision": read the approval and throw `.alreadyClosed`.                                                                                                                                                                                               |
| Thread request   | `GET issues/{i}/interactions`, then find the item with `id`                                                                                                                                                  | `IssueThreadInteraction`: `id`, `kind` (`request_confirmation`, `request_checkbox_confirmation`, `ask_user_questions`, `request_item_verdicts`, …), `status`, `title`, `summary`, `payload` (see below), `resolvedByUserId`, `resolvedByAgentId`, `resolvedAt`                                                                                                                                                                                                                                                                                                                                                                                                               | Not in the list, or not `pending`: `.alreadyClosed` built from the row, or with nil fields when the row is missing.                                                                                                                                                                              |
| Accept           | `POST issues/{i}/interactions/{r}/accept` `{}`                                                                                                                                                               | ignored                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      | `409` with `code` `interaction_already_resolved`, `interaction_superseded`, `interaction_stale_target` or `interaction_issue_closed`: re-read the interaction and throw `.alreadyClosed` `[D16]`. Any other `409`, such as the workspace-sync gate, passes through as `PaperclipError.conflict`. |
| Reject           | `POST issues/{i}/interactions/{r}/reject` `{ "reason": "…"? }`                                                                                                                                               | ignored                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      | Same as accept. `422` "A decline reason is required" is shown in the reason field.                                                                                                                                                                                                               |
| Answer           | `POST issues/{i}/interactions/{r}/respond` `{ "answers": [{ "questionId", "optionIds": [], "otherText"? }] }`                                                                                                | ignored                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      | Same as accept. `422` for a missing required answer.                                                                                                                                                                                                                                             |
| Verdicts         | `POST issues/{i}/interactions/{r}/verdicts` `{ "verdicts": [{ "id", "verdict": "approve\|reject\|defer", "reason"? }] }`                                                                                     | ignored                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      | Same as accept.                                                                                                                                                                                                                                                                                  |
| Close            | `POST companies/{c}/attention/{sourceKind}/{sourceId}/close` with `{ "mode": "withdraw", "reason": "…" }`, `{ "mode": "archive", "fingerprint" }` or `{ "mode": "snooze", "until": ISO8601, "fingerprint" }` | `AttentionCloseResult` (ignored)                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             | `409` with `code: attention_already_closed`: `.alreadyClosed(details)`. `422` "Reject this hire request instead" on a hire withdraw (never offered, see 7). `404` on the route means `.unsupported`.                                                                                             |
| Claim            | `POST companies/{c}/attention/issue_thread_interaction/{r}/claim` (no body)                                                                                                                                  | `{ alreadyClaimed }`                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         | `409 attention_already_closed`: `.alreadyClosed`. A `409` "Someone else claimed this card first": `PaperclipError.conflict`, so refresh.                                                                                                                                                         |
| Transfer         | `POST companies/{c}/attention/issue_thread_interaction/{r}/transfer` `{ "userId", "reason"? }`                                                                                                               | `{ alreadyTransferred }`                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     | `422`: the server's reason is shown in the picker ("can't take this request").                                                                                                                                                                                                                   |
| Dismiss receipt  | `POST companies/{c}/inbox-dismissals` `{ "itemKey": receipt.dismissalKey, "kind": "dismiss" }`                                                                                                               | ignored                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      | `404` means `.unsupported`, so the receipt is hidden locally.                                                                                                                                                                                                                                    |
| People           | `GET companies/{c}/user-directory`                                                                                                                                                                           | `{ users: [{ principalId, membershipRole, user: { id, name, email, image } \| null }] }`                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     | `403` or `404` means `.unsupported`. Names fall back to "A teammate" and Transfer is hidden `[D7]`.                                                                                                                                                                                              |

The `409` body from Paperclip's error handler is:

```json
{
  "error": "Already answered",
  "code": "attention_already_closed",
  "details": {
    "code": "attention_already_closed",
    "sourceKind": "approval",
    "sourceId": "…",
    "status": "approved",
    "resolvedByUserId": "…",
    "resolvedByAgentId": null,
    "resolvedAt": "…"
  }
}
```

`ErrorBodyDTO` gains `code: String?` and `details: AlreadyClosedDTO?`, both decoded leniently. `PaperclipClient.perform` throws `PaperclipError.alreadyClosed(AttentionClosure)` when `code == "attention_already_closed"` and `details` decodes. Every other status keeps today's mapping. `PaperclipError.conflict` and `invalidRequest` keep their `String?` payload, and the body's `code` is exposed through a new `PaperclipError.code` property, so existing switches still compile.

Payload fields Fabrix maps (the rest is ignored):

- `request_confirmation`: `prompt`, `detailsMarkdown`, `acceptLabel`, `rejectLabel`, `rejectRequiresReason`, `rejectReasonLabel`, `allowDeclineReason`, `target.kind`. The card type comes from feed metadata (`isPlanTarget` gives `review_plan`, `requestKind == deliverable` gives `review_deliverable`). `toolAction`, `secretProposal` and `connectionAuthorization` make the card Open in Paperclip.
- `ask_user_questions`: `title`, `submitLabel`, `questions[]{id, prompt, helpText, selectionMode, required, allowOther, options[]{id, label, description, freeText}}`. When `questionSet` is present, its `recommended` flags are copied onto the options by ID. A `questionSet` question with `answerMode: text` makes the card Open in Paperclip `[D17]`.
- `request_item_verdicts`: `prompt`, `detailsMarkdown`, `items[]{id, label, description, previewMarkdown, href}`, `verdicts` (default all three), `requireReasonOn`, `reasonLabel`, `allowBulkApprove`.
- `request_checkbox_confirmation`, `suggest_tasks`, `connection_intent`: not mapped. The card is Open in Paperclip `[D1]`.

"Open in Paperclip" builds `factory.baseURL` + the card's `subject.href` (or `relatedIssue.href`). It opens only when the result has the same origin as the factory, using the same `SameOriginRedirects.Origin` check as sign-in. Otherwise the button is hidden.

### 3. New `FactoryService` methods

Every method has a default in the protocol extension that throws `FactoryServiceError.unsupported`. `DemoFactoryService` and `PaperclipFactoryService` implement all of them.

```swift
func attention(companyID: Company.ID, view: AttentionView, cursor: String?) async throws -> AttentionFeed
func attentionHistory(companyID: Company.ID, mineOnly: Bool, cursor: String?) async throws -> DecisionHistoryPage
func approvalDetail(approvalID: Approval.ID) async throws -> ApprovalDetail
func addApprovalComment(approvalID: Approval.ID, body: String) async throws -> ApprovalComment
func requestRevision(approvalID: Approval.ID, note: String) async throws
func threadRequest(issueID: WorkItem.ID, requestID: ThreadRequest.ID) async throws -> ThreadRequest
func acceptRequest(issueID: WorkItem.ID, requestID: ThreadRequest.ID) async throws
func rejectRequest(issueID: WorkItem.ID, requestID: ThreadRequest.ID, reason: String?) async throws
func answerQuestions(issueID: WorkItem.ID, requestID: ThreadRequest.ID, answers: [QuestionAnswer]) async throws
func submitVerdicts(issueID: WorkItem.ID, requestID: ThreadRequest.ID, verdicts: [ItemVerdict]) async throws
func closeAttention(companyID: Company.ID, source: AttentionSource, mode: AttentionCloseMode) async throws
func claimAttention(companyID: Company.ID, source: AttentionSource) async throws
func transferAttention(companyID: Company.ID, source: AttentionSource, to personID: Person.ID, reason: String?) async throws
func people(companyID: Company.ID) async throws -> [Person]
func dismissReceipt(companyID: Company.ID, receipt: AttentionReceipt) async throws
```

`AttentionCloseMode` is `.withdraw(reason: String)`, `.archive(fingerprint: String?)` or `.snooze(until: Date, fingerprint: String?)`. `decide(approvalID:approve:)` is unchanged. Its live implementation gains the `422` to `.alreadyClosed` mapping, which `ApprovalsView` also benefits from.

How each screen treats `.unsupported`:

| Method fails with `.unsupported`                                                       | Screen behavior                                                                                                                     |
| -------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------- |
| `attention`                                                                            | No Inbox section or tab. Approvals, its tab and its badge stay exactly as today. Remembered for the factory session, like projects. |
| `attentionHistory`                                                                     | The History button is hidden.                                                                                                       |
| `approvalDetail`                                                                       | The card shows the feed's summary and Approve and Reject. No payload or comments.                                                   |
| `addApprovalComment`                                                                   | The composer is hidden.                                                                                                             |
| `requestRevision`                                                                      | Request revision is hidden.                                                                                                         |
| `threadRequest`, `acceptRequest`, `rejectRequest`, `answerQuestions`, `submitVerdicts` | The card becomes Open in Paperclip.                                                                                                 |
| `closeAttention`, `claimAttention`, `transferAttention`                                | The action is hidden. The card's `closeModes` and routing flag already hide it on servers without routing `[D19]`.                  |
| `people`                                                                               | Transfer is hidden, and names show as "A teammate".                                                                                 |
| `dismissReceipt`                                                                       | The receipt hides locally until the next launch.                                                                                    |

A method that is unsupported at run time, for example a `404` on a close route, is remembered as unsupported for the factory session. The action disappears, and the user sees "This factory doesn't support that yet" once.

### 4. Models (sketch)

```swift
enum AttentionView { case mine, unassigned, company }
struct AttentionSource: Hashable { enum Kind: Hashable { case approval, threadRequest, decision, joinRequest, other(String) }; var kind: Kind; var id: String }
enum AttentionCardType { /* the 16 server types */ case unknown(String) }
enum AttentionAnswer { case approval(Approval.ID), confirmation, questions, verdicts, openInPaperclip }   // [D1] [D2] [D17]
struct AttentionItem: Identifiable, Hashable {
  var id: String; var source: AttentionSource; var cardType: AttentionCardType; var answer: AttentionAnswer
  var title: String; var summary: String?; var requester: RequesterRef?; var task: TaskRef?   // id, identifier, title, status
  var projectName: String?; var isCritical: Bool; var isProblem: Bool; var staleReason: StaleReason?
  var audience: AttentionAudience?; var closeModes: Set<CloseModeKind>; var canClaim: Bool; var canTransfer: Bool
  var fingerprint: String?; var createdAt: Date; var activityAt: Date; var webPath: String?
  var obligationLeadID: String?
}
struct AttentionFeed { var items: [AttentionItem]; var receipts: [AttentionReceipt]; var viewCounts: [AttentionView: Int]?; var badgeCount: Int; var nextCursor: String?
  var supportsRouting: Bool { viewCounts != nil } }
struct AttentionClosure: Hashable { var status: String?; var resolvedByUserID: String?; var resolvedByAgentID: String?; var resolvedAt: Date? }
struct Person: Identifiable, Hashable { var id: String; var name: String?; var email: String? }
```

`canClaim` is true only for an Unassigned thread request on a routed server. `canTransfer` is true only for a thread request on a routed server `[D6]`. An item whose `obligationLeadID` names another item in the page is shown only as evidence inside its lead, which follows the server's rule 11. Unknown enum strings decode to `.unknown` or `.other` and are treated as Open in Paperclip, never as a decoding failure. Rows decode leniently, the way projects do.

### 5. Where state lives

`InboxStore` is a `@MainActor @Observable final class` in `FabrixFeatures/Inbox/`. It holds:

- support, the selected view, the feed, the loading and error state, the selection, card details by ID, people by ID and history pages;
- an `InboxDesk` for staged actions, and the per-card closures (`AttentionClosure`) that drive `ResolvedNotice`.

It gets the current service, company and generation from `AppModel` through a small `InboxContext` value, so it never holds a stale service.

`AppModel` changes are limited to these:

- `let inbox: InboxStore`;
- `refresh()` also calls `inbox.refresh(context)`, under the same generation check, so a stale feed can't land after a factory switch;
- `use(_:)`, `renew(_:)` and `select(_:)` call `inbox.reset(…)`, which also drops staged actions, the same rule as `ApprovalDesk`;
- `commitStagedDecisions()` also awaits `inbox.commitStaged()`;
- `waitingCount` returns `inbox.badgeCount` when the inbox is supported, and the approvals count otherwise.

Overview's approval card calls `inbox.decide` when the inbox is supported, so the same approval is never staged in two desks.

`InboxDesk` is the pure counterpart of `ApprovalDesk`. It maps a card ID to a `StagedAction`:

- `.approve`, `.reject`, `.requestRevision(note)`;
- `.accept`, `.decline(reason)`;
- `.answer([QuestionAnswer])`, `.verdicts([ItemVerdict])`;
- `.snooze(until)`, `.archive`.

It has `stage`, `undo`, `beginCommit`, `finish` and `restage` (for a sign-out bounce), with the same semantics and tests as `ApprovalDesk`. `ApprovalDesk` stays as it is for the fallback screen.

### 6. Demo factory

`DemoFactoryService` gains:

- **People:** you (`me`), Priya and Sam.
- **For you:** "Hire a Designer agent" (approval with payload and two comments); "Review the Q4 plan" (`review_plan` on ATL-148); "Which push provider?" (`answer_questions` on ATL-160, single choice with Recommended and Other, plus multiple choice); "Review release notes" (`review_items` on ATL-120, 3 items); a confirmation with `rejectRequiresReason`; a stale card (`aged`); a transferred card ("Transferred by Priya"); and a "Critical" `budget_stop` problem card (Open in Paperclip).
- **Unassigned:** a claimable confirmation.
- **Company:** `failed_run` and `join_request` (Open in Paperclip).
- **One receipt:** "Priya approved Raise Founding Engineer cap for you".
- **History:** approved, rejected, answered, decided, withdrawn, transferred and expired.

Every action changes the demo's state in memory. A demo-only switch `simulateAlreadyClosed` makes the next decision on one marked card throw `.alreadyClosed` (by Priya), so previews and UI checks reach the 409 path. "Open in Paperclip" is disabled in the demo, with the reason "Not available in the demo".

### 7. Undo window and confirmation per action

| Action                                            | Face ID (when "Confirm approvals" is on) | Undo                                                                      | Notes                                                                                                        |
| ------------------------------------------------- | ---------------------------------------- | ------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------ |
| Approve, reject (approval)                        | yes                                      | 8 s staged                                                                | as today                                                                                                     |
| Request revision                                  | yes                                      | 8 s staged `[D3]`                                                         | note required                                                                                                |
| Accept, decline (confirmation, plan, deliverable) | yes                                      | 8 s staged                                                                | the reason is required when `rejectRequiresReason` is set                                                    |
| Submit answers                                    | yes                                      | 8 s staged                                                                | required questions must be answered first                                                                    |
| Submit verdicts                                   | yes                                      | 8 s staged                                                                | a reason is required on verdicts in `requireReasonOn`; "Approve all" only with `allowBulkApprove`            |
| Withdraw                                          | yes `[D4]`                               | none. A reason, then a destructive confirmation                           | Hidden on hire approvals, because the server refuses them. Shown only when `closeModes` contains `withdraw`. |
| Snooze, archive                                   | no                                       | 8 s staged `[D5]`                                                         | affects only the user                                                                                        |
| Claim                                             | no                                       | none                                                                      | routing only; changes nothing anyone can't change back                                                       |
| Transfer                                          | no                                       | none. Picking a person and confirming "Transfer to X" is the confirmation | sent at once                                                                                                 |
| Post comment                                      | no                                       | none `[D20]`                                                              | sending and failed states, with retry by hand                                                                |
| Dismiss receipt                                   | no                                       | none                                                                      | affects only the user                                                                                        |

Staged actions go out when the window ends, when the user taps "Send now" in the undo bar, or when the app leaves the foreground (`commitStagedDecisions`). A staged action rejected because the key was refused stays staged until the user signs in again, as approvals do today. A staged action whose card leaves the company with a company switch is dropped.

### 8. "Already decided"

When an action throws `FactoryServiceError.alreadyClosed(closure)`:

1. The staged action is finished, not restaged, and nothing is retried.
2. The card shows `ResolvedNotice`: "Priya approved this at 14:29. Your rejection wasn't recorded." The decider is a person's name from `people`, an agent's name from the snapshot, or "Someone" when neither is known.
3. The store refreshes the feed. The notice stays on the selected card until the user moves on. On iPhone it stays until they go back.

A generic `PaperclipError.conflict` (for example "Someone else claimed this card first") shows the server's sentence and refreshes.

### 9. Badges

- **Tab (compact) and sidebar row (regular):** `inbox.badgeCount`, which is `deskBadgeCount` from the last feed. It is hidden at 0 and shows "99+" above 99 (`CountBadge`).
- **App icon:** `AppIconBadge` sets it after every feed load and clears it on sign-out, on factory removal and when the inbox is unsupported. On iOS and iPadOS it uses `UNUserNotificationCenter.setBadgeCount`, only after the user turns on "Show count on app icon" in Settings, which asks for `.badge` authorization `[D18]`. On macOS it uses `NSApp.dockTile.badgeLabel` and is always on. The count is the open company's `[D8]`.

### 10. Layout per device

- **iPhone:** Inbox is the first tab, with a `CountedPicker` for the views. Rows open the card in a pushed view with a pinned `DecisionBar`. Swipe trailing to snooze (with a preset menu) and leading to archive. A long press opens the same actions as a context menu.
- **iPad:** in the sidebar, then a `NavigationSplitView` content column with the list and a detail column with the card above its task context. A toolbar holds History, Refresh and the view switch.
- **Mac:** the same split, plus the Inbox menu. Snooze presets are "In 1 hour", "Tomorrow morning (9:00)", "Next week (Monday 9:00)" and "Pick a time…", all in local time.
- **Keyboard (Mac, and iPad with a keyboard):** the Inbox menu (`InboxCommands`) uses `FocusedValue` from the inbox view:

  | Command          | Keys                  |
  | ---------------- | --------------------- |
  | Next             | ↓ or J                |
  | Previous         | ↑ or K                |
  | Open task        | ⌘O `[D21]`            |
  | Switch view      | ⌘⌥1–3                 |
  | Approve / accept | ⌘↩                    |
  | Reject           | ⌘⌫ `[D14]`            |
  | Request revision | ⌥⌘↩                   |
  | Undo             | ⌘Z, inside the window |
  | Snooze           | ⌃⌘S or S              |
  | Archive          | ⌃⌘A or E              |
  | Claim            | ⌃⌘C                   |
  | Transfer         | ⌃⌘T                   |
  | History          | ⌘Y                    |
  | Refresh          | ⌘R                    |
  | Copy link        | ⇧⌘C                   |

  Single keys work only while the list has focus. Each slice adds the commands for its own actions, so every layer of the stack has shortcuts for what it ships.

### 11. Accessibility

- **VoiceOver:** a row is one element read as "kind, title, from requester, age, for owner". Swipe and menu actions are custom actions on it. `UndoBar` is a live region: it announces the verdict and "sending in 8 seconds", then "sent". `ResolvedNotice` is announced when it appears.
- **Dynamic Type:** at accessibility sizes the view switch becomes a menu, rows stack, payload rows put the label above the value, and the decision buttons move from the pinned bar to the end of the content.
- **Reduce Motion:** decided rows fade instead of sliding (`fabrixTransition`), skeletons don't shimmer, and the countdown is text. Nothing needs a gesture, because every swipe action is also in the context menu.
- **Color:** never the only signal. Verdicts say Approve, Reject or Defer, history rows start with a verb, and problems carry a "Problem" tag.

### 12. Telemetry

Fabrix adds no new spans and no new attributes. URL session spans for the new routes are already templated (`/api/companies/{id}/attention/issue_thread_interaction/{id}/close`) and lose their queries. Request and response bodies, where titles, comments, answers, reasons and payloads travel, are never recorded. Slice 2 adds `AttributeScrubberTests.attentionRoutesAreTemplated`, and slice 3 adds `ScrubbingExporterTests.inboxErrorLogsCarryNoText`. That test fails if any inbox error log or span status carries comment text, a decision note or a payload value, and it covers the failure paths `InboxStore` logs.

### 13. Docs

Each slice adds its endpoints to a new "Inbox" section of `docs/paperclip-api.md`, in the same PR as the call. The section covers the request, the fields read, the error mapping, the fallback rules and the version notes `[D16]` `[D19]`.

## Risks / Trade-offs

- [Paperclip's attention API is four months old, and routing is three days old at `890dcbdd`] → All decoding is lenient: unknown kinds become Open in Paperclip, and missing routing fields switch to the unrouted mode `[D19]`. Slice 10 runs the sandbox contract tests against the pinned image and `latest`.
- [An interaction `409` carries no resolver] → One extra `GET issues/{i}/interactions` after the conflict. When that read fails, the notice says "Someone already answered this".
- [The user directory exposes members' emails to Fabrix] → Fabrix shows emails only when a name is missing, never writes them to telemetry or logs, and doesn't cache them on disk.
- [Two desks (approvals fallback and inbox) can disagree on one approval] → Only one is active per factory: the inbox when it is supported, the Approvals screen otherwise. Overview routes through whichever is active.
- [The app icon badge on iOS needs a permission prompt] → It is opt-in in Settings `[D18]`. Without it, the tab badge still shows the count.
- [The first page is capped at 100 cards] → The next page loads at the end of the list. The view count comes from `viewCounts`, never from counting the rows.
- [A 20 s poll on the feed adds one request per tick] → It replaces nothing yet. Phase 5 drops the snapshot's two approval requests once the inbox is the only approvals surface.

## Migration Plan

The change is additive and ships as the 10-slice stack in tasks.md. Every layer can ship:

- After slice 2, Inbox appears beside Approvals, read-only.
- Slice 3 makes approvals answerable in the inbox and removes the Approvals section on servers that have the inbox.
- Slices 4–9 add the remaining card kinds and actions.

To roll back, revert the stack. Servers without `/attention` never see a change.

## Open Questions

None that change the specs or tasks. The items Paperclip's source didn't settle are listed in the tasks under 10.2, to check in the sandbox:

- how `local_trusted` routes the inbox for `local-board`;
- `answerMode: text` answers;
- whether interaction accept on a plan target needs a body.
