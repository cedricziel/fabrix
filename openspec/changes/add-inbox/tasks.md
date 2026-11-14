Slices ship as one gh stack, one PR per numbered group, bottom to top. Each layer builds, passes its tests and can ship on its own.

| Slice                                   | Stack position | Shared files edited                                                                                                                                                                                                                                                                                                                                                                                                         | Changes shape of FactoryService / Models / AppModel | Touches undo window / Face ID / Auth / Connections / Keychain / telemetry scrubbing | Needs `validate` sandbox        | Model  |
| --------------------------------------- | -------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | --------------------------------------------------- | ----------------------------------------------------------------------------------- | ------------------------------- | ------ |
| 1. Telemetry route from `url.full`      | 1 (bottom)     | `AttributeScrubber.swift`                                                                                                                                                                                                                                                                                                                                                                                                   | no / no / no                                        | telemetry scrubbing                                                                 | no                              | sonnet |
| 2. Inbox components                     | 2              | FabrixDesign `Localizable.xcstrings`, `Badges.swift`                                                                                                                                                                                                                                                                                                                                                                        | no / no / no                                        | none                                                                                | no                              | sonnet |
| 3. Feed in Core                         | 3              | `FactoryService.swift`, `DemoFactoryService.swift` (one stored property), `InboxModels.swift`, `AttentionDTOs.swift`, `AttentionMapping.swift`, `PaperclipFactoryService.swift`, `DemoFactoryService+Inbox.swift`, `docs/paperclip-api.md`                                                                                                                                                                                  | yes / yes / no                                      | none                                                                                | yes                             | opus   |
| 4. Feed screens                         | 4              | `AppModel.swift`, `InboxStore.swift`, inbox views, FabrixFeatures `Localizable.xcstrings`, `AppSection.swift`, `CompactShell.swift`, `SplitShell.swift`                                                                                                                                                                                                                                                                     | no / no / yes                                       | none                                                                                | no                              | opus   |
| 5. Badge and Inbox menu                 | 5              | `InboxStore.swift`, `InboxCommands.swift`, `App/Shared/FabrixApp.swift`, `Lock/SettingsView.swift`, FabrixFeatures `Localizable.xcstrings`                                                                                                                                                                                                                                                                                  | no / no / no                                        | none                                                                                | no                              | sonnet |
| 6. Approvals in the inbox               | 6              | `FactoryService.swift`, `InboxModels.swift`, `PaperclipClient.swift`, `PaperclipError.swift`, `PaperclipDTOs.swift` (`ErrorBodyDTO`, shared with `Auth/AuthProvider.swift`; new fields optional, no `Auth/` file edited), `PaperclipFactoryService.swift`, `AttentionMapping.swift`, `DemoFactoryService+Inbox.swift`, `AppModel.swift`, `InboxStore.swift`, `InboxDesk.swift`, `InboxCommands.swift`, inbox views, `OverviewView.swift`, `Logic/OverviewMetrics.swift`, `AppSection.swift`, `CompactShell.swift`, `SplitShell.swift`, `AppLock+Approvals.swift`, both string catalogs | yes / yes / yes                                     | undo window, Face ID                                                                | yes                             | opus   |
| 7. Approval comments                    | 7              | `FactoryService.swift`, `InboxModels.swift`, `PaperclipFactoryService.swift`, `AttentionMapping.swift`, `DemoFactoryService+Inbox.swift`, `InboxStore.swift`, inbox views, both string catalogs                                                                                                                                                                                                                             | yes / yes / no                                      | none                                                                                | yes                             | opus   |
| 8. Confirmations                        | 8              | `FactoryService.swift`, `InboxModels.swift`, `PaperclipFactoryService.swift`, `AttentionDTOs.swift`, `AttentionMapping.swift`, `DemoFactoryService+Inbox.swift`, `InboxStore.swift`, `InboxDesk.swift`, `InboxCommands.swift`, inbox views, both string catalogs                                                                                                                                                            | yes / yes / no                                      | undo window, Face ID                                                                | yes                             | opus   |
| 9. Questions                            | 9              | same as 8                                                                                                                                                                                                                                                                                                                                                                                                                   | yes / yes / no                                      | undo window, Face ID                                                                | yes                             | opus   |
| 10. Item verdicts                       | 10             | same as 8                                                                                                                                                                                                                                                                                                                                                                                                                   | yes / yes / no                                      | undo window, Face ID                                                                | yes                             | opus   |
| 11. Snooze, archive, withdraw, receipts | 11             | same as 8                                                                                                                                                                                                                                                                                                                                                                                                                   | yes / yes / no                                      | undo window (snooze, archive), Face ID (withdraw)                                   | yes                             | opus   |
| 12. Claim and transfer                  | 12             | same as 8                                                                                                                                                                                                                                                                                                                                                                                                                   | yes / yes / no                                      | none                                                                                | yes                             | opus   |
| 13. Decision history                    | 13             | same as 8                                                                                                                                                                                                                                                                                                                                                                                                                   | yes / yes / no                                      | none                                                                                | yes                             | opus   |
| 14. Verify and archive                  | 14 (top)       | `openspec/specs/*`, `docs/paperclip-api.md`                                                                                                                                                                                                                                                                                                                                                                                 | no / no / no                                        | none                                                                                | yes (pinned image and `latest`) | sonnet |

