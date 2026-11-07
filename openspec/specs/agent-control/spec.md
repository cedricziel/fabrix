# agent-control Specification

## Purpose
Checking on one agent, steering it, and seeing who reports to whom.
## Requirements
### Requirement: Agent detail

Agent detail SHALL show the agent's status and manager, its current run with elapsed time, its monthly budget, and its recent runs with result and cost.

#### Scenario: Near the budget cap

- **WHEN** an agent has spent at least 90% of its monthly cap
- **THEN** the budget bar turns orange and a note says the agent pauses automatically at 100%

### Requirement: Pause and wake

Agent detail SHALL offer Pause and Wake now.

#### Scenario: Waking a paused agent

- **WHEN** the user taps Wake now on a paused agent
- **THEN** the factory is asked to wake it and its status updates

#### Scenario: Agent already running

- **WHEN** the agent is running
- **THEN** Wake now is disabled

### Requirement: Org chart

At regular width the app SHALL draw the company as a tree from each agent's manager, with a summary of agents, agents working, pending hires and company spend.

#### Scenario: Reporting lines

- **WHEN** the demo company is shown
- **THEN** the CEO is at the top with the CTO and CMO below

#### Scenario: Broken reporting lines

- **WHEN** an agent's manager is unknown or managers form a loop
- **THEN** every agent still appears exactly once

#### Scenario: Selecting an agent

- **WHEN** the user selects a node
- **THEN** that agent's detail opens beside the chart

