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

- **WHEN** the user chooses "Choose another factory" on the empty or unreachable screen
- **THEN** onboarding is shown again, neither the demo nor the factory reopens on the next launch, and the factory's saved credentials are kept

## ADDED Requirements

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
