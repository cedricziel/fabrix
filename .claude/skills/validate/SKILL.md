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

Several sessions may run sandboxes at once. Give yours its own name with
`export PAPERCLIP_SANDBOX_NAME=fabrix-<task>` before `up`. The container, its
data and the seed's state directory all follow that name, so set it for every
command below, including `down`.

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
   - four issues (todo, blocked, backlog, and a todo in the Mobile app project);
   - a project "Mobile app" led by the CTO, with a target date, a colour and the repository `https://github.com/atlas/mobile`, and an archived project "Old website";
   - a pending `hire_agent` approval and a pending `approve_ceo_strategy` approval.

It exports `FABRIX_SANDBOX_URL`, `FABRIX_SANDBOX_KEY` and `FABRIX_SANDBOX_COMPANY_ID`, and writes them to `$TMPDIR/$PAPERCLIP_SANDBOX_NAME/credentials.env` (default `fabrix-paperclip-sandbox`). `down` deletes that file with the sandbox data. Never commit it.

The seed covers the board-key provider only. The sandbox has no OIDC identity provider; OIDC is covered by the stubbed package tests (`OIDCFlowTests`, `OIDCAuthProviderTests`). To validate OIDC end to end, put a reverse proxy with an IdP in front of the sandbox yourself, and record that in the report.

## 3. Exercise

- Contract checks: `xcrun swift test --package-path Packages/FabrixKit --filter Sandbox`
  runs `SandboxContractTests` with the exported variables. They are skipped when
  `FABRIX_SANDBOX_URL` is unset. A filter that matches nothing still exits 0, and Swift
  Testing counts skipped tests in its summary, so a positive count proves nothing. Check that each
  `SandboxContractTests` test has its own `✔ … passed` line and that no `➜ … skipped` line
  appears; otherwise say the contract check was skipped. The tests change the seeded data: they approve and reject approvals and pause
  agents. Re-seed a fresh sandbox before running them again.
- App check: build the change and drive the Mac app against the sandbox.
  - Build from a worktree so the main checkout and other sessions are untouched:
    `git worktree add --detach <scratch>/wt <ref>`, then `xcodegen generate` and
    `xcodebuild build -scheme FabrixMac -configuration Debug -destination 'platform=macOS' -derivedDataPath <scratch>/wt/.dd -allowProvisioningUpdates`.
    Ad-hoc signing fails because of the Keychain access group; use development signing.
  - Launch `<scratch>/wt/.dd/Build/Products/Debug/Fabrix.app` with `open`, and drive it
    with the computer-use `app_*` tools (bundle `com.cedricziel.fabrix`).
  - Connect it to `$FABRIX_SANDBOX_URL` and confirm the seeded company, agents,
    tasks and approvals show up. Approve one approval and pause one agent, then
    confirm both through the API. Take a screenshot as evidence.
  - Password fields can't be typed into by automation. For the paste-a-key method,
    put the key on the clipboard with `printf %s "$FABRIX_SANDBOX_KEY" | pbcopy`
    and ask the user to paste it. Clear the clipboard afterwards.
- Browser sign-in check (the default sign-in method):
  1. Choose "Sign in with browser", enter the sandbox URL and press Connect. The
     app shows "Approve Fabrix in your browser".
  2. Press "Copy link" and read it with `pbpaste`. The link must use the sandbox
     origin. Redact `token=` when you print it.
  3. Open the link in Claude's built-in browser, not the user's browser. Sign in
     with the seed's sandbox-only test account (`board@fabrix.test` /
     `fabrix-sandbox-password` from `scripts/paperclip-sandbox-seed.sh`), then press
     "Approve CLI access". It should name the command `fabrix connect`.
  4. The app should connect on its own and load the company.
     `GET /api/board-api-keys` (with `$FABRIX_SANDBOX_KEY`) lists the new key; note its name.
  5. Expiry and revocation: `DELETE /api/board-api-keys/<id>` the app's key. The app
     should show "Sign in again" within one poll, and the count of 401s in
     `docker logs` should stop growing. Sign in again, approve, and confirm it recovers.
  6. Cancel: start a sign-in, copy the link, press Cancel. Check the challenge with
     `GET /api/cli-auth/challenges/<id>?token=<token>`: it should be `cancelled`, and
     the app's polls for it in `docker logs` should stop.
  - Wait on conditions with an until-loop on the API or `docker logs`. Don't end a
    turn to wait; nothing wakes you up afterwards.
  - Afterwards: remove the sandbox factory in the app (Remove Factory…), quit the
    app, clear the clipboard (`pbcopy </dev/null`), and remove the worktree. The Debug
    build shares the real bundle ID, so it writes to the user's app container and Keychain.

## 4. Inspect on failure

```bash
scripts/paperclip-sandbox.sh logs
```

## 5. Clean up — always, also after a failure

```bash
scripts/paperclip-sandbox.sh down
docker ps -a --format '{{.Names}}' | grep "${PAPERCLIP_SANDBOX_NAME:-fabrix-paperclip-sandbox}" || echo clean
```

Before cleaning up, record the image the sandbox actually ran
(`scripts/paperclip-sandbox.sh image`), then report what was checked against it
and say plainly which steps were skipped.
