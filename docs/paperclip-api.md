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

Redirects are followed only within the same scheme, host and port. Any other redirect fails, and the error names only the new origin, since the full URL can carry a token.

There are two ways to get a board API key:

1. **Browser sign-in (CLI auth challenge).** Fabrix creates a challenge, the user approves it in a browser where they are signed in to Paperclip, and the pending key in the challenge becomes active.
2. **Paste a key** created with `POST /api/board-api-keys` (for example from the Paperclip CLI).

| Method | Path                                          | Use                                                                                                                                                                                                    |
| ------ | --------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| `GET`  | `/api/cli-auth/me`                            | Validate a credential. Returns the board user, `companyIds` and `isInstanceAdmin`. `401` if the key is missing or invalid.                                                                             |
| `POST` | `/api/cli-auth/challenges`                    | Start browser sign-in. Body: `{ "command": "fabrix connect", "clientName": "Fabrix" }`. Returns `id`, `token`, `boardApiToken`, `approvalPath`, `approvalUrl`, `expiresAt`, `suggestedPollIntervalMs`. |
| `GET`  | `/api/cli-auth/challenges/{id}?token={token}` | Poll the challenge. `status` is `pending`, `approved`, `cancelled` or `expired`.                                                                                                                       |

### OIDC in front of Paperclip

Paperclip has no OIDC login for board users. When a reverse proxy protects the server with OIDC, Fabrix signs in to the identity provider with Authorization Code + PKCE and sends `Bearer <access token>` on every request:

- In `Authorization` when the proxy fronts a `local_trusted` server.
- In a header you name, such as `X-Forwarded-Access-Token`, when Paperclip also needs a board key in `Authorization`.

The proxy must accept bearer tokens, for example oauth2-proxy with `--skip-jwt-bearer-tokens`.

## Reads

| Method | Path                                                  | Maps to                                                                                    |
| ------ | ----------------------------------------------------- | ------------------------------------------------------------------------------------------ |
| `GET`  | `/api/companies?scope=accessible`                     | `[Company]`: companies the user can open.                                                  |
| `GET`  | `/api/companies/{companyId}`                          | `Company`, plus `spentMonthlyCents` and `budgetMonthlyCents` for the snapshot.             |
| `GET`  | `/api/companies/{companyId}/agents`                   | `[Agent]`. Terminated agents are dropped.                                                  |
| `GET`  | `/api/agents/{agentId}`                               | Used by `wake` to check whether the agent is paused.                                       |
| `GET`  | `/api/companies/{companyId}/issues?limit=500`         | `[WorkItem]`.                                                                              |
| `GET`  | `/api/companies/{companyId}/approvals?status=pending` and `?status=revision_requested` | `[Approval]`, newest first. Two requests, because the filter matches one exact status; an approval in both answers is listed once. |
| `GET`  | `/api/companies/{companyId}/heartbeat-runs?limit=50`  | `[Run]`. A `403` (run telemetry hidden from this user) yields no runs instead of an error. |
| `GET`  | `/api/companies/{companyId}/activity?limit=50`        | `[ActivityEvent]`.                                                                         |

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
