#!/usr/bin/env bash
# /aria-awake handler: ensure Aria.app running, then send wake event.
# Used by commands/aria-awake.md (CC skill loader).
#
# 不再用 :8000 端口探测 skip launch 的逻辑 — zombie aria-agent 会占着 8000
# 但 GUI 已经被 /aria-sleep 关掉 (sleep 1.0 + 0.1.5 osascript quit 不一定带走
# launcher 启 spawn 的 uvicorn 子进程). 让 ensure-aria.sh 自己 pgrep Arai
# 判断 GUI 是否真活, 这是唯一权威信号.
set -u

URL="${ARIA_AGENT_URL:-http://127.0.0.1:8000}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

"$SCRIPT_DIR/ensure-aria.sh" >&2 || true

# Fire wake event, best-effort. App may still be booting; that's OK —
# subsequent CC events (UserPromptSubmit etc) will reset state.
curl -s --max-time 0.5 -X POST "$URL/events/cc" \
  -H 'Content-Type: application/json' \
  -d "{\"kind\":\"wake\",\"payload\":{\"cwd\":\"$PWD\"}}" >/dev/null 2>&1 || true

echo "awake dispatched"
