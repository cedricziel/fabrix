Slices ship as one gh stack, one PR per numbered group, bottom to top. Each layer builds, passes its tests and can ship on its own.

| Slice | Stack position | Shared files edited | Changes shape of FactoryService / Models / AppModel | Touches undo window / Face ID / Auth / Connections / Keychain / telemetry scrubbing | Needs `validate` sandbox | Model |
| --- | --- | --- | --- | --- | --- | --- |
| 1. Inbox components | 1 (bottom) | FabrixDesign `Localizable.xcstrings` | no / no / no | none | no | sonnet |
| 2. Inbox feed | 2 | `FactoryService.swift`, `DemoFactoryService.swift`, `AppModel.swift`, `PaperclipDTOs.swift`, FabrixFeatures string catalog, `AppSection.swift`, `CompactShell.swift`, `SplitShell.swift`, `AttributeScrubber.swift` | yes / yes / yes | telemetry scrubbing (route from `url.full`, task 2.13) | yes | opus |
| 3. Approvals in the inbox | 3 | `FactoryService.swift`, `DemoFactoryService.swift`, `AppModel.swift`, `PaperclipClient.swift`, `PaperclipError.swift`, string catalogs, `AppSection.swift`, `OverviewView.swift`, `AppLock+Approvals.swift` | yes / yes / yes | undo window, Face ID | yes | opus |
| 4. Confirmations | 4 | `FactoryService.swift`, `DemoFactoryService.swift`, string catalogs | yes / yes / no | undo window, Face ID | yes | opus |
| 5. Questions | 5 | `FactoryService.swift`, `DemoFactoryService.swift`, string catalogs | yes / yes / no | undo window, Face ID | yes | opus |
| 6. Item verdicts | 6 | `FactoryService.swift`, `DemoFactoryService.swift`, string catalogs | yes / yes / no | undo window, Face ID | yes | opus |
| 7. Snooze, archive, withdraw, receipts | 7 | `FactoryService.swift`, `DemoFactoryService.swift`, string catalogs | yes / yes / no | undo window (snooze, archive), Face ID (withdraw) | yes | opus |
| 8. Claim and transfer | 8 | `FactoryService.swift`, `DemoFactoryService.swift`, string catalogs | yes / yes / no | none | yes | opus |
| 9. Decision history | 9 | `FactoryService.swift`, `DemoFactoryService.swift`, string catalogs | yes / yes / no | none | yes | opus |
| 10. Verify and archive | 10 (top) | `openspec/specs/*`, `docs/paperclip-api.md` | no / no / no | none | yes (pinned image and `latest`) | sonnet |

Slice 1 touches only FabrixDesign and slice 2's Core work touches only FabrixCore, so the two can be built in parallel. Slice 2's screens rebase onto slice 1 before its PR is submitted. Shared files in slices 4–9 are touched only by appending a method and its default, or a demo card. `Models.swift` is never edited: new types go in `FabrixCore/Inbox/InboxModels.swift`. `Auth/`, `Connections/` and the Keychain are never touched.

Every task runs `xcrun swift test --package-path Packages/FabrixKit`, `scripts/sync-string-catalogs.sh`, `scripts/check-feature-strings.sh`, `xcodegen generate` and both `xcodebuild` builds before it is ticked. Each slice that adds a call updates `docs/paperclip-api.md` in the same PR.

## 1. Inbox components (stack 1, FabrixDesign)

