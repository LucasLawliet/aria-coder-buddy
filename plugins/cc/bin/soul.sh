#!/usr/bin/env bash
# /aria-soul handler: get/set Aria's soul (system prompt / persona — single
# text blob, matches server schema {content, is_default}).
# Used by commands/aria-soul.md (CC skill loader).
#
# Server endpoints (aria-agent FastAPI on :8000):
#   GET  /soul       → {"content": "...", "is_default": bool}
#   PUT  /soul       body {"content": "..."} → save text override
#   POST /soul/reset → delete override, fall back to default
#
# Usage:
#   soul.sh get        # print current soul JSON {content, is_default}
#   soul.sh set <text> # update soul text (raw, not JSON — script wraps it)
#   soul.sh reset      # restore default soul
set -u

URL="${ARIA_AGENT_URL:-http://127.0.0.1:8000}"
ACTION="${1:-get}"

case "$ACTION" in
    get)
        RESP=$(curl -s --max-time 2 "$URL/soul" 2>&1) || true
        if [ -z "$RESP" ]; then
            echo "Failed to fetch soul. Is aria-agent server running (port :8000)? Try /aria-awake first." >&2
            exit 1
        fi
        echo "$RESP"
        ;;
    set)
        if [ -z "${2:-}" ]; then
            echo "Usage: soul.sh set <new soul text>" >&2
            exit 1
        fi
        # Wrap raw text in JSON {"content": "..."} — escape quotes + newlines
        BODY=$(python3 -c "import json,sys; print(json.dumps({'content': sys.argv[1]}))" "$2")
        RESP=$(curl -s --max-time 2 -X PUT "$URL/soul" \
            -H "Content-Type: application/json" \
            -d "$BODY" 2>&1) || true
        if [ -z "$RESP" ] || echo "$RESP" | grep -qiE "error|fail"; then
            echo "Failed to update soul. Server response: $RESP" >&2
            exit 1
        fi
        echo "✓ soul updated. Aria 下次回复会用新 soul."
        ;;
    reset)
        RESP=$(curl -s --max-time 2 -X POST "$URL/soul/reset" 2>&1) || true
        if [ -z "$RESP" ] || echo "$RESP" | grep -qiE "error|fail"; then
            echo "Failed to reset soul. Server response: $RESP" >&2
            exit 1
        fi
        echo "✓ soul reset to default."
        ;;
    *)
        echo "Unknown action '$ACTION'. Use 'get' / 'set <text>' / 'reset'." >&2
        exit 1
        ;;
esac
