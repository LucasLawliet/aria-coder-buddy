#!/usr/bin/env bash
# /aria-sleep handler: graceful sleep + quit Aria.app.
# 1. POST sleep event (Unity 收到后可以播道别动画 / 收尾)
# 2. 让 app 1 秒处理完, 然后 osascript graceful quit
# Used by commands/aria-sleep.md (CC skill loader).
set -u

ARIA_BUNDLE_ID="${ARIA_BUNDLE_ID:-com.sensebeing.aria}"
URL="${ARIA_AGENT_URL:-http://127.0.0.1:8000}"

# 1. 通知 server 进 sleep state, 触发道别动画 (best-effort, app 没在跑就静默)
curl -s --max-time 0.2 -X POST "$URL/events/cc" \
  -H 'Content-Type: application/json' \
  -d '{"kind":"sleep","payload":{}}' >/dev/null 2>&1 || true

# 2. 给 app 1 秒播完动画, 然后 graceful quit (app 没在跑 osascript 也 noop)
sleep 1
if command -v osascript >/dev/null 2>&1; then
  osascript -e 'tell application id "'"$ARIA_BUNDLE_ID"'" to quit' 2>/dev/null || true
fi

echo "sleep dispatched"
