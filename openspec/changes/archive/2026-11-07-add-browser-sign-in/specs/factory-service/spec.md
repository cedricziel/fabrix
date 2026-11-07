## ADDED Requirements

### Requirement: Board key expiry

The live factory SHALL report when the board key it uses expires, from the key's record on the server. It SHALL report no expiry when the server doesn't say, or when the factory uses no board key.

#### Scenario: Key with an expiry

- **WHEN** the factory's board key expires on a known date
- **THEN** the service reports that date

#### Scenario: Unknown expiry

- **WHEN** the key list is unavailable or the key has no expiry
- **THEN** the service reports no expiry and the app relies on the server rejecting the key