How the slices are built:

- **Order.** Slices are implemented strictly in sequence, one at a time, because slices 6–13 all edit the inbox store, desk, models, mapping, commands, views and both string catalogs. The exceptions are slices 1, 2 and 3: they touch disjoint targets (FabrixTelemetry, FabrixDesign, FabrixCore), so they can be built in parallel. Slice 4 starts once 2 and 3 are done.
- **Demo data** lives in `DemoFactoryService+Inbox.swift`. `DemoFactoryService.swift` gets only one stored property, in slice 3. `Models.swift` is never edited: new types go in `FabrixCore/Inbox/InboxModels.swift`. No slice edits a file under `Auth/` or `Connections/`, or the Keychain. The one shared type is `ErrorBodyDTO` in `PaperclipDTOs.swift`, which `Auth/AuthProvider.swift` also decodes. Slice 6 adds only optional fields to it, so Auth's decoding is unchanged.
- **`.xcstrings` conflicts** after a rebase are resolved by re-running `scripts/sync-string-catalogs.sh` on the merged sources, never by hand.
- **Before ticking a task**, run `xcrun swift test --package-path Packages/FabrixKit`, `scripts/sync-string-catalogs.sh`, `scripts/check-feature-strings.sh`, `xcodegen generate` and both `xcodebuild` builds.
- **Docs.** Each slice that adds a call updates `docs/paperclip-api.md` in the same PR.

## 1. Telemetry route from `url.full` (stack 1, FabrixTelemetry)

- [ ] 1.1 Derive `paperclip.api.route` from the scrubbed `url.full` when a span has no `url.path`, keeping the factory-host and `/api/` checks. Test: `AttributeScrubberTests.attentionRouteFromFullURL`. A span with only `url.full` for the close route gets `/api/companies/{id}/attention/issue_thread_interaction/{id}/close`; this fails today. Touches `FabrixTelemetry/AttributeScrubber.swift`, `Tests/FabrixTelemetryTests/AttributeScrubberTests.swift`.
- [ ] 1.2 Add `ScrubbingExporterTests.inboxRouteErrorHasNoQueryOrID`: a failed span on `…/attention?view=mine&cursor=…` exports with a templated route and no query. It is a guard that passes once 1.1 lands. Touches `Tests/FabrixTelemetryTests/ScrubbingExporterTests.swift`.

## 2. Inbox components (stack 2, FabrixDesign)