- [ ] 1.1 Add `DesignIndependenceTests.noCoreImport`, a source scan that fails if any FabrixDesign file imports FabrixCore. It passes today. It is the guard for this slice. Touches `Tests/FabrixDesignTests/DesignIndependenceTests.swift`.
- [ ] 1.2 Add `CountBadge` and `KeyHint`, with their previews. Test: `InboxComponentTests.countBadgeText` (0 → hidden, 7 → "7", 140 → "99+") and `keyHintChord` (⌃⌘S reads "Control-Command-S" for VoiceOver). Touches `FabrixDesign/Inbox/CountBadge.swift`, `KeyHint.swift`.
- [ ] 1.3 Add `KindTag` tones (`signal`, `neutral`, `halt`), plus `InboxRow`, `OwnerLabel` and `PlaceholderRow`. The row takes plain values: kind label, tone, requester, task identifier, age, title, summary, owner, stale reason and the Critical and Problem flags. Test: `InboxComponentTests.rowAccessibilityLabel` ("Approval. Hire a Designer agent. From CEO, 12 minutes ago. For you.") and `criticalAndProblemAreText`. Touches `FabrixDesign/Badges.swift`, `Inbox/InboxRow.swift`, `OwnerLabel.swift`, `PlaceholderRow.swift`.
- [ ] 1.4 Add `CountedPicker`, which becomes a menu at accessibility sizes and hides a count of 0. Test: `InboxComponentTests.countedPickerStyle(forAccessibilitySize:)` and `hidesZeroCount`. Touches `FabrixDesign/Inbox/CountedPicker.swift`.
- [ ] 1.5 Add `ReceiptRow`, `KeyValueList` (with a raw-JSON disclosure; stacks at accessibility sizes), `CommentRow` (sending, failed) and `HistoryRow` (each outcome starts with its verb). Test: `InboxComponentTests.historyRowStartsWithVerb` and `keyValueListStacksAtAccessibilitySizes`. Touches `FabrixDesign/Inbox/*.swift`.
- [ ] 1.6 Add `ChoiceRow`, `VerdictPicker` and `ReasonField` (shows who reads it, required, and too long past 4,000 characters). Test: `InboxComponentTests.reasonFieldValidation` and `verdictPickerRequiresReason`. Touches `FabrixDesign/Inbox/*.swift`.
- [ ] 1.7 Add `DecisionBar`, which can be disabled with a reason, `UndoBar` (counting, sending, sent, failed; time left as text; an announcement string per phase) and `ResolvedNotice` (by person, by agent, unknown). Test: `InboxComponentTests.undoBarAnnouncements`, `resolvedNoticeText` and `decisionBarDisabledReason`. Touches `FabrixDesign/Inbox/*.swift`, FabrixDesign `Localizable.xcstrings`.

## 2. Inbox feed (stack 2, FabrixCore + FabrixFeatures)

