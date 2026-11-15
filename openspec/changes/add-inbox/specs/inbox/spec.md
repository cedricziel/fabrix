## Purpose

The inbox lists everything in a Paperclip company that waits for the user: approvals, the requests agents raise in task threads, and problems. It lets the user answer, route or put aside each one on iPhone, iPad and Mac.

## ADDED Requirements

### Requirement: Inbox views

The app SHALL show the selected company's attention cards in three views: For you, Unassigned and Company. Each view SHALL show the server's count for it, and a count of 0 SHALL be hidden. For you SHALL be the default view. Stale cards SHALL be grouped under Stale with their reason ("Task closed", "Waiting 30+ days", "Deadline close", "No owner for 7+ days"). A card that is evidence for another card SHALL be shown only inside the card it belongs to. Cards SHALL keep the server's order.

#### Scenario: Opening the inbox

- **WHEN** the user opens the inbox on a factory that supports it
- **THEN** For you is selected, and its cards are listed with each one's kind, requester, task identifier, age, title, one-line summary and owner

#### Scenario: Switching view

- **WHEN** the user picks Unassigned
- **THEN** the cards nobody owns are listed, and the counts on all three views stay as the server sent them

#### Scenario: Stale card

- **WHEN** a card is stale because its task is closed
- **THEN** it is listed under Stale with "Task closed" and can still be answered

#### Scenario: Evidence folded into its lead

- **WHEN** a pending approval and its task's review card share an obligation
- **THEN** one card is listed, with the other shown inside it as evidence

#### Scenario: View switch at accessibility sizes

- **WHEN** the text size is an accessibility size
- **THEN** the view switch is a menu button that shows the selected view and the counts

### Requirement: Critical and problem cards

A card the server marks critical SHALL show a "Critical" tag with an icon. A card that reports a problem (failed run, budget stop, blocked task, recovery) SHALL show a "Problem" tag. Neither SHALL rely on color alone. `[D12]`

#### Scenario: Critical budget stop

- **WHEN** a budget-stop card has critical severity
- **THEN** its row shows both "Problem" and "Critical" as text

### Requirement: Receipts

For you SHALL show the receipts the server sends ("Priya approved Raise the cap for you") above the cards, with the outcome, the person and the reason when there is one. A receipt SHALL never count in a badge or view count. The user SHALL be able to dismiss a receipt. `[D9]`

#### Scenario: Receipt shown

- **WHEN** someone else approved a card that was for the user
- **THEN** For you shows a receipt naming that person and the approval

#### Scenario: Dismissing a receipt

- **WHEN** the user dismisses a receipt
- **THEN** it disappears and doesn't come back on the next refresh

### Requirement: Card detail per width

Selecting a card SHALL show it with its full content and the actions it allows, and with its task context: identifier, title, status, assignee and project, when the card belongs to a task. "Open task" SHALL open the task in Paperclip. `[D21]`

#### Scenario: Compact width

- **WHEN** the user taps a card on iPhone
- **THEN** the card opens in its own screen with the decision buttons pinned at the bottom, and Back returns to the list

#### Scenario: Regular width

- **WHEN** the user selects a card on iPad or Mac
- **THEN** the list stays visible, and the card with its task context fills the detail area

#### Scenario: Decision buttons at accessibility sizes

- **WHEN** the text size is an accessibility size
- **THEN** the decision buttons appear after the card's content instead of pinned at the bottom

### Requirement: Answering approvals

An approval card SHALL offer Approve and Reject. It SHALL show the approval's full payload as labelled rows, with the raw JSON behind a disclosure, and the approval's comments. The user SHALL be able to post a comment, which is sent at once and shows sending and failed states. `[D20]`

#### Scenario: Approving from the inbox

- **WHEN** the user approves an approval card
- **THEN** the decision is staged with its undo window, and the card leaves the list once it is sent

#### Scenario: Payload and comments

- **WHEN** the user opens a hire approval with two comments
- **THEN** the card shows the hire's fields as rows, and both comments with author and age

#### Scenario: Posting a comment fails

- **WHEN** the user posts a comment and the factory can't be reached
- **THEN** the comment stays in the thread marked "Not sent" with a Retry button

### Requirement: Request revision

