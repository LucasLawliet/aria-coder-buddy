#!/usr/bin/env bash
# /aria-model handler: tell Aria desktop app to open character editor (捏人界面).
# Used by commands/aria-model.md (CC skill loader).
set -u

URL="${ARIA_AGENT_URL:-http://127.0.0.1:8000}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Ensure app running first
"$SCRIPT_DIR/ensure-aria.sh" >&2 || true

# Tell server to open character_editor page (server WebSocket pushes to dart shell)
RESP=$(curl -s --max-time 2 -X POST "$URL/events/cc/open_character_editor" \
    -H "Content-Type: application/json" \
    -d '{}' 2>&1) || true

if [ -z "$RESP" ] || echo "$RESP" | grep -q "error\|Error\|Failed"; then
    echo "Failed to open character editor. Make sure Aria.app is running and aria-agent server is up." >&2
    echo "Server response: $RESP" >&2
    exit 1
fi

echo "✓ 捏人界面已打开"
