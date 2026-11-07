## Purpose

Defines how Fabrix proves who it is to a Paperclip factory and to any OIDC-protected reverse proxy in front of it, including how tokens are refreshed.

## ADDED Requirements

### Requirement: No authentication

The app SHALL connect to a Paperclip server in `local_trusted` mode without any credential.

#### Scenario: Local trusted server

- **WHEN** the user connects without a credential to a server that treats every request as the local board
- **THEN** the factory is saved and requests carry no `Authorization` header

### Requirement: Board API key

The app SHALL authenticate to Paperclip with a board API key sent as `Authorization: Bearer <key>`. Surrounding whitespace in a pasted key SHALL be ignored.

#### Scenario: Pasted key with a trailing newline

- **WHEN** the user pastes `pcp_board_abc` followed by a newline
- **THEN** requests carry `Authorization: Bearer pcp_board_abc`

### Requirement: Browser sign-in

The app SHALL let the user get a board API key by approving a sign-in request in a browser where they are signed in to Paperclip, without copying any key.

#### Scenario: Approved in the browser

- **WHEN** the user starts browser sign-in, opens the approval page and approves it
- **THEN** the app detects the approval by polling and saves the factory with the issued key

#### Scenario: Cancelled or expired

- **WHEN** the sign-in request is cancelled or expires before approval
- **THEN** sign-in fails with a cancelled or expired error and nothing is saved

### Requirement: OIDC sign-in

The app SHALL sign in to an OIDC provider with Authorization Code and PKCE (S256). It SHALL find the endpoints through the issuer's `/.well-known/openid-configuration` and show the provider's login page in the system web authentication session.

#### Scenario: Successful login

- **WHEN** the user connects with OIDC settings (issuer, client ID, redirect URI, scopes) and completes the provider's login
- **THEN** the app exchanges the code for tokens with the PKCE verifier
- **AND** stores the tokens in the Keychain
- **AND** saves the factory after the server accepts a request carrying the access token

#### Scenario: Forged callback

- **WHEN** the callback's `state` does not match the request
- **THEN** sign-in fails and no token is requested

#### Scenario: Provider reports an error

- **WHEN** the callback carries an `error` parameter instead of a code
- **THEN** sign-in fails with that error and nothing is saved

### Requirement: Token refresh with rotation

The app SHALL refresh an OIDC access token that is expired or about to expire before sending a request, and SHALL retry a request once after refreshing when the server answers `401`. When the provider returns a new refresh token, the app SHALL store it in place of the old one.

#### Scenario: Expired access token

- **WHEN** a request is about to be sent with an access token that expires within a minute
- **THEN** the app refreshes first and sends the request with the new token
- **AND** stores the rotated refresh token

#### Scenario: Concurrent requests share one refresh

- **WHEN** several requests need a refresh at the same time
- **THEN** the app calls the token endpoint once

#### Scenario: Paperclip rejects the board key behind a front door

- **WHEN** Paperclip answers `401` with its own JSON error while the OIDC token is valid
- **THEN** the app does not refresh the OIDC token and the request fails as unauthorized

#### Scenario: Rotated tokens survive a failed Keychain write

- **WHEN** a refresh succeeds but storing the new tokens fails
- **THEN** the request fails with the storage error
- **AND** the next request uses the new tokens without another refresh

#### Scenario: Refresh rejected

- **WHEN** the provider rejects the refresh token
- **THEN** the request fails with an unauthorized error so the user can sign in again

### Requirement: Front-door proxy chaining

The app SHALL combine an OIDC token for a reverse proxy with Paperclip authentication on the same request. The OIDC token SHALL go in the `Authorization` header by default, or in a header the user names. A configuration where both layers need the `Authorization` header SHALL be rejected before connecting.

#### Scenario: Proxy header plus board key

- **WHEN** a factory uses OIDC in the header `X-Forwarded-Access-Token` and a board key for Paperclip
- **THEN** each request carries the OIDC access token in `X-Forwarded-Access-Token` and `Authorization: Bearer <board key>`

#### Scenario: Browser sign-in behind a front door

- **WHEN** the user starts browser sign-in with OIDC settings for the proxy and approves it in the browser
- **THEN** the sign-in requests carry the OIDC token
- **AND** the factory is saved with both the OIDC configuration and the issued board key, without a second OIDC login

#### Scenario: Conflicting headers

- **WHEN** the user configures OIDC in the `Authorization` header together with a board key
- **THEN** connecting fails with an invalid-configuration error before any network call