An approval card SHALL offer Request revision. It SHALL require a note for the requesting agent and SHALL be staged like a decision. `[D3]`

#### Scenario: Revision requested

- **WHEN** the user requests a revision with a note and the undo window ends
- **THEN** the factory receives the request with the note, and the card leaves For you

#### Scenario: Revision without a note

- **WHEN** the user chooses Request revision and leaves the note empty
- **THEN** the send button stays disabled and the field says a note is required

### Requirement: Answering confirmations

A confirmation card (confirm, plan review, deliverable review) SHALL offer accept and reject with the request's own labels. Reject SHALL take an optional reason, and SHALL require one when the request says so. A plan review SHALL show the plan's title and summary.

#### Scenario: Accepting a plan

- **WHEN** the user accepts a plan review and the undo window ends
- **THEN** the factory records the acceptance, and the card leaves the list

#### Scenario: Reject requires a reason

- **WHEN** a confirmation requires a reason to reject and the user chooses Reject
- **THEN** the reason field is shown as required, and Reject stays disabled until it has text

### Requirement: Answering questions

A questions card SHALL show each question with its options: single choice as radio buttons, multiple choice as checkboxes, a "Recommended" mark where the request has one, and a free-text "Other" field where the question allows it. Submit SHALL stay disabled until every required question is answered. A card with a text-only question SHALL open in Paperclip instead. `[D17]`

#### Scenario: Single and multiple choice

- **WHEN** the user picks one option in a single-choice question and two in a multiple-choice question and submits
- **THEN** after the undo window the factory receives both answers with the chosen options

#### Scenario: Other answer

- **WHEN** the user picks Other and types an answer
- **THEN** the typed text is sent as that question's answer

### Requirement: Item verdicts

An item-review card SHALL list each item with Approve, Reject and Defer (or the subset the request allows). It SHALL require a reason on the verdicts the request names. It SHALL offer "Approve all" only when the request allows bulk approval. Submit SHALL stay disabled until every item has a verdict.

#### Scenario: Verdict needing a reason

- **WHEN** reject requires a reason and the user rejects an item without one
- **THEN** that item's reason field is marked required, and Submit stays disabled

#### Scenario: Approve all

- **WHEN** the request allows bulk approval and the user chooses Approve all
- **THEN** every item is set to Approve, and the user can still change any of them before submitting

### Requirement: Cards answered in Paperclip

Cards Fabrix can't answer in place SHALL be listed and counted like the others, and SHALL offer "Open in Paperclip". That covers suggested tasks, choices between options, join requests, tool access, connecting a service, task reviews, failed runs, budget stops, blocked tasks, recovery, checkbox confirmations, text-only questions and any type this version doesn't know. "Open in Paperclip" SHALL open only a page on the factory's own origin. `[D1]` `[D2]`

#### Scenario: Join request

- **WHEN** the user opens a join-request card
- **THEN** it shows its title and summary and an "Open in Paperclip" button that opens the request in the factory's web UI

#### Scenario: Link to another origin

- **WHEN** a card's link would leave the factory's origin
- **THEN** no "Open in Paperclip" button is shown

#### Scenario: Card type from a newer server

- **WHEN** the server sends a card type this version doesn't know
- **THEN** the card is listed with "Open in Paperclip" and the inbox still loads

### Requirement: Staged inbox actions

Approve, reject, request revision, accept, decline, submit answers, submit verdicts, snooze and archive SHALL wait for the 8-second undo window before reaching the factory. While an action waits, an undo bar SHALL show the action, the card and the time left as text, with Undo and Send now, and Edit ▸ Undo SHALL undo it. All waiting actions SHALL be sent when the app leaves the foreground and when the user switches company or factory. An action the factory refuses because the sign-in expired SHALL stay staged until the user signs in again. An action whose send fails for any other reason, such as the device going offline, SHALL not be retried or queued. Its card SHALL return to the list with "Your decision wasn't sent:" and the reason, so the user can act again, as on today's Approvals screen. An action held because the sign-in expired SHALL survive a company switch and SHALL be sent once the user signs in again. Leaving the factory with Disconnect SHALL drop what is still staged, as it does for approvals today. `[D5]` `[D22]`

