#!/usr/bin/env bash
# /aria-soul handler: get/set Aria's soul (system prompt / persona / memory).
# Used by commands/aria-soul.md (CC skill loader).
#
# Usage:
#   soul.sh get       # print current soul as JSON
#   soul.sh set <json> # update soul (json string with prompt/persona/memory fields)
set -u

URL="${ARIA_AGENT_URL:-http://127.0.0.1:8000}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

ACTION="${1:-get}"

case "$ACTION" in
    get)
        # Fetch current soul. Server returns JSON {prompt, persona, memory}.
        RESP=$(curl -s --max-time 2 "$URL/soul" 2>&1) || true
        if [ -z "$RESP" ]; then
            echo "Failed to fetch soul. Is aria-agent server running (port :8000)?" >&2
            exit 1
        fi
        echo "$RESP"
        ;;
    set)
        if [ -z "${2:-}" ]; then
            echo "Usage: soul.sh set '<json>'" >&2
            exit 1
        fi
        RESP=$(curl -s --max-time 2 -X PUT "$URL/soul" \
            -H "Content-Type: application/json" \
            -d "$2" 2>&1) || true
        if [ -z "$RESP" ] || echo "$RESP" | grep -q "error\|Error"; then
            echo "Failed to update soul. Server response: $RESP" >&2
            exit 1
        fi
        echo "✓ soul updated. Aria 下一次回复会用新的 soul."
        ;;
    *)
        echo "Unknown action '$ACTION'. Use 'get' or 'set'." >&2
        exit 1
        ;;
esac
