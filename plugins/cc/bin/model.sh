#!/usr/bin/env bash
# /aria-model handler: tell Aria desktop app to open character editor (捏人界面).
# Used by commands/aria-model.md (CC skill loader).
set -u

URL="${ARIA_AGENT_URL:-http://127.0.0.1:8000}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Ensure app running first
"$SCRIPT_DIR/ensure-aria.sh" >&2 || true

# Tell server to open character_editor page (server WebSocket pushes to dart shell).
# Endpoint returns 204 No Content on success — empty body is normal, 之前用
# `[ -z "$RESP" ]` 误判 204 为失败. 改用 HTTP code 判断成功.
HTTP_CODE=$(curl -sS -o /dev/null -w "%{http_code}" --max-time 3 -X POST \
    "$URL/events/cc/open_character_editor" \
    -H "Content-Type: application/json" \
    -d '{}' 2>/dev/null || echo "000")

if [ "$HTTP_CODE" = "204" ]; then
    echo "✓ 捏人界面已打开"
    exit 0
fi

if [ "$HTTP_CODE" = "000" ]; then
    echo "Aria.app / aria-agent 没响应 (是否在运行?)" >&2
    exit 1
fi

echo "aria-agent 返回 HTTP $HTTP_CODE — 检查 Aria.app 是否正常" >&2
exit 1