- [ ] 2.1 Add the inbox models: `AttentionView`, `AttentionSource`, `AttentionCardType`, `AttentionAnswer`, `AttentionItem`, `AttentionAudience`, `AttentionFeed`, `AttentionReceipt`, `Person` and `RequesterRef`. Test: `InboxModelTests.answerPerCardType` covers the full table of 16 types plus unknown `[D1]` `[D2]`. Touches `FabrixCore/Inbox/InboxModels.swift`.
- [ ] 2.2 Add `attention(companyID:view:cursor:)` and `people(companyID:)` to `FactoryService`, each with a default that throws `.unsupported`. Test: `InboxModelTests.defaultsAreUnsupported`, with a minimal conformer. Touches `FactoryService.swift`.
- [ ] 2.3 Record feed fixtures from the sandbox: a routed feed with every card type, a feed without routing, and a user directory. No test; they are inputs. Touches `Tests/FabrixCoreTests/Support/PaperclipFixtures.swift`, `scripts/paperclip-sandbox-seed.sh` (one approval with comments, one interaction of each kind and a second board user).
- [ ] 2.4 Add the attention DTOs and their mapping, with lenient rows, unknown kinds, routing detection, obligation leads and the web path. Tests: `AttentionMappingTests.mapsRoutedFeed`, `feedWithoutRoutingHasNoCloseModes` `[D19]`, `unknownCardTypeOpensInPaperclip`, `malformedCardIsSkipped`, `evidenceFoldsIntoLead` and `textOnlyQuestionOpensInPaperclip` `[D17]`. Touches `Paperclip/AttentionDTOs.swift`, `Paperclip/AttentionMapping.swift`.
- [ ] 2.5 Implement `attention` and `people` live. A `404` "API route not found" or without a JSON body, or a `403` "Board user context required", means `.unsupported`; any other `404` stays `notFound`. Tests: `PaperclipFactoryServiceTests.attentionRequestsView` (path and query), `attentionNotFoundIsUnsupported`, `resourceNotFoundIsNotUnsupported`, `peopleFromUserDirectory` and `peopleForbiddenIsUnsupported`. Touches `PaperclipFactoryService.swift`.
- [ ] 2.6 Add the demo inbox: every card from design §6, a receipt and the people. Test: `DemoFactoryServiceTests.demoInboxHasEveryKind`. Touches `DemoFactoryService.swift`.
- [ ] 2.7 Add `InboxStore`: support, view, feed, selection, load states, paging, the people cache and the generation guard. Tests: `InboxStoreTests.unsupportedIsRemembered`, `staleFeedAfterFactorySwitchIsDropped`, `firstLoadFailureKeepsCompanyUsable`, `badgeCountFromDeskBadgeCount` and `nextPageAppends`. Touches `FabrixFeatures/Inbox/InboxStore.swift`, `InboxContext.swift`.
- [ ] 2.8 Wire `AppModel`: an `inbox` property, refresh, reset on `use` and `select` but not on `renew`, and `waitingCount`. Test: `AppModelTests.inboxRefreshesWithSnapshot`, `inboxResetsOnCompanySwitch` and `renewKeepsStagedInboxActions`. Touches `AppModel.swift` (about 30 lines).
- [ ] 2.9 Add the inbox screens, read-only: list with views, Stale group, Critical and Problem tags, receipts, placeholder, empty and failed states, and card detail with task context and "Open in Paperclip" for every card, checked for same origin `[D21]`. Both widths. Test: `InboxCardTests.webURLOnlySameOrigin` and `taskContextFromSnapshot` (logic in `InboxCard`). Touches `FabrixFeatures/Inbox/InboxView.swift`, `InboxCardView.swift`, `InboxCard.swift`.
- [ ] 2.10 Navigation: Inbox section first `[D15]` and an Inbox tab with the badge. In this slice Approvals stays reachable, so iPhone briefly has five tabs, until slice 3. Test: `NavigatorTests.inboxSectionOnlyWhenSupported` and `compactTabsWithInbox`. Touches `Shell/AppSection.swift`, `CompactShell.swift`, `SplitShell.swift`.
- [ ] 2.11 Add `AppIconBadge`: the Dock badge on macOS, and on iOS behind "Show count on app icon" in Settings `[D8]` `[D18]`. Clear it on sign-out, on factory removal and when the inbox is unsupported. Test: `AppIconBadgeTests.clearsOnSignOut`, `iOSRequiresOptIn` and `macAlwaysOn`, with an injected badge setter. Touches `FabrixFeatures/Inbox/AppIconBadge.swift`, `Lock/SettingsView.swift`.
- [ ] 2.12 Inbox menu: Next, Previous, Switch view, Refresh, Open task and Copy link, with the J and K single keys only while the list has focus. Test: `InboxCommandsTests.nextPreviousMoveSelection` and `singleKeysNeedListFocus`. Touches `FabrixFeatures/Inbox/InboxCommands.swift`, `App/macOS` (`.commands`).
- [ ] 2.13 Derive `paperclip.api.route` from the scrubbed `url.full` when a span has no `url.path`, keeping the factory-host and `/api/` checks. Test: `AttributeScrubberTests.attentionRouteFromFullURL` (a span with only `url.full` for the close route gets `/api/companies/{id}/attention/issue_thread_interaction/{id}/close`; it fails today). Touches `FabrixTelemetry/AttributeScrubber.swift`, `Tests/FabrixTelemetryTests`.
- [ ] 2.14 Docs: an Inbox section for the feed and the user directory in `docs/paperclip-api.md`. Run `validate` against the sandbox with `SandboxContractTests.attentionFeed`. Touches `docs/paperclip-api.md`, `SandboxContractTests.swift`.

## 3. Approvals in the inbox (stack 3)