#### Scenario: Undo inside the window

- **WHEN** the user rejects a card and taps Undo within 8 seconds
- **THEN** the card returns to the list unchanged and nothing is sent

#### Scenario: Send now

- **WHEN** the user taps Send now in the undo bar
- **THEN** the action is sent at once and Undo is no longer offered

#### Scenario: Leaving the foreground

- **WHEN** the app goes to the background with two actions still in their window
- **THEN** both are sent right away

#### Scenario: Company switch

- **WHEN** the user switches company while an action is in its window
- **THEN** the action is sent to the factory right away, before the other company loads `[D22]`

#### Scenario: Held action across a company switch

- **WHEN** an action is held because the sign-in expired and the user switches company
- **THEN** the action is still held, and once the user signs in again it is sent for the company it was made in

#### Scenario: Send fails offline

- **WHEN** the undo window ends while the device is offline
- **THEN** nothing is retried, and the card returns to the list with "Your decision wasn't sent: You're offline." and its actions enabled once the factory is back

#### Scenario: Undo from the Edit menu

- **WHEN** the user approves a card and chooses Edit ▸ Undo within 8 seconds
- **THEN** the card returns to the list unchanged and nothing is sent

### Requirement: Withdraw

Withdraw SHALL be offered only on cards whose server allows it. It SHALL require a reason, then a destructive confirmation that says the request closes for everyone, then authentication when "Confirm approvals" is on. It SHALL be sent at once. `[D4]`

#### Scenario: Withdrawing an out-of-date request

- **WHEN** the user withdraws a request with a reason and confirms
- **THEN** the factory closes it for everyone with that reason, and the card leaves the list

#### Scenario: Cancelling the confirmation

- **WHEN** the user cancels the destructive confirmation
- **THEN** nothing is sent and the card stays

### Requirement: Snooze and archive

Snooze SHALL hide a card for the user until a chosen time: in 1 hour, tomorrow at 9:00, next Monday at 9:00, or a picked time. Archive SHALL hide it until it changes. Both SHALL affect only the user, and SHALL be offered only where the server allows them. `[D5]` `[D10]`

#### Scenario: Swipe on compact width

- **WHEN** the user swipes a row on iPhone
- **THEN** a trailing swipe offers Snooze with its presets, and a leading swipe offers Archive

#### Scenario: Context menu on regular width

- **WHEN** the user opens a row's context menu on iPad or Mac
- **THEN** it offers Snooze with its presets and Archive, and the same actions are in the card's toolbar

#### Scenario: Snoozed card returns

- **WHEN** a snoozed card's time passes
- **THEN** it is listed again after the next refresh

### Requirement: Claim and transfer

On a task-thread request in the Unassigned view, the app SHALL offer Claim, which makes the user its owner. On any task-thread request the user may route, the app SHALL offer Transfer to one of the company's people, with an optional reason. Neither SHALL be offered on approvals or on servers without routing. Transfer SHALL be hidden when the factory doesn't list its people. `[D6]` `[D7]`

#### Scenario: Claiming

- **WHEN** the user claims an Unassigned card
- **THEN** after the refresh the card is in For you and no longer in Unassigned

#### Scenario: Transfer on compact width

- **WHEN** the user chooses Transfer on iPhone
- **THEN** a sheet lists the company's people by name, and the user confirms with "Transfer to Priya"

#### Scenario: Transfer on regular width

- **WHEN** the user chooses Transfer on iPad or Mac
- **THEN** a popover lists the company's people with a search field, and the user confirms with "Transfer to Priya"

#### Scenario: Recipient refused

- **WHEN** the factory refuses the chosen person
- **THEN** the picker shows the server's reason and the card stays with its owner

### Requirement: Already decided

When someone else answered or closed a card first, the app SHALL say who decided and when, say that the user's action wasn't recorded, refresh the inbox, and never retry the action. `[D16]`

#### Scenario: Approval decided by someone else

- **WHEN** the user's rejection reaches the factory after Priya approved the same approval
- **THEN** the card shows "Priya approved this at 14:29. Your rejection wasn't recorded." and the inbox refreshes

#### Scenario: Decided by an agent

- **WHEN** an agent resolved the request first
- **THEN** the notice names the agent

