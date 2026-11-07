#!/usr/bin/env bash
# Throwaway Paperclip server in Docker for validating Fabrix against a real API.
#   scripts/paperclip-sandbox.sh up      start (prints the base URL)
#   scripts/paperclip-sandbox.sh url     print the base URL of the running sandbox
#   scripts/paperclip-sandbox.sh logs    follow server logs
#   scripts/paperclip-sandbox.sh down    stop and delete the container and its data
set -euo pipefail

NAME="${PAPERCLIP_SANDBOX_NAME:-fabrix-paperclip-sandbox}"
IMAGE="${PAPERCLIP_IMAGE:-ghcr.io/paperclipai/paperclip:latest}"
STATE_DIR="${TMPDIR:-/tmp}/$NAME"

url() {
  local port
  port="$(docker port "$NAME" 3100/tcp | head -n1 | sed 's/.*://')"
  echo "http://127.0.0.1:$port"
}

case "${1:-}" in
  up)
    if docker ps -a --format '{{.Names}}' | grep -qx "$NAME"; then
      echo "Sandbox $NAME already exists; run '$0 down' first." >&2
      exit 1
    fi
    rm -rf "$STATE_DIR" && mkdir -p "$STATE_DIR/data"
    docker run -d --name "$NAME" \
      -p 127.0.0.1::3100 \
      -e HOST=0.0.0.0 \
      -e PAPERCLIP_HOME=/paperclip \
      -e PAPERCLIP_DEPLOYMENT_MODE=authenticated \
      -e PAPERCLIP_DEPLOYMENT_EXPOSURE=private \
      -e BETTER_AUTH_SECRET="$(openssl rand -hex 32)" \
      -e PAPERCLIP_TOOL_ACTION_SIGNING_SECRET="$(openssl rand -hex 32)" \
      -v "$STATE_DIR/data:/paperclip" \
      "$IMAGE" >/dev/null
    base="$(url)"
    docker exec "$NAME" true
    for _ in $(seq 1 90); do
      if curl -fsS "$base/api/health" >/dev/null 2>&1; then
        echo "$base"
        exit 0
      fi
      sleep 2
    done
    echo "Paperclip did not become healthy at $base; see '$0 logs'." >&2
    exit 1
    ;;
  url) url ;;
  logs) docker logs -f "$NAME" ;;
  down)
    docker rm -f "$NAME" >/dev/null 2>&1 || true
    rm -rf "$STATE_DIR"
    ;;
  *)
    echo "usage: $0 up|url|logs|down" >&2
    exit 2
    ;;
esac
