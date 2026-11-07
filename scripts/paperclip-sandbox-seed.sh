#!/usr/bin/env bash
# Seeds a fresh Paperclip sandbox (scripts/paperclip-sandbox.sh up) through its own API:
# board user + instance claim, a board API key, one company with agents, issues, approvals and projects.
# Prints shell assignments for the sandbox contract tests:
#   eval "$(scripts/paperclip-sandbox-seed.sh)"
#   xcrun swift test --package-path Packages/FabrixKit --filter Sandbox
# Also writes them to $TMPDIR/fabrix-paperclip-sandbox/credentials.env. Never commit that file.
set -euo pipefail

BASE="${1:-$("$(dirname "$0")/paperclip-sandbox.sh" url)}"
STATE_DIR="${TMPDIR:-/tmp}/${PAPERCLIP_SANDBOX_NAME:-fabrix-paperclip-sandbox}"
JAR="$STATE_DIR/cookies.txt"
mkdir -p "$STATE_DIR"
rm -f "$JAR"

json_field() { python3 -c 'import json,sys; print(json.load(sys.stdin)[sys.argv[1]])' "$1"; }

session() { curl -fsS -c "$JAR" -b "$JAR" -H "Origin: $BASE" -H 'Content-Type: application/json' "$@"; }

# 1. Board user, first-admin claim, board API key (session cookie only lives in this script).
session -X POST "$BASE/api/auth/sign-up/email" \
  -d '{"email":"board@fabrix.test","password":"fabrix-sandbox-password","name":"Sandbox Board"}' >/dev/null
session -X POST "$BASE/api/bootstrap/claim" -d '{}' >/dev/null
KEY="$(session -X POST "$BASE/api/board-api-keys" -d '{"name":"fabrix-sandbox"}' | json_field token)"
rm -f "$JAR"

api() { curl -fsS -H "Authorization: Bearer $KEY" -H 'Content-Type: application/json' "$@"; }

# 2. Company, agents, issues and approvals.
COMPANY="$(api -X POST "$BASE/api/companies" -d '{"name":"Atlas Sandbox","description":"Seeded by Fabrix"}' | json_field id)"
agent() { api -X POST "$BASE/api/companies/$COMPANY/agents" -d "$1" | json_field id; }
CTO="$(agent '{"name":"CTO","role":"cto","title":"Chief Technology Officer","adapterType":"process","adapterConfig":{"command":"true"}}')"
OPS="$(agent "{\"name\":\"DevOps\",\"role\":\"engineer\",\"title\":\"Infrastructure\",\"reportsTo\":\"$CTO\",\"adapterType\":\"process\",\"adapterConfig\":{\"command\":\"true\"}}")"
api -X POST "$BASE/api/agents/$OPS/pause" >/dev/null

issue() { api -X POST "$BASE/api/companies/$COMPANY/issues" -d "$1" >/dev/null; }
issue "{\"title\":\"Split sync worker into queue consumers\",\"status\":\"todo\",\"assigneeAgentId\":\"$CTO\"}"
issue "{\"title\":\"Rotate staging certificates\",\"status\":\"blocked\",\"assigneeAgentId\":\"$OPS\"}"
issue '{"title":"Evaluate push provider"}'

project() { api -X POST "$BASE/api/companies/$COMPANY/projects" -d "$1" | json_field id; }
MOBILE="$(project "{\"name\":\"Mobile app\",\"status\":\"in_progress\",\"leadAgentId\":\"$CTO\",\"targetDate\":\"2026-12-15\",\"color\":\"#0F766E\",\"repositoryUrls\":[\"https://github.com/atlas/mobile\"]}")"
issue "{\"title\":\"Offline cache for task list\",\"status\":\"todo\",\"projectId\":\"$MOBILE\"}"
ARCHIVED="$(project '{"name":"Old website","status":"completed"}')"
api -X PATCH "$BASE/api/projects/$ARCHIVED" -d '{"archivedAt":"2026-01-01T00:00:00.000Z"}' >/dev/null

approval() { api -X POST "$BASE/api/companies/$COMPANY/approvals" -d "$1" >/dev/null; }
approval "{\"type\":\"hire_agent\",\"requestedByAgentId\":\"$CTO\",\"payload\":{\"name\":\"Designer\",\"role\":\"designer\",\"title\":\"Product Designer\",\"adapterType\":\"process\"}}"
approval '{"type":"approve_ceo_strategy","payload":{"title":"Q4 plan","plan":"Retention over new features."}}'

ENV_FILE="$STATE_DIR/credentials.env"
cat >"$ENV_FILE" <<EOF
export FABRIX_SANDBOX_URL=$BASE
export FABRIX_SANDBOX_KEY=$KEY
export FABRIX_SANDBOX_COMPANY_ID=$COMPANY
EOF
chmod 600 "$ENV_FILE"
cat "$ENV_FILE"
