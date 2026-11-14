## MODIFIED Requirements

### Requirement: Company actions

The app SHALL offer Pause company (or Resume company when paused) and New task from the toolbar. New task SHALL open the create form described in the `task-editing` capability.

#### Scenario: Pausing a company

- **WHEN** the user chooses Pause company
- **THEN** the factory is asked to pause the company and the overview shows it as paused

#### Scenario: New task

- **WHEN** the user chooses New task or presses Command-N
- **THEN** the create form opens for the selected company

#### Scenario: New task before the service supports it

- **WHEN** the factory doesn't support creating tasks and the user chooses New task
- **THEN** a sheet explains that this factory doesn't allow creating tasks from Fabrix and offers no way to submit
