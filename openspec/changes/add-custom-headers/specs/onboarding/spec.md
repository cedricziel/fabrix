## ADDED Requirements

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
