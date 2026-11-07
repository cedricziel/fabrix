---
name: validate
description: Validate a Fabrix change end to end against an isolated, throwaway Paperclip server in Docker — start the sandbox, seed it, point the app or tests at it, check the behavior, tear it down. Use before reporting a change that touches FabrixCore networking, auth, the FactoryService mapping, or any screen that shows server data. Not for pure UI tweaks covered by the demo factory, and never against a real factory.
---

# Validate against a sandboxed Paperclip

Fabrix must never be validated against someone's real factory. This loop runs a
private Paperclip server in Docker on a random loopback port with its own data
directory, and deletes both afterwards.

## 1. Start

```bash
base_url="$(scripts/paperclip-sandbox.sh up)"   # waits for /api/health, prints http://127.0.0.1:<port>
curl -fsS "$base_url/api/health"
```

The sandbox runs `ghcr.io/paperclipai/paperclip:latest` in `authenticated` /
`private` mode with fresh random secrets. Pin another image with
`PAPERCLIP_IMAGE=ghcr.io/paperclipai/paperclip:<tag>`. A fresh server reports
`"bootstrapStatus":"bootstrap_pending"`: no board user exists yet.

## 2. Seed and get a credential

```bash
eval "$(scripts/paperclip-sandbox-seed.sh)"   # needs a fresh sandbox; run once per `up`
```

The script uses the server's own API:

1. It signs up `board@fabrix.test` (`POST /api/auth/sign-up/email`) and claims the instance (`POST /api/bootstrap/claim`).
2. It mints a board API key (`POST /api/board-api-keys`). The session cookie stays inside the script.
3. It creates the company "Atlas Sandbox" with:
   - a CTO agent and a DevOps agent, paused, reporting to the CTO;
   - three issues (todo, blocked, backlog);
   - a pending `hire_agent` approval and a pending `approve_ceo_strategy` approval.

It exports `FABRIX_SANDBOX_URL`, `FABRIX_SANDBOX_KEY` and `FABRIX_SANDBOX_COMPANY_ID`, and writes them to `$TMPDIR/fabrix-paperclip-sandbox/credentials.env`. `down` deletes that file with the sandbox data. Never commit it.

The seed covers the board-key provider only. The sandbox has no OIDC identity provider; OIDC is covered by the stubbed package tests (`OIDCFlowTests`, `OIDCAuthProviderTests`). To validate OIDC end to end, put a reverse proxy with an IdP in front of the sandbox yourself, and record that in the report.

## 3. Exercise

- Contract checks: `xcrun swift test --package-path Packages/FabrixKit --filter Sandbox`
  runs `SandboxContractTests` with the exported variables. They are skipped when
  `FABRIX_SANDBOX_URL` is unset. A filter that matches nothing still exits 0, and Swift
  Testing counts skipped tests in its summary, so a positive count proves nothing. Check that each
  `SandboxContractTests` test has its own `✔ … passed` line and that no `➜ … skipped` line
  appears; otherwise say the contract check was skipped. The tests change the seeded data: they approve and reject approvals and pause
  agents. Re-seed a fresh sandbox before running them again.
- App check (only once the app can connect to a factory and shows approvals and
  agents; until then, report it as skipped): build and launch `FabrixMac` (see CLAUDE.md), connect it to
  `$base_url`, and confirm the seeded company, agents, tasks and approvals show
  up; approve one approval and pause one agent, then confirm the change through
  the API. Take a screenshot as evidence.

## 4. Inspect on failure

```bash
scripts/paperclip-sandbox.sh logs
```

## 5. Clean up — always, also after a failure

```bash
scripts/paperclip-sandbox.sh down
docker ps -a --format '{{.Names}}' | grep fabrix-paperclip-sandbox || echo clean
```

Before cleaning up, record the image the sandbox actually ran
(`scripts/paperclip-sandbox.sh image`), then report what was checked against it
and say plainly which steps were skipped.
