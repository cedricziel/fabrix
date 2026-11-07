#!/usr/bin/env bash
# Runs fastlane locally with App Store Connect and match credentials read from 1Password.
#   scripts/fastlane-local.sh register_bundle_id
#   scripts/fastlane-local.sh bootstrap_signing
set -euo pipefail
cd "$(dirname "$0")/.."

VAULT="Private"
OTLP_ITEM="signaldb - apps / fabrix ingest"
asc_item="$(op item get "AppStore Connect: fastlane-ci" --vault "$VAULT" --format json | python3 -c 'import json,sys; print(json.load(sys.stdin)["id"])')"
ASC_KEY_CONTENT="$(op read "op://$VAULT/$asc_item/AuthKey_3W9XDG5U47.p8" | base64 | tr -d '\n')"
ASC_ISSUER_ID="$(op item get "$asc_item" --vault "$VAULT" --fields "label=Issue ID")"
MATCH_PASSWORD="$(op item get "fastlane-ci: match" --vault "$VAULT" --fields label=password --reveal)"
for k in REVIEW_CONTACT_FIRST_NAME REVIEW_CONTACT_LAST_NAME REVIEW_CONTACT_PHONE REVIEW_CONTACT_EMAIL; do
  export "$k=$(op item get "Fabrix: App Review contact" --vault "$VAULT" --fields "label=$k" --reveal)"
done
OTLP_ENDPOINT="$(op item get "$OTLP_ITEM" --vault "$VAULT" --fields label=otlp_http)"
OTLP_API_KEY="$(op item get "$OTLP_ITEM" --vault "$VAULT" --fields label=credential --reveal)"
export ASC_KEY_ID="3W9XDG5U47" ASC_KEY_CONTENT ASC_ISSUER_ID MATCH_PASSWORD OTLP_ENDPOINT OTLP_API_KEY

PATH="/opt/homebrew/opt/ruby/bin:$PATH" exec bundle exec fastlane "$@"
