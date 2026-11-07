## Purpose

What the user sees before a factory is connected, and how a factory gets connected.

## ADDED Requirements

### Requirement: First launch

The app SHALL show onboarding until the user connects a factory or explores the demo.

#### Scenario: First launch

- **WHEN** the app starts with no remembered factory
- **THEN** it shows "Connect a factory" and "Explore the demo"

#### Scenario: Demo remembered

- **WHEN** the user explored the demo and relaunches the app
- **THEN** the demo factory opens without onboarding

#### Scenario: Leaving a factory

- **WHEN** the user chooses Switch factory or Choose another factory
- **THEN** onboarding is shown again and the demo is no longer remembered

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
