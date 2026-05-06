#!/usr/bin/env bash
# /aria-sleep handler: graceful sleep + quit Aria.app + sweep aria-agent zombie.
# 1. POST sleep event (Unity 收到后可以播道别动画 / 收尾)
# 2. 让 app 1 秒处理完, 然后 osascript graceful quit (Flutter shell + Unity)
# 3. Sweep launcher spawn 的 uvicorn 子进程 — osascript quit 不一定带走它,
#    残留会占 :8000, 让下次 awake 误判 / 让 CC hooks 还以为 server 活着.
# Used by commands/aria-sleep.md (CC skill loader).
set -u

ARIA_BUNDLE_ID="${ARIA_BUNDLE_ID:-com.sensebeing.aria}"
URL="${ARIA_AGENT_URL:-http://127.0.0.1:8000}"
PORT="${ARIA_AGENT_PORT:-8000}"

# 1. 通知 server 进 sleep state, 触发道别动画 (best-effort, app 没在跑就静默)
curl -s --max-time 0.2 -X POST "$URL/events/cc" \
  -H 'Content-Type: application/json' \
  -d '{"kind":"sleep","payload":{}}' >/dev/null 2>&1 || true

# 2. 给 app 1 秒播完动画, 然后 graceful quit (app 没在跑 osascript 也 noop)
sleep 1
if command -v osascript >/dev/null 2>&1; then
  osascript -e 'tell application id "'"$ARIA_BUNDLE_ID"'" to quit' 2>/dev/null || true
fi

# 3. Sweep aria-agent zombie: launcher 启动的 uvicorn 子进程 detach 后跟 GUI
#    脱钩, osascript quit Flutter shell 不一定能带走. 直接挑 :8000 上的
#    listener PID kill (lsof 找 LISTEN socket owner). 静默, app 没跑也 noop.
if command -v lsof >/dev/null 2>&1; then
  ZOMBIE_PIDS=$(lsof -ti :"$PORT" -sTCP:LISTEN 2>/dev/null || true)
  for pid in $ZOMBIE_PIDS; do
    kill "$pid" 2>/dev/null || true
  done
fi

echo "sleep dispatched"
