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
json_user_id() { python3 -c 'import json,sys; print(json.load(sys.stdin)["user"]["id"])'; }

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
# Add a second active member for reviewer access coverage.
REVIEWER="$(curl -fsS -H "Origin: $BASE" -H 'Content-Type: application/json' -X POST "$BASE/api/auth/sign-up/email" -d '{"email":"reviewer@fabrix.test","password":"fabrix-sandbox-password","name":"Sandbox Reviewer"}' | json_user_id)"
api -X PUT "$BASE/api/admin/users/$REVIEWER/company-access" -d "{\"companyIds\":[\"$COMPANY\"]}" >/dev/null
agent() { api -X POST "$BASE/api/companies/$COMPANY/agents" -d "$1" | json_field id; }
CTO="$(agent '{"name":"CTO","role":"cto","title":"Chief Technology Officer","adapterType":"process","adapterConfig":{"command":"true"}}')"
OPS="$(agent "{\"name\":\"DevOps\",\"role\":\"engineer\",\"title\":\"Infrastructure\",\"reportsTo\":\"$CTO\",\"adapterType\":\"process\",\"adapterConfig\":{\"command\":\"true\"}}")"
api -X POST "$BASE/api/agents/$OPS/pause" >/dev/null

issue() { api -X POST "$BASE/api/companies/$COMPANY/issues" -d "$1" >/dev/null; }
issue "{\"title\":\"Split sync worker into queue consumers\",\"status\":\"todo\",\"assigneeAgentId\":\"$CTO\"}"
issue "{\"title\":\"Rotate staging certificates\",\"status\":\"blocked\",\"assigneeAgentId\":\"$OPS\"}"
issue '{"title":"Evaluate push provider"}'

# Interaction issues are intentionally left unassigned and at the API default status.
interaction_issue() { api -X POST "$BASE/api/companies/$COMPANY/issues" -d "$1" | json_field id; }
CONFIRMATION="$(interaction_issue '{"title":"Confirm rollout"}')"
api -X POST "$BASE/api/issues/$CONFIRMATION/interactions" -d '{"kind":"request_confirmation","payload":{"version":1,"prompt":"Proceed?","acceptLabel":"Proceed","rejectLabel":"Hold","rejectRequiresReason":true}}' >/dev/null
CHECKBOX="$(interaction_issue '{"title":"Verify readiness"}')"
api -X POST "$BASE/api/issues/$CHECKBOX/interactions" -d '{"kind":"request_checkbox_confirmation","payload":{"version":1,"prompt":"Check readiness","options":[{"id":"backup","label":"Backup verified"}],"defaultSelectedOptionIds":[],"minSelected":0}}' >/dev/null
QUESTIONS="$(interaction_issue '{"title":"Choose push provider"}')"
api -X POST "$BASE/api/issues/$QUESTIONS/interactions" -d '{"kind":"ask_user_questions","payload":{"version":1,"questionSet":{"schema":"paperclip.question_set.v1","questions":[{"id":"provider","prompt":"Which provider?","required":true,"answerMode":"single_select","options":[{"id":"apns","label":"APNs","recommended":true},{"id":"other-provider","label":"Another provider"}],"customAnswer":{"enabled":true,"label":"Other"}},{"id":"notes","prompt":"Rollout notes?","required":false,"answerMode":"text"}]}}}' >/dev/null
VERDICTS="$(interaction_issue '{"title":"Review release notes"}')"
api -X POST "$BASE/api/issues/$VERDICTS/interactions" -d '{"kind":"request_item_verdicts","payload":{"version":1,"prompt":"Review release notes","items":[{"id":"intro","label":"Introduction"}],"verdicts":["approve","reject","defer"],"requireReasonOn":["reject"],"allowBulkApprove":true}}' >/dev/null
TASKS="$(interaction_issue '{"title":"Suggest release task"}')"
api -X POST "$BASE/api/issues/$TASKS/interactions" -d '{"kind":"suggest_tasks","payload":{"version":1,"tasks":[{"clientKey":"release-check","title":"Check release readiness"}]}}' >/dev/null

project() { api -X POST "$BASE/api/companies/$COMPANY/projects" -d "$1" | json_field id; }
MOBILE="$(project "{\"name\":\"Mobile app\",\"status\":\"in_progress\",\"leadAgentId\":\"$CTO\",\"targetDate\":\"2026-12-15\",\"color\":\"#0F766E\",\"repositoryUrls\":[\"https://github.com/atlas/mobile\"]}")"
issue "{\"title\":\"Offline cache for task list\",\"status\":\"todo\",\"projectId\":\"$MOBILE\"}"
ARCHIVED="$(project '{"name":"Old website","status":"completed"}')"
api -X PATCH "$BASE/api/projects/$ARCHIVED" -d '{"archivedAt":"2026-01-01T00:00:00.000Z"}' >/dev/null

approval() { api -X POST "$BASE/api/companies/$COMPANY/approvals" -d "$1" | json_field id; }
HIRE_APPROVAL="$(approval "{\"type\":\"hire_agent\",\"requestedByAgentId\":\"$CTO\",\"payload\":{\"name\":\"Designer\",\"role\":\"designer\",\"title\":\"Product Designer\",\"adapterType\":\"process\"}}")"
api -X POST "$BASE/api/approvals/$HIRE_APPROVAL/comments" -d '{"body":"Please check the rollout notes."}' >/dev/null
approval '{"type":"approve_ceo_strategy","payload":{"title":"Q4 plan","plan":"Retention over new features."}}' >/dev/null

ENV_FILE="$STATE_DIR/credentials.env"
cat >"$ENV_FILE" <<EOF
export FABRIX_SANDBOX_URL=$BASE
export FABRIX_SANDBOX_KEY=$KEY
export FABRIX_SANDBOX_COMPANY_ID=$COMPANY
EOF
chmod 600 "$ENV_FILE"
cat "$ENV_FILE"
