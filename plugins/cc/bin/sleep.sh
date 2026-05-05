#!/usr/bin/env bash
# /aria-sleep handler: tell Aria to play farewell + drift to sleep state.
# Used by commands/aria-sleep.md (CC skill loader).
set -u

URL="${ARIA_AGENT_URL:-http://127.0.0.1:8000}"

curl -s --max-time 0.2 -X POST "$URL/events/cc" \
  -H 'Content-Type: application/json' \
  -d '{"kind":"sleep","payload":{}}' >/dev/null 2>&1 || true

echo "sleep dispatched"
