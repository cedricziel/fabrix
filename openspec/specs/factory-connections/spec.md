# factory-connections Specification

## Purpose
Lets the user connect Fabrix to Paperclip servers ("factories"), keeps those connections across launches, and provides a live factory service for each one.
## Requirements
### Requirement: Validate before saving

The app SHALL save a factory only after an authenticated call to its server succeeds with the chosen auth configuration.

#### Scenario: Valid board key

- **WHEN** the user connects to `https://paperclip.example.com` with a board API key the server accepts
- **THEN** the factory is saved with that address
- **AND** the key is stored in the Keychain, not in preferences

#### Scenario: Rejected credential

- **WHEN** the server answers `401` to the validation call
- **THEN** connecting fails with an unauthorized error carrying the server's message
- **AND** no factory and no secret is saved

#### Scenario: Storing a secret fails

- **WHEN** the board key is stored but storing the OIDC tokens fails
- **THEN** connecting fails with the storage error
- **AND** the previously saved key and configuration are unchanged

### Requirement: Server address input

The app SHALL accept a server address with or without a scheme and with or without a trailing `/api`, and SHALL reject anything that is not an http or https URL with a host.

#### Scenario: Bare host

- **WHEN** the user enters `paperclip.example.com`
- **THEN** the factory is saved as `https://paperclip.example.com`

#### Scenario: Address with the API suffix

- **WHEN** the user enters `http://localhost:3100/api/`
- **THEN** the factory is saved as `http://localhost:3100`

#### Scenario: Unusable address

- **WHEN** the user enters `file:///etc/passwd`
- **THEN** connecting fails with an invalid-server-address error before any network call

### Requirement: Credentials only over trusted transport

The app SHALL send a board key or OIDC token, SHALL run browser sign-in (including polling the sign-in request), and SHALL talk to an OIDC issuer and the authorization and token endpoints it lists, only over HTTPS or over plain HTTP to this machine or a private network. Private networks are loopback, `.local` and `.localhost` names, literal RFC 1918 IPv4 addresses (exactly four numeric parts, so `192.168.1.1.example.com` is not one), `100.64.0.0/10` (Tailscale), link-local, and IPv6 unique-local addresses.

#### Scenario: Board key to a remote server over HTTP

- **WHEN** the user connects to `http://paperclip.example.com` with a board key
- **THEN** connecting fails with an insecure-connection error before any request is sent

#### Scenario: Redirect to another address

- **WHEN** the server or the identity provider answers a credential-bearing request with a redirect to a different scheme, host or port
- **THEN** the app does not follow it, so no credential or sign-in token reaches that address
- **AND** the error names only the new origin (scheme, host and port), never the full address, which can carry a token

#### Scenario: OIDC issuer on a remote server over HTTP

- **WHEN** the user connects with an OIDC issuer like `http://idp.example.com`
- **THEN** connecting fails with an insecure-connection error before the provider is contacted or its login page is shown

#### Scenario: OIDC issuer lists a plain-HTTP endpoint

- **WHEN** an HTTPS issuer's discovery document lists an authorization or token endpoint like `http://idp.example.com/authorize`
- **THEN** connecting fails with an insecure-connection error before the provider's login page is shown

#### Scenario: OIDC sign-in in front of an insecure server

- **WHEN** the user connects to `http://paperclip.example.com` with OIDC
- **THEN** connecting fails with an insecure-connection error before the provider's login page is shown

#### Scenario: Board key to a server on the local network

- **WHEN** the user connects to `http://192.168.1.20:3100` with a board key
- **THEN** the key is sent and the factory is saved once the server accepts it

### Requirement: Saved factories persist

The app SHALL keep saved factories, their display names and their auth configuration across relaunches.

#### Scenario: Relaunch

- **WHEN** the app restarts after a factory was saved
- **THEN** the factory list contains the same factory with the same ID, name and address

#### Scenario: Default display name

- **WHEN** the user connects without entering a name
- **THEN** the factory is named after the server's host

### Requirement: Reconnecting updates in place

Connecting to an address that is already saved SHALL update that factory instead of adding a second one.

#### Scenario: New key for a saved server

- **WHEN** the user connects again to a saved server with a new key and a new name
- **THEN** the factory keeps its ID
- **AND** its name and stored key are replaced

### Requirement: Removing a factory

Removing a factory SHALL delete its record and every secret stored for it.

#### Scenario: Remove

- **WHEN** the user removes a saved factory
- **THEN** it disappears from the list, also after relaunch
- **AND** its board key, OIDC tokens and custom header values are deleted from the Keychain

### Requirement: Live service per factory

The app SHALL provide a factory service for each saved factory that authenticates with that factory's stored configuration.

#### Scenario: Stored key is used

- **WHEN** the app asks for a saved factory's service and lists companies
- **THEN** the request carries that factory's stored board key

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

