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

Create the board user, a company and a few agents, tasks and approvals through
the server's own API, then obtain a credential of the kind Fabrix's auth
provider under test uses. Keep the steps in `scripts/paperclip-sandbox-seed.sh`
so they stay repeatable; credentials go to stdout or a file under `$TMPDIR`,
never into the repo.

## 3. Exercise

- Contract checks: run the client tests that are gated on the sandbox, e.g.
  `FABRIX_SANDBOX_URL="$base_url" xcrun swift test --package-path Packages/FabrixKit --filter Sandbox`.
- App check: build and launch `FabrixMac` (see CLAUDE.md), connect it to
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

Report what was checked against which image digest
(`docker image inspect ghcr.io/paperclipai/paperclip:latest --format '{{index .RepoDigests 0}}'`),
and say plainly which steps were skipped.
