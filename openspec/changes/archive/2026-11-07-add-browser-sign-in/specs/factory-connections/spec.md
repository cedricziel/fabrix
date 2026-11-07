## ADDED Requirements

### Requirement: Sign in again

When a saved factory rejects its board key, the app SHALL stop refreshing and SHALL offer "Sign in again". Signing in again SHALL run browser sign-in for that factory and SHALL replace only its key, keeping its ID, name, custom headers and OIDC settings. When the server reports that the key expires within 5 days, the app SHALL offer the same action before the key stops working.

#### Scenario: Rejected key

- **WHEN** a saved factory answers a refresh with "unauthorized"
- **THEN** the app shows "Sign in again" instead of repeating the error, and stops refreshing until the user signs in

#### Scenario: Key replaced

- **WHEN** the user signs in again and approves in the browser
- **THEN** the factory keeps its ID and custom headers, its new key is stored, and refreshing resumes

#### Scenario: Key about to expire

- **WHEN** the factory's board key expires in fewer than 5 days
- **THEN** the app offers "Sign in again" with the expiry date

### Requirement: Sign-in request safety

The approval page SHALL be opened on the factory's own origin, under the same transport rule as credentials. Waiting SHALL end when the request's expiry time passes. The request token and the issued key SHALL NOT appear in error messages or logs.

#### Scenario: Server reports another host

- **WHEN** the server's approval URL names a different host than the factory address
- **THEN** the app opens the approval path on the factory address instead

#### Scenario: Plain HTTP to a public host

- **WHEN** the user starts browser sign-in for `http://paperclip.example.com`
- **THEN** it fails with an insecure-connection error before any request is sent

#### Scenario: Expiry passes while waiting

- **WHEN** the request's expiry time passes before approval
- **THEN** waiting ends with "the sign-in request expired"
