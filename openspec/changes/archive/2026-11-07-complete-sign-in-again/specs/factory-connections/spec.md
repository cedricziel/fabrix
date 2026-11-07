## MODIFIED Requirements

### Requirement: Sign in again

When a saved factory rejects its board key, or the identity provider in front of it needs a new login, the app SHALL stop refreshing and SHALL offer "Sign in again". For a factory with a board key, signing in again SHALL log in to its identity provider again (when it has one), run browser sign-in, and replace only its key. For an OIDC-only factory it SHALL log in to the identity provider again. Either way the factory SHALL keep its ID, name, custom headers and OIDC settings. When the server reports that the key expires within 5 days, the app SHALL offer the same action before the key stops working.

#### Scenario: Rejected key

- **WHEN** a saved factory answers a refresh with "unauthorized"
- **THEN** the app shows "Sign in again" instead of repeating the error, and stops refreshing until the user signs in

#### Scenario: Key replaced

- **WHEN** the user signs in again and approves in the browser
- **THEN** the factory keeps its ID and custom headers, its new key is stored, and refreshing resumes

#### Scenario: Key about to expire

- **WHEN** the factory's board key expires in fewer than 5 days
- **THEN** the app offers "Sign in again" with the expiry date

#### Scenario: Proxy session ended

- **WHEN** the identity provider in front of a saved factory rejects its refresh token
- **THEN** the app shows "Sign in again", and signing in again logs in to the identity provider without asking for a new Paperclip key if the factory has none

#### Scenario: Reconnect keeps single sign-on

- **WHEN** the connect form opens to re-enter lost header values for a factory that uses single sign-on
- **THEN** it shows that factory's sign-in method, issuer and client ID
