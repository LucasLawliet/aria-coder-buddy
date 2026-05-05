#!/usr/bin/env bash
# /aria-awake handler: ensure Aria.app running, then send wake event.
# Used by commands/aria-awake.md (CC skill loader).
set -u

PORT="${ARIA_AGENT_PORT:-8000}"
URL="${ARIA_AGENT_URL:-http://127.0.0.1:$PORT}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Probe :PORT — already running, skip launch
if ! (echo > /dev/tcp/127.0.0.1/$PORT) 2>/dev/null; then
  "$SCRIPT_DIR/ensure-aria.sh" >&2 || true
fi

# Fire wake event, best-effort. App may still be booting; that's OK —
# subsequent CC events (UserPromptSubmit etc) will reset state.
curl -s --max-time 0.5 -X POST "$URL/events/cc" \
  -H 'Content-Type: application/json' \
  -d '{"kind":"wake","payload":{}}' >/dev/null 2>&1 || true

echo "awake dispatched"
