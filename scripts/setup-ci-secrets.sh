#!/usr/bin/env bash
# Sets the GitHub Actions secrets fastlane needs, reading values from 1Password.
# Creates a repo-specific read-only match deploy key and keychain password.
set -euo pipefail

REPO="${REPO:-cedricziel/fabrix}"
NAME="${REPO#*/}"
CERTS_REPO="cedricziel/certificates"
VAULT="Private"

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

if ! op item get "fastlane-ci: match deploy key ($NAME)" --vault "$VAULT" >/dev/null 2>&1; then
  ssh-keygen -t ed25519 -N "" -C "fastlane-ci match ($NAME)" -f "$tmp/key" -q
  gh api -X POST "repos/$CERTS_REPO/keys" \
    -f title="$NAME CI (match, read-only)" -f key="$(cat "$tmp/key.pub")" -F read_only=true >/dev/null
  python3 - "$tmp/key" "$NAME" "$CERTS_REPO" "$REPO" <<'PY' | op item create --vault="$VAULT" - >/dev/null
import json, sys
key, name, certs, repo = sys.argv[1:]
print(json.dumps({
    "title": f"fastlane-ci: match deploy key ({name})",
    "category": "SECURE_NOTE",
    "fields": [
        {"id": "notesPlain", "type": "STRING", "purpose": "NOTES",
         "value": f"Read-only deploy key on {certs}; private key stored as MATCH_DEPLOY_KEY secret in {repo}"},
        {"label": "private key", "type": "CONCEALED", "value": open(key).read()},
        {"label": "public key", "type": "STRING", "value": open(key + ".pub").read().strip()},
    ],
}))
PY
fi
# `--fields` prints CSV, which wraps a multi-line key in quotes; read the raw value from JSON instead.
op item get "fastlane-ci: match deploy key ($NAME)" --vault "$VAULT" --format json \
  | python3 -c 'import json, sys; v = next(f["value"] for f in json.load(sys.stdin)["fields"] if f.get("label") == "private key"); sys.stdout.write(v if v.endswith("\n") else v + "\n")' \
  | gh secret set MATCH_DEPLOY_KEY -R "$REPO"

if ! op item get "fastlane-ci: keychain ($NAME)" --vault "$VAULT" >/dev/null 2>&1; then
  op item create --category=Password --vault="$VAULT" --title="fastlane-ci: keychain ($NAME)" \
    --generate-password=32,letters,digits "notesPlain=MATCH_KEYCHAIN_PASSWORD for $REPO CI" >/dev/null
fi
op item get "fastlane-ci: keychain ($NAME)" --vault "$VAULT" --fields label=password --reveal | tr -d '\n' \
  | gh secret set MATCH_KEYCHAIN_PASSWORD -R "$REPO"

op item get "fastlane-ci: match" --vault "$VAULT" --fields label=password --reveal | tr -d '\n' \
  | gh secret set MATCH_PASSWORD -R "$REPO"
printf '%s' "git@github.com:$CERTS_REPO.git" | gh secret set MATCH_GIT_URL -R "$REPO"

printf '%s' "3W9XDG5U47" | gh secret set ASC_KEY_ID -R "$REPO"
op item get "AppStore Connect: fastlane-ci" --vault "$VAULT" --fields "label=Issue ID" | tr -d '\n' \
  | gh secret set ASC_ISSUER_ID -R "$REPO"
asc_item="$(op item get "AppStore Connect: fastlane-ci" --vault "$VAULT" --format json | python3 -c 'import json,sys; print(json.load(sys.stdin)["id"])')"
op read "op://$VAULT/$asc_item/AuthKey_3W9XDG5U47.p8" > "$tmp/asc.p8"
grep -q "BEGIN PRIVATE KEY" "$tmp/asc.p8"
base64 < "$tmp/asc.p8" | tr -d '\n' | gh secret set ASC_KEY_CONTENT -R "$REPO"

op read "op://$VAULT/release-please token/token" | tr -d '\n' | gh secret set RELEASE_PLEASE_TOKEN -R "$REPO"

for k in REVIEW_CONTACT_FIRST_NAME REVIEW_CONTACT_LAST_NAME REVIEW_CONTACT_PHONE REVIEW_CONTACT_EMAIL; do
  op item get "Fabrix: App Review contact" --vault "$VAULT" --fields "label=$k" --reveal | tr -d '\n' \
    | gh secret set "$k" -R "$REPO"
done
op item get "signaldb - apps / fabrix ingest" --vault "$VAULT" --fields label=otlp_http | tr -d '\n' \
  | gh secret set OTLP_ENDPOINT -R "$REPO"
op item get "signaldb - apps / fabrix ingest" --vault "$VAULT" --fields label=credential --reveal | tr -d '\n' \
  | gh secret set OTLP_API_KEY -R "$REPO"

gh secret list -R "$REPO"
