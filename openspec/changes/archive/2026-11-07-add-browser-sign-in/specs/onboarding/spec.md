## ADDED Requirements

### Requirement: Browser sign-in

The connect form SHALL offer "Sign in with browser" as its default method. Connecting with it SHALL create a sign-in request on the factory, open its approval page in the user's default browser, and wait for approval. While waiting, the form SHALL show "Approve Fabrix in your browser", a Copy link button and Cancel. The same flow SHALL be available behind single sign-on, where the proxy login runs first. Custom headers SHALL apply to the sign-in requests.

#### Scenario: Default method

- **WHEN** the connect form opens
- **THEN** "Sign in with browser" is selected

#### Scenario: Approved

- **WHEN** the user connects with browser sign-in and approves Fabrix in the browser
- **THEN** the app opens the approval page, waits, and shows the factory once Paperclip issues the key

#### Scenario: Cancelled by the user

- **WHEN** the user taps Cancel while waiting
- **THEN** the app stops checking for approval and returns to the form without an error

#### Scenario: Request expired or declined

- **WHEN** the request expires or is cancelled in the browser
- **THEN** the app shows a message that says so, with Try again

#### Scenario: App in the background

- **WHEN** the user switches to the browser and comes back before the request expires
- **THEN** the app continues waiting and connects once approved