- [ ] 3.1 Add `ApprovalDetail`, `ApprovalField`, `ApprovalComment`, `AttentionClosure` and `FactoryServiceError.alreadyClosed`. Add `approvalDetail`, `addApprovalComment` and `requestRevision` to `FactoryService`, each with a default that throws `.unsupported`. Test: `InboxModelTests.approvalPayloadFields` (nested values become text, the raw JSON is kept). Touches `InboxModels.swift`, `FactoryService.swift`.
- [ ] 3.2 Make `PaperclipClient` keep the body's `code` and `details`, and add `PaperclipError.alreadyClosed`. Tests: `PaperclipClientTests.alreadyClosedBodyIsDecoded` (the 409 body from design §2) and `otherConflictsStayConflicts`. Touches `PaperclipClient.swift`, `PaperclipError.swift`, `PaperclipDTOs.swift`.
- [ ] 3.3 Live approval detail, comments and revision. Map `422 "Only pending…"` on approve, reject and revision to a read of the approval, then `.alreadyClosed` `[D16]`. Tests: `PaperclipFactoryServiceTests.approvalDetailReadsBoth`, `rejectAfterOtherDecisionIsAlreadyClosed`, `sameVerdictRepeatedSucceeds` and `requestRevisionSendsNote`. Touches `PaperclipFactoryService.swift`, `AttentionMapping.swift`.
- [ ] 3.4 Add `InboxDesk` with the same tests as `ApprovalDesk`, for `.approve`, `.reject` and `.requestRevision`. Tests: `InboxDeskTests.undoInsideWindow`, `beginCommitLocks`, `restageAfterSignOut` and `keepOnlyDropsGoneCards`. Touches `FabrixFeatures/Inbox/InboxDesk.swift`.
- [ ] 3.5 Add `InboxStore` decisions: stage after `AppLock.confirmDecision()`, a commit timer, Send now, `commitStaged()`, the `.alreadyClosed` handling (no retry, a notice, then a refresh), and offline disabling `[D13]`. Tests: `InboxStoreTests.decisionWaitsForWindow`, `cancelledAuthenticationStagesNothing`, `alreadyClosedShowsNoticeAndRefreshesWithoutRetry`, `offlineDisablesDecisions` and `backgroundCommitsInboxAndApprovals`. Touches `InboxStore.swift`, `AppModel.swift` (`commitStagedDecisions`), `Lock/AppLock+Approvals.swift`.
- [ ] 3.6 Approval card UI: `KeyValueList` payload, comments with a composer (sending, failed, retry) `[D20]`, Request revision with a required note `[D3]`, `UndoBar` and `ResolvedNotice`. Test: `InboxStoreTests.commentFailureKeepsDraft` and `revisionNeedsNote`. Touches `InboxCardView.swift`, `ApprovalCardContent.swift`.
- [ ] 3.7 Navigation: when the inbox is supported, remove the Approvals section and tab. iPhone tabs become Inbox, Factory, Tasks and Agents. Overview's approve and reject go to `inbox`, and Open selects the approval in the inbox. Tests: `NavigatorTests.approvalsOnlyWithoutInbox`, `overviewOpenSelectsInboxCard` and `AppModelTests.overviewDecisionUsesInboxDesk`. Touches `AppSection.swift`, `CompactShell.swift`, `SplitShell.swift`, `OverviewView.swift`.
- [ ] 3.8 Demo: payload, comments and `simulateAlreadyClosed`. Test: `DemoFactoryServiceTests.demoApprovalAlreadyClosed`. Touches `DemoFactoryService.swift`.
- [ ] 3.9 Inbox menu: Approve or accept (⌘↩), Reject (⌘⌫) `[D14]`, Request revision (⌥⌘↩) and Undo (⌘Z). Test: `InboxCommandsTests.approveDisabledWhenCardDoesNotAllowIt`. Touches `InboxCommands.swift`.
- [ ] 3.10 Telemetry guard: `ScrubbingExporterTests.inboxErrorLogsCarryNoText` (a failed comment post and a failed decision log no comment text, note or title). Touches `Tests/FabrixTelemetryTests`. Docs: approval endpoints and the 422 mapping. Run `validate` with `SandboxContractTests.approvalInInbox` (approve, then a second user's reject is already closed).

## 4. Confirmations (stack 4)

- [ ] 4.1 Add `ThreadRequest` with `Confirmation` (labels, `rejectRequiresReason`, reason label, plan target, details). Add `threadRequest`, `acceptRequest` and `rejectRequest` to `FactoryService` with defaults. Test: `InboxModelTests.toolActionConfirmationOpensInPaperclip` `[D1]`. Touches `InboxModels.swift`, `FactoryService.swift`.
- [ ] 4.2 Live: read through `GET issues/{i}/interactions`; accept and reject; map the interaction `409` codes to a re-read, then `.alreadyClosed`; any other `409` stays a conflict `[D16]`. Tests: `PaperclipFactoryServiceTests.acceptRequest`, `rejectSendsReason`, `interactionAlreadyResolvedIsAlreadyClosed`, `workspaceSyncConflictStaysConflict` and `missingRequestIsAlreadyClosed`. Touches `PaperclipFactoryService.swift`, `AttentionDTOs.swift`, `AttentionMapping.swift`.
- [ ] 4.3 Desk and store: `.accept` and `.decline(reason)`, with Face ID and the undo window. Test: `InboxStoreTests.declineRequiresReasonWhenAsked`. Touches `InboxDesk.swift`, `InboxStore.swift`.
- [ ] 4.4 UI: the confirmation, plan review and deliverable review cards. Demo: plan review and a reason-required confirmation. Test: `DemoFactoryServiceTests.demoPlanReviewAccepts`. Touches `ConfirmationCardContent.swift`, `DemoFactoryService.swift`.
- [ ] 4.5 Docs and `validate`: `SandboxContractTests.confirmation`.

## 5. Questions (stack 5)

- [ ] 5.1 Add `Question`, `QuestionOption` (`recommended`, `freeText`) and `QuestionAnswer`, plus `answerQuestions` with its default. Test: `AttentionMappingTests.questionSetRecommendedCopiedToOptions`. Touches `InboxModels.swift`, `FactoryService.swift`, `AttentionMapping.swift`.
- [ ] 5.2 Live `respond`. Test: `PaperclipFactoryServiceTests.answerQuestionsBody` (option IDs and `otherText`). Touches `PaperclipFactoryService.swift`.
- [ ] 5.3 Store and UI: `.answer` staged with Face ID; Submit only when the required questions are answered; Other text. Test: `InboxStoreTests.submitNeedsRequiredAnswers` and `otherTextIsSent`. Touches `InboxDesk.swift`, `InboxStore.swift`, `QuestionsCardContent.swift`.
- [ ] 5.4 Demo questions card. Test: `DemoFactoryServiceTests.demoQuestionsAnswered`. Docs and `validate`: `SandboxContractTests.questions`, which also records how `answerMode: text` behaves `[D17]`.

## 6. Item verdicts (stack 6)

- [ ] 6.1 Add `VerdictItem`, `Verdict` and `ItemVerdict`, plus `submitVerdicts` with its default. Test: `AttentionMappingTests.verdictsDefaultToAllThree`. Touches `InboxModels.swift`, `FactoryService.swift`, `AttentionMapping.swift`.
- [ ] 6.2 Live `verdicts`. Test: `PaperclipFactoryServiceTests.submitVerdictsBody`. Touches `PaperclipFactoryService.swift`.
- [ ] 6.3 Store and UI: per-item `VerdictPicker`, reasons required on `requireReasonOn`, Approve all only when allowed. Test: `InboxStoreTests.verdictsNeedReasonWhereRequired` and `approveAllOnlyWhenAllowed`. Touches `InboxDesk.swift`, `InboxStore.swift`, `VerdictsCardContent.swift`.
- [ ] 6.4 Demo item review. Test: `DemoFactoryServiceTests.demoVerdictsSubmitted`. Docs and `validate`: `SandboxContractTests.itemVerdicts`.

## 7. Snooze, archive, withdraw and receipts (stack 7)

- [ ] 7.1 Add `AttentionCloseMode`, plus `closeAttention` and `dismissReceipt` with their defaults. Test: `InboxModelTests.closeModesFromCard` (only the server's `closeModes`, none without routing) `[D19]`. Touches `InboxModels.swift`, `FactoryService.swift`.
- [ ] 7.2 Live close with fingerprint and until; `409 attention_already_closed` becomes `.alreadyClosed`; a `404` "API route not found" means `.unsupported`, while "Card not found" means the card is gone; receipt dismissal. Tests: `PaperclipFactoryServiceTests.snoozeBody`, `archiveSendsFingerprint`, `withdrawSendsReason`, `closeAlreadyClosed` and `dismissReceiptBody`. Touches `PaperclipFactoryService.swift`.
- [ ] 7.3 Desk: `.snooze(until)` and `.archive`, staged with no Face ID `[D5]`. Snooze presets in local time. Tests: `SnoozePresetTests.tomorrowMorningAcrossDST` and `nextMondayFromSunday`, and `InboxStoreTests.snoozeDoesNotAskForFaceID`. Touches `InboxDesk.swift`, `SnoozePreset.swift`, `InboxStore.swift`.
- [ ] 7.4 Withdraw: reason, then a destructive confirmation, then Face ID, sent at once `[D4]`; hidden for hire approvals and wherever `closeModes` lacks it. Test: `InboxStoreTests.withdrawNeedsReasonAndConfirmation` and `withdrawHiddenOnHire`. Touches `InboxStore.swift`, `WithdrawSheet.swift`.
- [ ] 7.5 UI: swipe actions on iPhone, context menu and toolbar on iPad and Mac, VoiceOver custom actions, receipt dismiss `[D9]`. Inbox menu: Snooze (⌃⌘S or S) and Archive (⌃⌘A or E). Test: `InboxCommandsTests.snoozeOpensPresets`. Touches `InboxView.swift`, `InboxCommands.swift`.
- [ ] 7.6 Demo close and receipt dismissal. Test: `DemoFactoryServiceTests.demoSnoozeHidesCard`. Docs and `validate`: `SandboxContractTests.closeModes`.

## 8. Claim and transfer (stack 8)

- [ ] 8.1 Add `claimAttention` and `transferAttention` with their defaults. Test: `InboxModelTests.claimAndTransferOnlyOnThreadRequests` `[D6]`. Touches `FactoryService.swift`, `InboxModels.swift`.
- [ ] 8.2 Live claim and transfer: `409 attention_already_closed` becomes `.alreadyClosed`; other `409`s stay conflicts; the `422` reason passes through. Tests: `PaperclipFactoryServiceTests.claimPath`, `transferBody`, `transferRefusedKeepsReason`. Touches `PaperclipFactoryService.swift`.
- [ ] 8.3 Store and UI: Claim in Unassigned; Transfer picker (a sheet on compact, a popover with search on regular) from `people`, hidden when people are unsupported `[D7]`; "Transferred by" on the owner label. Inbox menu: Claim (⌃⌘C) and Transfer (⌃⌘T). Tests: `InboxStoreTests.transferHiddenWithoutPeople`, `claimMovesCardAfterRefresh`. Touches `InboxStore.swift`, `TransferPicker.swift`, `InboxCommands.swift`.
- [ ] 8.4 Demo claim and transfer. Test: `DemoFactoryServiceTests.demoClaimMovesToMine`. Docs and `validate`: `SandboxContractTests.claimAndTransfer`, which uses the seeded second board user.

## 9. Decision history (stack 9)

- [ ] 9.1 Add `DecisionRecord` and `DecisionHistoryPage`, plus `attentionHistory` with its default. Test: `AttentionMappingTests.historyActionVerb` (`withdrawn`, `issue_closed`, `expired`). Touches `InboxModels.swift`, `FactoryService.swift`, `AttentionMapping.swift`.
- [ ] 9.2 Live history: `scope=mine` only when routed `[D19]`; paging. Tests: `PaperclipFactoryServiceTests.historyScopeOnlyWhenRouted` and `historyNextPage`. Touches `PaperclipFactoryService.swift`.
- [ ] 9.3 UI: a History screen on compact, history in the content column on regular; `HistoryRow`; History (⌘Y). Test: `InboxStoreTests.historyLoadsMoreAtEnd`. Touches `HistoryView.swift`, `InboxStore.swift`, `InboxCommands.swift`.
- [ ] 9.4 Demo history with every outcome. Test: `DemoFactoryServiceTests.demoHistoryHasEveryOutcome`. Docs and `validate`: `SandboxContractTests.history`.

## 10. Verify and archive (stack 10)

- [ ] 10.1 Run the full sandbox contract suite against the pinned Paperclip image and `latest`. Take iPhone, iPad and Mac screenshots of the demo inbox at default and accessibility sizes, with VoiceOver checks from design §11. No test (verification).
- [ ] 10.2 Record what the sandbox showed for the open items in `docs/paperclip-api.md`, and update the specs if any differ:
  - how `local_trusted` routes the inbox for `local-board`;
  - `answerMode: text` answers `[D17]`;
  - whether accepting a plan target needs a body;
  - whether interaction `409`s now carry a resolver.
    No test (docs).
- [ ] 10.3 Archive the OpenSpec change `add-inbox` as the last commit. No test.