#### Scenario: Decider unknown

- **WHEN** the factory doesn't say who decided
- **THEN** the notice says "Someone already answered this"

#### Scenario: Already decided on compact width

- **WHEN** the user's action on iPhone finds the card already decided
- **THEN** the open card keeps the notice until the user goes back, and the list they return to no longer has the card

#### Scenario: Already decided on regular width

- **WHEN** the user's action on iPad or Mac finds the card already decided
- **THEN** the list refreshes without the card, and the detail area keeps the notice until the user selects another card

#### Scenario: Own answer after a lost response

- **WHEN** an answer is sent again after its response was lost, and the factory shows the user resolved the request with that same answer
- **THEN** the action counts as sent, and no "already decided" notice is shown

#### Scenario: Own different answer

- **WHEN** the user answered a question with one option in another session, and Fabrix later submits a different option
- **THEN** the notice says the user already answered at that time and this answer wasn't recorded

### Requirement: Offline

While the factory can't be reached, the decide buttons SHALL be disabled with the reason shown. Nothing new SHALL be queued, and actions already staged SHALL keep their behavior. The last loaded cards SHALL stay visible and be marked as not current. `[D13]`

#### Scenario: Deciding offline

- **WHEN** the device is offline and the user opens a card
- **THEN** the decision bar says "You're offline. Decisions are off until the factory is back." and its buttons are disabled

### Requirement: Load states

The inbox SHALL show placeholder rows on first load, a "Nothing waiting for you" state when For you is empty, and an error with Try again when the first load fails. Placeholder rows SHALL not animate when Reduce Motion is on.

#### Scenario: Empty For you

- **WHEN** For you has no cards and no receipts
- **THEN** the inbox says "Nothing waiting for you" and shows the counts of the other views

#### Scenario: First load fails

- **WHEN** the first feed request fails
- **THEN** the inbox shows the error with Try again, and the rest of the company stays usable

### Requirement: Server without the inbox

A factory without the attention feed SHALL keep today's Approvals section, tab and badge, with no Inbox. A factory with the feed but without routing SHALL show one list without the view switch, answer cards in place, and hide snooze, archive, withdraw, claim and transfer. The app SHALL remember per factory whether the feed was found, and SHALL lay out from that answer at launch. Until a factory's feed has loaded once, Approvals SHALL stay. Only a loaded feed, or a response that says the factory has no inbox for this user (a missing endpoint, or no board user to route to), SHALL change the answer. Other failures SHALL not. `[D19]` `[D24]`

#### Scenario: Older server

- **WHEN** the feed request answers `404` with "API route not found", or a `404` without a JSON error body
- **THEN** the app shows Approvals as before and never shows an Inbox for that factory session

#### Scenario: Remembered inbox no longer available

- **WHEN** a factory remembered as having the inbox answers the feed request with `403` "Board user context required" or a missing endpoint
- **THEN** the Inbox gives way to Approvals at once, and the factory is remembered as having no inbox

#### Scenario: First load fails on a new factory

- **WHEN** the feed request of a factory that has never loaded its feed fails with a network error
- **THEN** Approvals stays, with its tab and badge, and the inbox is tried again on the next refresh

#### Scenario: Launch with a known inbox

- **WHEN** the app launches on a factory whose feed loaded before
- **THEN** the tabs and sidebar show Inbox from the start, with a loading state, and don't change when the feed arrives

#### Scenario: Feed without routing

- **WHEN** the feed has no view counts
- **THEN** the inbox shows all cards in one list, and no card offers snooze, archive, withdraw, claim or transfer

### Requirement: Inbox badges

The Inbox tab (compact) and sidebar row (regular) SHALL show the server's count of cards for the user (`deskBadgeCount`), hidden at 0 and shown as "99+" above 99. On macOS the Dock icon SHALL show the same count. On iOS and iPadOS the app icon SHALL show it when the user turned on "Show count on app icon", which asks for badge permission. The icon badge SHALL be cleared on sign-out, on removing the factory, and on a factory without the inbox. `[D8]` `[D18]`

#### Scenario: Badge on compact width

- **WHEN** three cards are for the user
- **THEN** the Inbox tab shows 3

#### Scenario: Badge on regular width

