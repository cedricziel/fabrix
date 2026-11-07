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
  op item create --category="Secure Note" --vault="$VAULT" \
    --title="fastlane-ci: match deploy key ($NAME)" \
    "private key[password]=$(cat "$tmp/key")" "public key[text]=$(cat "$tmp/key.pub")" \
    "notesPlain=Read-only deploy key on $CERTS_REPO; private key stored as MATCH_DEPLOY_KEY secret in $REPO" >/dev/null
fi
op item get "fastlane-ci: match deploy key ($NAME)" --vault "$VAULT" --fields "label=private key" --reveal \
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

gh secret list -R "$REPO"
