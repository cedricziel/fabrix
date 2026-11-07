# Paperclip API used by Fabrix

Fabrix talks to a Paperclip server through `PaperclipClient` in `FabrixCore`. This page lists every endpoint the client calls and how Fabrix maps the responses. Source of truth: the Paperclip repository (`server/src/routes`, `packages/shared/src/types`, `docs/api`).

All paths are relative to the server root. The client appends `/api` itself, so a factory URL is stored as `https://paperclip.example.com`, not `https://paperclip.example.com/api`.

## Authentication

Fabrix acts as a **board user** (a human operator), not as an agent.

| Deployment mode | What Fabrix sends                                                                                     |
| --------------- | ----------------------------------------------------------------------------------------------------- |
| `local_trusted` | Nothing. Every request is treated as the local board.                                                 |
| `authenticated` | `Authorization: Bearer <board API key>`. Board keys start with `pcp_board_` and expire after 30 days. |

Fabrix sends credentials only over HTTPS, or over plain HTTP to this machine or a private network (loopback, `.local`, RFC 1918, Tailscale's `100.64.0.0/10`, link-local, IPv6 unique-local). Otherwise `PaperclipError.insecureConnection` is thrown before any request. Browser sign-in follows the same rule, because the approval response carries the new key. So do OIDC discovery and token requests, and the server check runs before the OIDC login page opens.

A factory can also carry custom headers, such as a reverse proxy's access token. They are sent with every request to the factory's origin under the same transport rule, and never to the OIDC issuer.

Redirects are followed only within the same scheme, host and port. Any other redirect fails, and the error names only the new origin, since the full URL can carry a token.

There are two ways to get a board API key:

1. **Browser sign-in (CLI auth challenge).** This is the default in the connect form. Fabrix creates a challenge and opens its approval page in the user's browser. The user approves it there while signed in to Paperclip, and the key in the challenge becomes active. The approval page is opened on the factory's own origin, even when the server reports another host in `approvalUrl`.
2. **Paste a key** created with `POST /api/board-api-keys`, for example from the Paperclip CLI.

### Where people get a board key

Paperclip's web UI has no page that creates or lists board API keys. This was checked in Paperclip's source at `cc3e67cf`; the sandbox image runs `d69631b`.

- **Web UI:** the only board-key page is the approval page at `/cli-auth/:id`. Its heading is "Approve Paperclip CLI access", with the buttons "Approve CLI access" and "Cancel". These settings pages don't manage board keys:
  - `/company/settings` and its `connections`, `members` and `secrets` tabs
  - `/company/settings/instance/profile`
  - `/company/settings/instance/access`

  The "API key" fields in the onboarding wizard are for LLM providers, not Paperclip.
- **CLI (`paperclipai`):**
  - `paperclipai auth login [--instance-admin] [--no-browser]` runs the same browser approval as Fabrix. Related commands: `auth whoami`, `auth logout`, `auth revoke-current` and `auth challenge create|get|approve|cancel`.
  - `paperclipai token board create [--name <label>] [--expires-at <iso8601> | --ttl-days <n> | --never-expires]` creates a named key once the CLI is signed in. Related commands: `token board list` and `token board revoke`. (`token agent …` manages agent keys, which Fabrix doesn't use.)

So without the CLI, browser sign-in is the only way to get a key.

Board keys expire after 30 days by default. Fabrix reads the expiry by taking `keyId` from `/api/cli-auth/me` and finding that key in `GET /api/board-api-keys`. It offers to sign in again when fewer than 5 days are left, or once the key is rejected.

| Method | Path                                          | Use                                                                                                                                                                                                    |
| ------ | --------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| `GET`  | `/api/cli-auth/me`                            | Validate a credential. Returns the board user, `companyIds` and `isInstanceAdmin`. `401` if the key is missing or invalid.                                                                             |
| `POST` | `/api/cli-auth/challenges`                    | Start browser sign-in. Body: `{ "command": "fabrix connect", "clientName": "Fabrix" }`. Returns `id`, `token`, `boardApiToken`, `approvalPath`, `approvalUrl`, `expiresAt`, `suggestedPollIntervalMs`. |
| `GET`  | `/api/cli-auth/challenges/{id}?token={token}` | Poll the challenge. `status` is `pending`, `approved`, `cancelled` or `expired`.                                                                                                                       |

Also used:

- `GET /api/board-api-keys` lists the signed-in user's keys with `id`, `name` and `expiresAt`. A `403` or `404` means no expiry warning.
- `POST /api/cli-auth/challenges/{id}/approve` takes `{ "token": … }`. Paperclip's approval page calls it, and the sandbox contract tests call it with the seeded board key.

### OIDC in front of Paperclip

Paperclip has no OIDC login for board users. When a reverse proxy protects the server with OIDC, Fabrix signs in to the identity provider with Authorization Code + PKCE and sends `Bearer <access token>` on every request:

- In `Authorization` when the proxy fronts a `local_trusted` server.
- In a header you name, such as `X-Forwarded-Access-Token`, when Paperclip also needs a board key in `Authorization`.

The proxy must accept bearer tokens, for example oauth2-proxy with `--skip-jwt-bearer-tokens`.

## Reads

| Method | Path                                                                                   | Maps to                                                                                                                                                                                                    |
| ------ | -------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `GET`  | `/api/companies?scope=accessible`                                                      | `[Company]`: companies the user can open.                                                                                                                                                                  |
| `GET`  | `/api/companies/{companyId}`                                                           | `Company`, plus `spentMonthlyCents` and `budgetMonthlyCents` for the snapshot.                                                                                                                             |
| `GET`  | `/api/companies/{companyId}/agents`                                                    | `[Agent]`. Terminated agents are dropped; their IDs stay in `formerAgentIDs`.                                                                                                                              |
| `GET`  | `/api/agents/{agentId}`                                                                | Used by `wake` to check whether the agent is paused.                                                                                                                                                       |
| `GET`  | `/api/companies/{companyId}/issues?limit=500`                                          | `[WorkItem]`.                                                                                                                                                                                              |
| `GET`  | `/api/companies/{companyId}/approvals?status=pending` and `?status=revision_requested` | `[Approval]`, newest first. Two requests, because the filter matches one exact status; an approval in both answers is listed once.                                                                         |
| `GET`  | `/api/companies/{companyId}/heartbeat-runs?limit=50`                                   | `[Run]`. A `403` (run telemetry hidden from this user) yields no runs instead of an error.                                                                                                                 |
| `GET`  | `/api/companies/{companyId}/activity?limit=50`                                         | `[ActivityEvent]`.                                                                                                                                                                                         |
| `GET`  | `/api/companies/{companyId}/projects`                                                  | `[Project]` via `projects(companyID:)`. Archived projects are left out. A `404` means the server has no projects endpoint: `FactoryServiceError.unsupported`, and the app hides projects without an error. |

An issue's `projectId` maps to `WorkItem.projectID`. An activity row with `entityType` `issue` sets `ActivityEvent.taskID`; one with `entityType` `project` sets `ActivityEvent.projectID`.

Projects are a separate call, not part of the company snapshot, so a failed projects request doesn't fail the snapshot.

### Project fields

The server omits archived projects unless the request has `?includeArchived=true`. Fabrix doesn't send it, and also drops any row with `archivedAt` set.

| Paperclip field             | `Project`                                                                                       |
| --------------------------- | ----------------------------------------------------------------------------------------------- |
| `name`                      | `name`                                                                                          |
| `description`               | `summary`                                                                                       |
| `leadAgentId`               | `leadAgentID`                                                                                   |
| `color` (`#RRGGBB`)         | `colorHex`                                                                                      |
| `goals[].title`             | `goals`                                                                                         |
| `targetDate` (`YYYY-MM-DD`) | `targetDate` as `DateComponents`, so no time zone shifts the day. Malformed values are dropped. |
| `workspaces`                | `repositories`                                                                                  |

Each workspace maps by `sourceType`. `isPrimary` is kept in every case.

| Workspace `sourceType`           | Repository                                                                                                                                |
| -------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------- |
| `git_repo`                       | `.git`. `url` is `repoUrl`, `name` is `owner/name` from the URL path (else the workspace `name`), `ref` is `defaultRef` (else `repoRef`). |
| `local_path`, `non_git_path`     | `.folder`, `name` is `cwd`.                                                                                                               |
| anything else (`remote_managed`) | `.other`                                                                                                                                  |

Fabrix ignores `budget` and `urlKey`. It counts open, blocked and done tasks from the snapshot's issues, which are capped at 500. `taskCount` counts every task, done and cancelled included; Fabrix keeps it as `Project.taskCount` and, when it is larger than the project's loaded tasks, says how many older tasks weren't counted.

A row that can't be decoded is skipped, so one malformed project or workspace doesn't fail the list. Only `http` and `https` repository URLs are kept as links.

A project belongs to one company. Paperclip refuses issues, assignees and goals from another company, but accepts a `leadAgentId` from another company. Fabrix shows such a lead as "Lead outside this company", without agent actions.

`GET /api/projects/{urlKey}` works only with `?companyId=`; without it the server answers `500`. Fabrix doesn't call it.

## Writes

| Method  | Path                                  | `FactoryService` call                                                                        |
| ------- | ------------------------------------- | -------------------------------------------------------------------------------------------- |
| `POST`  | `/api/approvals/{approvalId}/approve` | `decide(approvalID:approve: true)`                                                           |
| `POST`  | `/api/approvals/{approvalId}/reject`  | `decide(approvalID:approve: false)`                                                          |
| `POST`  | `/api/agents/{agentId}/resume`        | `wake(agentID:)`, only when the agent is paused                                              |
| `POST`  | `/api/agents/{agentId}/wakeup`        | `wake(agentID:)`. Body: `{ "source": "on_demand", "triggerDetail": "manual" }`               |
| `POST`  | `/api/agents/{agentId}/pause`         | `pause(agentID:)`                                                                            |
| `PATCH` | `/api/companies/{companyId}`          | `setCompanyPaused(_:companyID:)`. Body: `{ "status": "paused" }` or `{ "status": "active" }` |

## Status mapping

| Paperclip agent `status` | `AgentStatus`             |
| ------------------------ | ------------------------- |
| `running`                | `.running`                |
| `active`, `idle`         | `.idle`                   |
| `paused`                 | `.paused`                 |
| `error`                  | `.error`                  |
| `pending_approval`       | `.needsYou`               |
| `terminated`             | dropped from the snapshot |
| anything else            | `.idle`                   |

Issue `status` values (`backlog`, `todo`, `in_progress`, `in_review`, `blocked`, `done`, `cancelled`) map one to one onto `TaskStatus`. Unknown values become `.backlog`.

| Paperclip approval `type`               | `ApprovalKind` |
| --------------------------------------- | -------------- |
| `hire_agent`                            | `.hire`        |
| `approve_ceo_strategy`                  | `.strategy`    |
| `budget_override_required`              | `.budget`      |
| `request_board_approval`, anything else | `.other`       |

| Paperclip approval `status`     | `ApprovalState` |
| ------------------------------- | --------------- |
| `pending`, `revision_requested` | `.pending`      |
| `approved`                      | `.approved`     |
| `rejected`, `cancelled`         | `.rejected`     |

| Paperclip project `status` | `ProjectStatus` |
| -------------------------- | --------------- |
| `backlog`                  | `.backlog`      |
| `planned`                  | `.planned`      |
| `in_progress`              | `.inProgress`   |
| `completed`                | `.completed`    |
| `cancelled`                | `.cancelled`    |
| anything else              | `.other`        |

`.backlog`, `.planned` and `.inProgress` count as active. The app lists the others, `.other` included, under Completed.

A heartbeat run is live (`Run.finishedAt == nil`) while its status is `queued`, `scheduled_retry` or `running`.

## Errors

Paperclip returns `{ "error": "<message>" }` on failure. `PaperclipError` maps the HTTP status:

| HTTP status   | `PaperclipError`           |
| ------------- | -------------------------- |
| `400`, `422`  | `.invalidRequest(message)` |
| `401`         | `.unauthorized(message)`   |
| `403`         | `.forbidden(message)`      |
| `404`         | `.notFound(message)`       |
| `409`         | `.conflict(message)`       |
| other non-2xx | `.server(status:message:)` |

Network failures become `.transport(URLError.Code)` and undecodable bodies become `.decoding(String)`.
