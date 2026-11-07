## ADDED Requirements

### Requirement: Custom request headers

A factory SHALL have zero or more custom request headers. The app SHALL send them with every request to that factory's origin, including browser sign-in, and SHALL treat their values as credentials: only over trusted transport, never across a redirect to another origin, and never to the OIDC issuer or its endpoints. The names SHALL be stored with the factory record and the values in the Keychain.

#### Scenario: Header sent to the factory

- **WHEN** the user connects with a custom header `X-Proxy-Token`
- **THEN** every request to the factory, including the validation request, carries that header

#### Scenario: Header kept from the identity provider

- **WHEN** the factory uses OIDC and has a custom header
- **THEN** discovery and token requests to the identity provider do not carry the header

#### Scenario: Plain HTTP to a remote server

- **WHEN** the user connects to `http://paperclip.example.com` with a custom header
- **THEN** connecting fails with an insecure-connection error before any request is sent

#### Scenario: Redirect to another origin

- **WHEN** the factory answers a request with a redirect to another origin
- **THEN** the app does not follow it, so the header never reaches that origin

#### Scenario: Saved and restored

- **WHEN** the app restarts after a factory with custom headers was saved
- **THEN** its service sends the same headers
- **AND** the header values are in the Keychain, not in the saved factory record

### Requirement: Custom header validation

The app SHALL trim header names and values and SHALL reject:
- an empty name
- a name that is not an HTTP token
- a name or value containing a line break
- duplicate names, compared without case
- the reserved names `Host`, `Content-Length`, `Transfer-Encoding` and `Connection`
- `Authorization` while a board key is used
- the OIDC token header while OIDC is on

#### Scenario: Reserved or clashing name

- **WHEN** the user adds a custom header named `Host`, or `Authorization` while using a board key
- **THEN** connecting fails with a message naming the header, before any request is sent

#### Scenario: Duplicate name

- **WHEN** the user adds `X-Token` and `x-token`
- **THEN** connecting fails with a duplicate-header message

## MODIFIED Requirements

### Requirement: Removing a factory

Removing a factory SHALL delete its record and every secret stored for it.

#### Scenario: Remove

- **WHEN** the user removes a saved factory
- **THEN** it disappears from the list, also after relaunch
- **AND** its board key, OIDC tokens and custom header values are deleted from the Keychain