- [ ] 2.1 Add `DesignIndependenceTests.noCoreImport`, a source scan that fails if any FabrixDesign file imports FabrixCore. It passes today and guards this slice. Touches `Tests/FabrixDesignTests/DesignIndependenceTests.swift`.
- [ ] 2.2 Add `CountBadge` and `KeyHint`, with previews. Tests: `InboxComponentTests.countBadgeText` (0 → hidden, 7 → "7", 140 → "99+") and `keyHintChord` (⌥⌘S reads "Option-Command-S" for VoiceOver). Touches `FabrixDesign/Inbox/CountBadge.swift`, `KeyHint.swift`.
- [ ] 2.3 Add `KindTag` tones (`signal`, `neutral`, `halt`), `InboxRow`, `OwnerLabel` and `PlaceholderRow`. The row takes plain values: kind label, tone, requester, task identifier, age, title, summary, owner, stale reason, and the Critical and Problem flags. Tests: `InboxComponentTests.rowAccessibilityLabel` ("Approval. Hire a Designer agent. From CEO, 12 minutes ago. For you.") and `criticalAndProblemAreText`. Touches `FabrixDesign/Badges.swift`, `Inbox/InboxRow.swift`, `OwnerLabel.swift`, `PlaceholderRow.swift`.
- [ ] 2.4 Add `CountedPicker`, which becomes a menu at accessibility sizes and hides a count of 0. Tests: `InboxComponentTests.countedPickerStyle(forAccessibilitySize:)` and `hidesZeroCount`. Touches `FabrixDesign/Inbox/CountedPicker.swift`.
- [ ] 2.5 Add `ReceiptRow`, `KeyValueList` (raw-JSON disclosure; stacks at accessibility sizes), `CommentRow` (sending, failed) and `HistoryRow` (verb first). Tests: `InboxComponentTests.historyRowStartsWithVerb` and `keyValueListStacksAtAccessibilitySizes`. Touches `FabrixDesign/Inbox/*.swift`.
- [ ] 2.6 Add `ChoiceRow`, `VerdictPicker` and `ReasonField`. The field says who reads it, marks it required, and flags text past 4,000 characters as too long. Tests: `InboxComponentTests.reasonFieldValidation` and `verdictPickerRequiresReason`. Touches `FabrixDesign/Inbox/*.swift`.
- [ ] 2.7 Add `DecisionBar` (can be disabled with a reason), `UndoBar` and `ResolvedNotice` (by person, by agent, unknown). The undo bar has four phases (counting, sending, sent, failed), shows the time left as text, and has an announcement per phase. Tests: `InboxComponentTests.undoBarAnnouncements`, `resolvedNoticeText` and `decisionBarDisabledReason`. Touches `FabrixDesign/Inbox/*.swift`, FabrixDesign `Localizable.xcstrings`.

## 3. Feed in Core (stack 3, FabrixCore)

- [ ] 3.1 Add the inbox models: `AttentionView`, `AttentionSource`, `AttentionCardType`, `AttentionAnswer`, `AttentionItem`, `AttentionAudience`, `AttentionFeed`, `AttentionReceipt`, `Person` and `RequesterRef`. Test: `InboxModelTests.answerPerCardType` covers the 16 types plus unknown `[D1]` `[D2]`. Touches `FabrixCore/Inbox/InboxModels.swift`.
- [ ] 3.2 Add `attention(companyID:view:cursor:)` and `people(companyID:)` to `FactoryService`, each with a default that throws `.unsupported`. Test: `InboxModelTests.defaultsAreUnsupported`, with a minimal conformer. Touches `FactoryService.swift`.
- [ ] 3.3 Record sandbox fixtures: a routed feed with every card type, a feed without routing, and a user directory. Extend the seed script with one approval with comments, one interaction of each kind and a second board user. No test; these are inputs. Touches `Tests/FabrixCoreTests/Support/PaperclipFixtures.swift`, `scripts/paperclip-sandbox-seed.sh`.
- [ ] 3.4 Add the attention DTOs and mapping: lenient rows, unknown kinds, routing detection, obligation leads, web path. Tests: `AttentionMappingTests.mapsRoutedFeed`, `feedWithoutRoutingHasNoCloseModes` `[D19]`, `unknownCardTypeOpensInPaperclip`, `malformedCardIsSkipped`, `evidenceFoldsIntoLead` and `textOnlyQuestionOpensInPaperclip` `[D17]`. Touches `Paperclip/AttentionDTOs.swift`, `Paperclip/AttentionMapping.swift`.
- [ ] 3.5 Implement live `attention` and `people`. These mean `.unsupported`: a `404` "API route not found", a `404` without a JSON body, and a `403` "Board user context required". Any other `404` stays `notFound`. Tests: `PaperclipFactoryServiceTests.attentionRequestsView` (path and query), `attentionNotFoundIsUnsupported`, `resourceNotFoundIsNotUnsupported`, `peopleFromUserDirectory` and `peopleForbiddenIsUnsupported`. Touches `PaperclipFactoryService.swift`.
- [ ] 3.6 Add the demo inbox: the stored `inbox: DemoInbox` property, then every card from design §6, a receipt and the people in the extension. Test: `DemoFactoryServiceTests.demoInboxHasEveryKind`. Touches `DemoFactoryService.swift` (one line), `DemoFactoryService+Inbox.swift`.
- [ ] 3.7 Docs and contract. Add an Inbox section to `docs/paperclip-api.md` covering the feed and the user directory. Run `validate` with `SandboxContractTests.attentionFeed`. Touches `docs/paperclip-api.md`, `Tests/FabrixCoreTests/SandboxContractTests.swift`.

