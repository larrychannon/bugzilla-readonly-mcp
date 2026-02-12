#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  ./test-local.sh --bugzilla-url <URL> --api-key <KEY>

Options:
  --bugzilla-url URL   Bugzilla base URL (e.g. https://bugzilla.example.com)
  --api-key KEY        Bugzilla API key
  -h, --help           Show this help

You can also set:
  BUGZILLA_URL, BUGZILLA_API_KEY
EOF
}

BUGZILLA_URL="${BUGZILLA_URL:-}"
API_KEY="${BUGZILLA_API_KEY:-}"
HOST="${MCP_HOST:-127.0.0.1}"
PORT="${MCP_PORT:-8000}"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --bugzilla-url)
      BUGZILLA_URL="${2:-}"
      shift 2
      ;;
    --api-key)
      API_KEY="${2:-}"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      usage
      exit 1
      ;;
  esac
done

if [[ -z "$BUGZILLA_URL" ]]; then
  read -r -p "Enter Bugzilla URL: " BUGZILLA_URL
fi
if [[ -z "$API_KEY" ]]; then
  read -r -s -p "Enter Bugzilla API key: " API_KEY
  echo
fi

if [[ -z "$BUGZILLA_URL" || -z "$API_KEY" ]]; then
  echo "Bugzilla URL and API key are required." >&2
  exit 1
fi

echo "==> Sync dependencies"
uv sync --extra dev

echo "==> Run unit tests"
PYTHONPATH=src uv run pytest -q

echo "==> Start MCP server (HTTP) at http://${HOST}:${PORT}/mcp"
PYTHONPATH=src uv run bugzilla-readonly-mcp \
  --transport http \
  --bugzilla-server "$BUGZILLA_URL" \
  --host "$HOST" \
  --port "$PORT" &
SERVER_PID=$!

cleanup() {
  if kill -0 "$SERVER_PID" >/dev/null 2>&1; then
    kill "$SERVER_PID" >/dev/null 2>&1 || true
    wait "$SERVER_PID" 2>/dev/null || true
  fi
}
trap cleanup EXIT

sleep 2

echo "==> MCP smoke test: server_url"
SERVER_URL_RESPONSE="$(curl -fsS -X POST "http://${HOST}:${PORT}/mcp" \
  -H "ApiKey: ${API_KEY}" \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","method":"tools/call","params":{"name":"server_url","arguments":{}},"id":1}')"
echo "$SERVER_URL_RESPONSE"

echo "==> MCP smoke test: bug_info(id=1)"
BUG_INFO_RESPONSE="$(curl -fsS -X POST "http://${HOST}:${PORT}/mcp" \
  -H "ApiKey: ${API_KEY}" \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","method":"tools/call","params":{"name":"bug_info","arguments":{"id":1}},"id":2}')"
echo "$BUG_INFO_RESPONSE"

echo "==> Done"
