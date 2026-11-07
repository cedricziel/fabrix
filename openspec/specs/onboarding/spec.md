# onboarding Specification

## Purpose
What the user sees before a factory is connected, and how a factory gets connected.
## Requirements
### Requirement: First launch

The app SHALL show onboarding until the user connects a factory or explores the demo.

#### Scenario: First launch

- **WHEN** the app starts with no remembered factory
- **THEN** it shows "Connect a factory" and "Explore the demo"

#### Scenario: Demo remembered

- **WHEN** the user explored the demo and relaunches the app
- **THEN** the demo factory opens without onboarding

#### Scenario: Connected factory remembered

- **WHEN** the user connected a factory and relaunches the app
- **THEN** that factory opens without onboarding, using its saved credentials

#### Scenario: Saved factory is gone

- **WHEN** the remembered factory is no longer saved on the device
- **THEN** onboarding is shown

#### Scenario: Leaving a factory

- **WHEN** the user chooses "Choose another factory" on the empty or unreachable screen
- **THEN** onboarding is shown again, neither the demo nor the factory reopens on the next launch, and the factory's saved credentials are kept

### Requirement: Connecting a factory

The app SHALL let the user connect a factory by address with a sign-in method per factory: a Paperclip API key, OIDC (issuer URL and client ID), or OIDC in front of a Paperclip API key.

#### Scenario: Valid form

- **WHEN** the address and the fields the chosen method needs are filled in and the user connects
- **THEN** the app asks the connector to connect, with `https://` added to an address without a scheme, and shows the factory on success

#### Scenario: Missing field

- **WHEN** the address is unusable or a field the method needs is empty
- **THEN** the app explains which field is missing and does not contact the factory

#### Scenario: Connection fails

- **WHEN** the connector reports an error
- **THEN** onboarding stays visible with the error message

#### Scenario: No connector available

- **WHEN** the app has no way to connect to servers yet
- **THEN** the Connect button is disabled and a note points to the demo

### Requirement: Custom headers in the connect form

The connect form SHALL offer custom request headers in a collapsed "Advanced" section. Each header has a name and a value, and the value is entered like a password. The section SHALL explain that the headers are sent with every request to this factory, for example a proxy access token.

#### Scenario: Adding a header

- **WHEN** the user opens Advanced, adds a header with a name and a value, and connects
- **THEN** the connector receives that header with the address and sign-in method

#### Scenario: Blank rows are ignored

- **WHEN** a header row has neither a name nor a value
- **THEN** it is not sent to the connector

#### Scenario: Section stays out of the way

- **WHEN** the form has no headers
- **THEN** the Advanced section is collapsed

### Requirement: Adding and removing factories

The app SHALL let the user add a factory and remove the open one without leaving the current factory first.

#### Scenario: Adding a factory

- **WHEN** the user chooses "Add Factory…" and connects
- **THEN** the new factory opens and is remembered, and the previous one stays saved

#### Scenario: Removing a factory

- **WHEN** the user chooses "Remove Factory…" and confirms
- **THEN** the factory and its credentials are deleted from the device, and the next saved factory opens, or onboarding when none is left

#### Scenario: The demo

- **WHEN** the demo is open
- **THEN** "Remove Factory…" is not offered, and the demo stays reachable from the title menu

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