## 4. Feed screens (stack 4, FabrixFeatures)

- [ ] 4.1 Add `InboxStore`: support, view, feed, selection, load states, paging, people cache and the generation guard. Tests: `InboxStoreTests.unsupportedIsRemembered`, `staleFeedAfterFactorySwitchIsDropped`, `firstLoadFailureKeepsCompanyUsable`, `badgeCountFromDeskBadgeCount` and `nextPageAppends`. `reset(keepingHeld:)` exists from here, with nothing to keep until slice 6. Touches `FabrixFeatures/Inbox/InboxStore.swift`, `InboxContext.swift`.
- [ ] 4.2 Add `InboxSupportCache`: the answer is kept per factory ID, changed only by a loaded feed or a `404` "API route not found", and absent means Approvals `[D24]`. Tests: `InboxSupportCacheTests.networkErrorKeepsAnswer`, `missingEndpointSetsUnsupported` and `unknownFactoryShowsApprovals`. Touches `FabrixFeatures/Inbox/InboxSupportCache.swift`.
- [ ] 4.3 Wire `AppModel`:
  - an `inbox` property and `inboxBadgeCount`, with `waitingCount` unchanged;
  - refresh under the generation check;
  - `select`, `use` and `disconnect` reset the inbox (the commit before `select`'s reset arrives in 6.6, with the desk);
  - `renew` keeps the inbox.

  Tests: `AppModelTests.inboxRefreshesWithSnapshot`, `companySwitchResetsInbox`, `disconnectResetsInbox`, `renewKeepsInbox` and `approvalsBadgeKeepsWaitingCount`. Touches `AppModel.swift` (about 35 lines).

- [ ] 4.4 Build the inbox screens, read-only, at both widths:
  - the list, with the views, the Stale group, Critical and Problem tags, receipts, and the placeholder, empty and failed states;
  - card detail with task context, and "Open in Paperclip" for every card, checked for same origin `[D21]`.

  Tests: `InboxCardTests.webURLOnlySameOrigin` and `taskContextFromSnapshot` (logic in `InboxCard`). Touches `FabrixFeatures/Inbox/InboxView.swift`, `InboxCardView.swift`, `InboxCard.swift`.

- [ ] 4.5 Navigation: Inbox section first `[D15]` and an Inbox tab. Both read `inboxBadgeCount`, and the layout comes from `InboxSupportCache`. Approvals stays reachable in this slice, so iPhone has five tabs until slice 6. Tests: `NavigatorTests.inboxSectionOnlyWhenSupported`, `compactTabsWithInbox` and `layoutFromCachedSupport`. Touches `Shell/AppSection.swift`, `CompactShell.swift`, `SplitShell.swift`.

## 5. Badge and Inbox menu (stack 5)

- [ ] 5.1 Add `AppIconBadge`. On macOS it sets the Dock badge. On iOS it waits for "Show count on app icon" in Settings, which asks for `.badge` authorization `[D8]` `[D18]`. It follows `inboxBadgeCount`, so the reset in `disconnect`, on factory removal and on an unsupported inbox clears it. Tests: `AppIconBadgeTests.clearsOnSignOut`, `iOSRequiresOptIn` and `macAlwaysOn`, with an injected badge setter. Touches `FabrixFeatures/Inbox/AppIconBadge.swift`, `Lock/SettingsView.swift`.
- [ ] 5.2 Add the Inbox menu: Next, Previous, Switch view, Open task and Copy link. J and K work only while the list has focus. No Refresh entry: ⌘R stays in `FactoryCommands`. The inbox publishes a "text field focused" `FocusedValue` that later decide commands read. Tests: `InboxCommandsTests.nextPreviousMoveSelection`, `singleKeysNeedListFocus` and `noShortcutClashesWithFactoryCommands`. The last one is a table check of every inbox key against `FactoryCommands` and the reserved system keys (⌘R, ⌘Z, ⌃⌘S, ⌘⌫). Touches `FabrixFeatures/Inbox/InboxCommands.swift`, `App/Shared/FabrixApp.swift` (`.commands { InboxCommands() }` beside `FactoryCommands`).

## 6. Approvals in the inbox (stack 6)

- [ ] 6.1 Add `ApprovalDetail`, `ApprovalField`, `AttentionClosure` and `FactoryServiceError.alreadyClosed`, and conform `FactoryServiceError` to `LocalizedError`. Add `approvalDetail` and `requestRevision` to `FactoryService` with defaults. Tests: `InboxModelTests.approvalPayloadFields` (nested values become text, raw JSON kept) and `factoryServiceErrorDescriptions`. Touches `InboxModels.swift`, `FactoryService.swift`.
- [ ] 6.2 Add `PaperclipError.alreadyClosed(AttentionClosure)` and `.interactionClosed(code:message:)`. `perform` throws them only for the coded `409` bodies in design §2, and other coded `409`s stay `.conflict`. Give both cases a description, and update the existing `switch` statements. Tests: `PaperclipClientTests.alreadyClosedBodyIsDecoded` (the body from design §2), `interactionCodesAreInteractionClosed`, `workspaceSyncConflictStaysConflict` and `PaperclipErrorMessageTests.alreadyClosedMessage`. Touches `PaperclipClient.swift`, `PaperclipError.swift`, `PaperclipDTOs.swift`.
- [ ] 6.3 Live approval detail and revision, plus `closingErrors(_:reread:)` in `PaperclipFactoryService` with the signed-in user from `cli-auth/me`, cached per connection. A `422 "Only pending…"` on approve, reject or revision re-reads the approval and becomes `.alreadyClosed` `[D16]`. The user's own earlier answer counts as success. Tests: `PaperclipFactoryServiceTests.approvalDetailReadsBoth`, `rejectAfterOtherDecisionIsAlreadyClosed`, `ownEarlierRejectIsSuccess`, `sameVerdictRepeatedSucceeds` and `requestRevisionSendsNote`. Touches `PaperclipFactoryService.swift`, `AttentionMapping.swift`.
- [ ] 6.4 Add a guard: the fallback Approvals message doesn't change. Test: `ApprovalFlowTests.alreadyDecidedMessageUnchanged`. With a service whose `decide` throws `.alreadyClosed`, `decisionErrors` holds "This was already decided on the board.". Touches `Tests/FabrixFeaturesTests/ApprovalFlowTests.swift`.
- [ ] 6.5 Add `InboxDesk` with the same tests as `ApprovalDesk`, for `.approve`, `.reject` and `.requestRevision`. Tests: `InboxDeskTests.undoInsideWindow`, `beginCommitLocks`, `restageAfterSignOut` and `keepOnlyDropsGoneCards`. Touches `FabrixFeatures/Inbox/InboxDesk.swift`.
- [ ] 6.6 Add decisions to `InboxStore`:
  - stage after `AppLock.confirmDecision()`, with a commit timer and Send now;
  - register each staged action with the window's `UndoManager`;
  - `commitStaged()`;
  - handle `.alreadyClosed`: no retry, a notice per width, then a refresh;
  - disable decisions while offline `[D13]`;
  - keep decision failure logs free of text;
  - `AppModel.select` awaits `inbox.commitStaged()` before its reset `[D22]`, and the reset keeps actions held for sign-in.

  Tests: `InboxStoreTests.decisionWaitsForWindow`, `cancelledAuthenticationStagesNothing`, `undoManagerUndoesStagedAction`, `alreadyClosedShowsNoticeAndRefreshesWithoutRetry`, `offlineDisablesDecisions`, `backgroundCommitsInboxAndApprovals`, `failureLogsCarryNoContent` (a failed decision; an injected log sink sees only operation, card kind and error type), `AppModelTests.companySwitchCommitsThenResetsInbox`, `heldActionSurvivesCompanySwitch` and `renewKeepsStagedInboxActions`. Touches `InboxStore.swift`, `InboxDesk.swift`, `AppModel.swift` (`select`, `commitStagedDecisions`), `Lock/AppLock+Approvals.swift`.

- [ ] 6.7 Build the approval card UI: the `KeyValueList` payload, Request revision with a required note `[D3]`, `UndoBar` and `ResolvedNotice`. Test: `InboxStoreTests.revisionNeedsNote`. Touches `InboxCardView.swift`, `ApprovalCardContent.swift`.
- [ ] 6.8 Navigation and Overview:
  - When the inbox is supported, remove the Approvals section and tab. iPhone tabs become Inbox, Factory, Tasks and Agents.
  - Overview's approve and reject go to `inbox`.
  - `waitingApprovals` leaves out what `InboxDesk` holds.
  - "Waiting on you" shows `inboxBadgeCount` `[D23]`.
  - Open picks the view that holds the card.

  Tests: `NavigatorTests.approvalsOnlyWithoutInbox`, `overviewOpenSelectsCardInItsView`, `AppModelTests.overviewDecisionUsesInboxDesk`, `waitingApprovalsSkipsInboxStaged` and `OverviewMetricsTests.waitingUsesInboxBadge`. Touches `AppSection.swift`, `CompactShell.swift`, `SplitShell.swift`, `OverviewView.swift`, `AppModel.swift`, `Logic/OverviewMetrics.swift`.

- [ ] 6.9 Demo: approval payload and `simulateAlreadyClosed`. Test: `DemoFactoryServiceTests.demoApprovalAlreadyClosed`. Touches `DemoFactoryService+Inbox.swift`.
- [ ] 6.10 Inbox menu: Approve or accept (⌘↩), Reject (⌥⌘⌫) `[D14]` and Request revision (⌥⌘↩). All three are disabled while a text field has focus. Tests: `InboxCommandsTests.approveDisabledWhenCardDoesNotAllowIt` and `decideDisabledWhileTyping`. Touches `InboxCommands.swift`.
- [ ] 6.11 Docs: approval endpoints and the 422 mapping. Run `validate` with `SandboxContractTests.approvalInInbox`: approve, then a second user's reject is already closed. Touches `docs/paperclip-api.md`, `Tests/FabrixCoreTests/SandboxContractTests.swift`.

## 7. Approval comments (stack 7)

- [ ] 7.1 Add `ApprovalComment`, and add `addApprovalComment` to `FactoryService` with a default. `ApprovalDetail` gains `comments`. Test: `InboxModelTests.commentsDefaultEmpty`. Touches `InboxModels.swift`, `FactoryService.swift`.
- [ ] 7.2 Live: read comments beside the approval, and post a comment. Tests: `PaperclipFactoryServiceTests.approvalDetailReadsComments` and `addCommentBody`. Touches `PaperclipFactoryService.swift`, `AttentionMapping.swift`.
- [ ] 7.3 Store and UI: comments with a composer, posted at once with sending, failed and retry states `[D20]`. The composer is hidden when unsupported. Tests: `InboxStoreTests.commentFailureKeepsDraft`, `composerHiddenWhenUnsupported`, and `failureLogsCarryNoContent` extended with a failed comment post. Touches `InboxStore.swift`, `ApprovalCardContent.swift`.
- [ ] 7.4 Demo comments. Test: `DemoFactoryServiceTests.demoCommentPosted`. Docs and `validate`: `SandboxContractTests.approvalComments`. Touches `docs/paperclip-api.md`, `Tests/FabrixCoreTests/SandboxContractTests.swift`.

## 8. Confirmations (stack 8)

- [ ] 8.1 Add `ThreadRequest` with `Confirmation`: labels, `rejectRequiresReason`, reason label, plan target and details. Add `threadRequest`, `acceptRequest` and `rejectRequest` to `FactoryService` with defaults. Test: `InboxModelTests.toolActionConfirmationOpensInPaperclip` `[D1]`. Touches `InboxModels.swift`, `FactoryService.swift`.
- [ ] 8.2 Live: read through `GET issues/{i}/interactions`, then accept and reject. `.interactionClosed` goes through `closingErrors`, which re-reads and maps to `.alreadyClosed`, or to success when the user's own answer matches `[D16]`. Tests: `PaperclipFactoryServiceTests.acceptRequest`, `rejectSendsReason`, `interactionAlreadyResolvedIsAlreadyClosed`, `ownEarlierAcceptIsSuccess` and `missingRequestIsAlreadyClosed`. Touches `PaperclipFactoryService.swift`, `AttentionDTOs.swift`, `AttentionMapping.swift`.
- [ ] 8.3 Desk and store: `.accept` and `.decline(reason)`, with Face ID and the undo window. Test: `InboxStoreTests.declineRequiresReasonWhenAsked`. Touches `InboxDesk.swift`, `InboxStore.swift`.
- [ ] 8.4 UI for the confirmation, plan review and deliverable review cards. Demo: a plan review and a reason-required confirmation. Test: `DemoFactoryServiceTests.demoPlanReviewAccepts`. Touches `ConfirmationCardContent.swift`, `DemoFactoryService+Inbox.swift`.
- [ ] 8.5 Docs and `validate`: `SandboxContractTests.confirmation`. Touches `docs/paperclip-api.md`, `Tests/FabrixCoreTests/SandboxContractTests.swift`.

## 9. Questions (stack 9)

- [ ] 9.1 Add `Question`, `QuestionOption` (`recommended`, `freeText`) and `QuestionAnswer`, plus `answerQuestions` with its default. Test: `AttentionMappingTests.questionSetRecommendedCopiedToOptions`. Touches `InboxModels.swift`, `FactoryService.swift`, `AttentionMapping.swift`.
- [ ] 9.2 Live `respond` through `closingErrors`. Tests: `PaperclipFactoryServiceTests.answerQuestionsBody` (option IDs and `otherText`) and `ownEarlierAnswerIsSuccess`. Touches `PaperclipFactoryService.swift`.
- [ ] 9.3 Store and UI: `.answer` staged with Face ID. Submit is enabled only when the required questions are answered, and Other text is sent. Tests: `InboxStoreTests.submitNeedsRequiredAnswers` and `otherTextIsSent`. Touches `InboxDesk.swift`, `InboxStore.swift`, `QuestionsCardContent.swift`.
- [ ] 9.4 Demo questions card. Test: `DemoFactoryServiceTests.demoQuestionsAnswered`. Docs and `validate`: `SandboxContractTests.questions`, which also records how `answerMode: text` behaves `[D17]`. Touches `docs/paperclip-api.md`, `Tests/FabrixCoreTests/SandboxContractTests.swift`.

## 10. Item verdicts (stack 10)

- [ ] 10.1 Add `VerdictItem`, `Verdict` and `ItemVerdict`, plus `submitVerdicts` with its default. Test: `AttentionMappingTests.verdictsDefaultToAllThree`. Touches `InboxModels.swift`, `FactoryService.swift`, `AttentionMapping.swift`.
- [ ] 10.2 Live `verdicts` through `closingErrors`. Test: `PaperclipFactoryServiceTests.submitVerdictsBody`. Touches `PaperclipFactoryService.swift`.
- [ ] 10.3 Store and UI: a `VerdictPicker` per item, reasons required on `requireReasonOn`, and Approve all only when allowed. Tests: `InboxStoreTests.verdictsNeedReasonWhereRequired` and `approveAllOnlyWhenAllowed`. Touches `InboxDesk.swift`, `InboxStore.swift`, `VerdictsCardContent.swift`.
- [ ] 10.4 Demo item review. Test: `DemoFactoryServiceTests.demoVerdictsSubmitted`. Docs and `validate`: `SandboxContractTests.itemVerdicts`. Touches `docs/paperclip-api.md`, `Tests/FabrixCoreTests/SandboxContractTests.swift`.

## 11. Snooze, archive, withdraw and receipts (stack 11)

- [ ] 11.1 Add `AttentionCloseMode`, plus `closeAttention` and `dismissReceipt` with their defaults. Test: `InboxModelTests.closeModesFromCard`: only the server's `closeModes`, none without routing `[D19]`. Touches `InboxModels.swift`, `FactoryService.swift`.
- [ ] 11.2 Live close with fingerprint and until. `409 attention_already_closed` becomes `.alreadyClosed`. A `404` "API route not found" means `.unsupported`, and "Card not found" means the card is gone. Also live receipt dismissal. Tests: `PaperclipFactoryServiceTests.snoozeBody`, `archiveSendsFingerprint`, `withdrawSendsReason`, `closeAlreadyClosed` and `dismissReceiptBody`. Touches `PaperclipFactoryService.swift`.
- [ ] 11.3 Desk: `.snooze(until)` and `.archive`, staged with no Face ID `[D5]`. Snooze presets are in local time. Tests: `SnoozePresetTests.tomorrowMorningAcrossDST`, `nextMondayFromSunday` and `InboxStoreTests.snoozeDoesNotAskForFaceID`. Touches `InboxDesk.swift`, `SnoozePreset.swift`, `InboxStore.swift`.
- [ ] 11.4 Withdraw: a reason, then a destructive confirmation, then Face ID, sent at once `[D4]`. It is hidden for hire approvals and wherever `closeModes` lacks it. Tests: `InboxStoreTests.withdrawNeedsReasonAndConfirmation` and `withdrawHiddenOnHire`. Touches `InboxStore.swift`, `WithdrawSheet.swift`.
- [ ] 11.5 UI:
  - swipe actions on iPhone;
  - a context menu and toolbar on iPad and Mac;
  - VoiceOver custom actions;
  - receipt dismiss `[D9]`;
  - Inbox menu: Snooze (⌥⌘S or S) and Archive (⌃⌘A or E).

  Test: `InboxCommandsTests.snoozeOpensPresets`. Touches `InboxView.swift`, `InboxCommands.swift`.

- [ ] 11.6 Demo close and receipt dismissal. Test: `DemoFactoryServiceTests.demoSnoozeHidesCard`. Docs and `validate`: `SandboxContractTests.closeModes`. Touches `docs/paperclip-api.md`, `Tests/FabrixCoreTests/SandboxContractTests.swift`.

## 12. Claim and transfer (stack 12)

- [ ] 12.1 Add `claimAttention` and `transferAttention` with their defaults. Test: `InboxModelTests.claimAndTransferOnlyOnThreadRequests` `[D6]`. Touches `FactoryService.swift`, `InboxModels.swift`.
- [ ] 12.2 Live claim and transfer. `409 attention_already_closed` becomes `.alreadyClosed`, other `409`s stay conflicts, and the `422` reason passes through. Tests: `PaperclipFactoryServiceTests.claimPath`, `transferBody` and `transferRefusedKeepsReason`. Touches `PaperclipFactoryService.swift`.
- [ ] 12.3 Store and UI:
  - Claim in Unassigned;
  - a Transfer picker from `people`: a sheet on compact, a popover with search on regular, hidden when people are unsupported `[D7]`;
  - "Transferred by" on the owner label;
  - Inbox menu: Claim (⌃⌘C) and Transfer (⌃⌘T).

  Tests: `InboxStoreTests.transferHiddenWithoutPeople` and `claimMovesCardAfterRefresh`. Touches `InboxStore.swift`, `TransferPicker.swift`, `InboxCommands.swift`.

- [ ] 12.4 Demo claim and transfer. Test: `DemoFactoryServiceTests.demoClaimMovesToMine`. Docs and `validate`: `SandboxContractTests.claimAndTransfer`, which uses the seeded second board user. Touches `docs/paperclip-api.md`, `Tests/FabrixCoreTests/SandboxContractTests.swift`.

## 13. Decision history (stack 13)

- [ ] 13.1 Add `DecisionRecord` and `DecisionHistoryPage`, plus `attentionHistory` with its default. Test: `AttentionMappingTests.historyActionVerb` (`withdrawn`, `issue_closed`, `expired`). Touches `InboxModels.swift`, `FactoryService.swift`, `AttentionMapping.swift`.
- [ ] 13.2 Live history, with paging. `scope=mine` is sent only when routed `[D19]`. Tests: `PaperclipFactoryServiceTests.historyScopeOnlyWhenRouted` and `historyNextPage`. Touches `PaperclipFactoryService.swift`.
- [ ] 13.3 UI: a History screen on compact, and history in the content column on regular, using `HistoryRow`. Inbox menu: History (⌘Y). Test: `InboxStoreTests.historyLoadsMoreAtEnd`. Touches `HistoryView.swift`, `InboxStore.swift`, `InboxCommands.swift`.
- [ ] 13.4 Demo history with every outcome. Test: `DemoFactoryServiceTests.demoHistoryHasEveryOutcome`. Docs and `validate`: `SandboxContractTests.history`. Touches `docs/paperclip-api.md`, `Tests/FabrixCoreTests/SandboxContractTests.swift`.

## 14. Verify and archive (stack 14)

- [ ] 14.1 Run the full sandbox contract suite against the pinned Paperclip image and `latest`. Take iPhone, iPad and Mac screenshots of the demo inbox at default and accessibility sizes, with the VoiceOver checks from design §11. No test (verification).
- [ ] 14.2 Record what the sandbox showed for the open items in `docs/paperclip-api.md`, and update the specs if any differ:
  - how `local_trusted` routes the inbox for `local-board`;
  - `answerMode: text` answers `[D17]`;
  - whether accepting a plan target needs a body;
  - whether interaction `409`s now carry a resolver;
  - the status a submitted item review takes.

  No test (docs).

- [ ] 14.3 Archive the OpenSpec change `add-inbox` as the last commit. No test.
