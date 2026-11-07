## MODIFIED Requirements

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

- **WHEN** the user chooses Switch factory or Choose another factory
- **THEN** onboarding is shown again, neither the demo nor the factory reopens on the next launch, and the factory's saved credentials are kept