- **WHEN** three cards are for the user
- **THEN** the Inbox sidebar row shows 3

#### Scenario: Dock badge on Mac

- **WHEN** three cards are for the user on macOS
- **THEN** the Dock icon shows 3

#### Scenario: App icon badge switched off

- **WHEN** "Show count on app icon" is off on iPhone
- **THEN** the app icon shows no count and the tab still shows it

### Requirement: Decision history

The app SHALL show decision history: what the user handled or what was handled for them, newest first. Each row SHALL start with the outcome verb and show the title, the detail (reason, chosen option or verdict counts), the person or agent who acted, and the time. More rows SHALL load at the end of the list.

#### Scenario: History on compact width

- **WHEN** the user opens History from the inbox on iPhone
- **THEN** a screen lists the user's decisions with their outcome verb first

#### Scenario: History on regular width

- **WHEN** the user opens History on iPad or Mac
- **THEN** history replaces the card list in the content column, and selecting a row shows its detail

### Requirement: Inbox keyboard shortcuts

On macOS, and on iPadOS with a hardware keyboard, an Inbox menu SHALL offer the inbox commands with shortcuts:

- Next (↓ or J) and Previous (↑ or K);
- Approve or accept (⌘↩), Reject (⌥⌘⌫) and Request revision (⌥⌘↩);
- Snooze (⌥⌘S or S) and Archive (⌃⌘A or E);
- Switch view (⌘⌥1–3), Claim (⌃⌘C), Transfer (⌃⌘T) and History (⌘Y);
- Open task (⌘O) and Copy link (⇧⌘C).

Undo SHALL use the Edit menu's Undo (⌘Z), and Refresh SHALL stay the existing Factory Refresh (⌘R). No inbox shortcut SHALL reuse a key the app or macOS already binds. Single-key shortcuts SHALL work only while the card list has focus. The decide commands SHALL be disabled while a text field has focus. A command SHALL be disabled when the selected card doesn't allow its action. `[D14]`

#### Scenario: Moving through cards

- **WHEN** the card list has focus and the user presses J twice
- **THEN** the selection moves down two cards and the detail follows

#### Scenario: Approving by keyboard

- **WHEN** an approval card is selected and the user presses ⌘↩
- **THEN** the approval is staged with its undo window, exactly as if the button was clicked

#### Scenario: Snoozing by keyboard

- **WHEN** a card is selected and the user presses ⌥⌘S
- **THEN** the snooze presets open for that card

#### Scenario: Typing a reason

- **WHEN** the user is typing in a reason or comment field and presses ⌘↩ or ⌥⌘⌫
- **THEN** no decision is made, and the keys act on the text field only

#### Scenario: Shortcuts on iPad

- **WHEN** an iPad with a hardware keyboard shows the inbox and the user holds ⌘
- **THEN** the shortcut overlay lists the Inbox commands

#### Scenario: Command not allowed

- **WHEN** the selected card is a join request
- **THEN** Approve or accept and Reject are disabled in the Inbox menu

### Requirement: Inbox accessibility

Every inbox row SHALL be one VoiceOver element that reads kind, title, requester, age and owner, with its swipe and menu actions as custom actions. The undo bar SHALL announce the action and the time left. It SHALL announce "Sent" only after the factory accepted the action. When the action is held for sign-in it SHALL announce that, and when the send failed it SHALL announce the reason. The "already decided" notice SHALL be announced when it appears. Decided rows SHALL fade instead of sliding when Reduce Motion is on. Every swipe action SHALL also be in the context menu.

#### Scenario: VoiceOver row

- **WHEN** VoiceOver focuses a hire approval row
- **THEN** it reads "Approval. Hire a Designer agent. From CEO, 12 minutes ago. For you." and offers Snooze and Archive as actions

#### Scenario: Undo announcement

- **WHEN** the user approves with VoiceOver on
- **THEN** VoiceOver announces "Approved. Sending in 8 seconds." and, once the factory accepts it, "Sent."

#### Scenario: Held announcement

- **WHEN** the window ends with VoiceOver on and the factory refuses the action because the sign-in expired
- **THEN** VoiceOver announces "Not sent yet. It goes out when you sign in again." and never "Sent"
