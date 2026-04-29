#!/usr/bin/env bash
# Forward a CC hook event to aria-agent. Reads CC's hook JSON on stdin,
# reshapes to aria-agent /events/cc schema, fires fire-and-forget POST
# capped at 200ms wall time. Errors are silenced — CC user experience
# trumps avatar fidelity.
#
# Usage (from hooks.json):
#   ${CLAUDE_PLUGIN_ROOT}/bin/post-event.sh <kind>
set -u

KIND="${1:-unknown}"
ENDPOINT="${ARIA_AGENT_URL:-http://127.0.0.1:8000}/events/cc"

command -v curl >/dev/null 2>&1 || exit 0
command -v jq   >/dev/null 2>&1 || exit 0

INPUT=""
if [ ! -t 0 ]; then
  INPUT=$(cat)
fi

build_payload() {
  if [ -z "$INPUT" ]; then
    # No stdin (rare). For wake we still want cwd from $PWD.
    if [ "$KIND" = "wake" ]; then
      echo "{\"cwd\":\"$PWD\"}"
    else
      echo '{}'
    fi
    return
  fi
  case "$KIND" in
    wake)
      # SessionStart stdin carries .cwd per Anthropic hook spec; fallback to $PWD.
      echo "$INPUT" | jq -c --arg pwd "$PWD" '{cwd: (.cwd // $pwd)}' 2>/dev/null \
        || echo "{\"cwd\":\"$PWD\"}" ;;
    stop)
      echo "$INPUT" | jq -c '{outcome: "success", duration_ms: (.duration_ms // null)}' 2>/dev/null \
        || echo '{"outcome":"success"}' ;;
    stop_failure)
      echo "$INPUT" | jq -c '{outcome: "error", duration_ms: (.duration_ms // null), error_summary: (.error // null)}' 2>/dev/null \
        || echo '{"outcome":"error"}' ;;
    pre_tool_use|post_tool_use)
      echo "$INPUT" | jq -c '{tool_name: (.tool_name // "unknown")}' 2>/dev/null \
        || echo '{}' ;;
    notification)
      echo '{"notification_kind":"general"}' ;;
    permission_request)
      echo "$INPUT" | jq -c '{tool_name: (.tool_name // null)}' 2>/dev/null \
        || echo '{}' ;;
    *)
      echo '{}' ;;
  esac
}

SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // ""' 2>/dev/null || echo "")
PAYLOAD=$(build_payload)

BODY=$(jq -nc \
  --arg sid "$SESSION_ID" \
  --arg kind "$KIND" \
  --argjson payload "$PAYLOAD" \
  '{session_id: $sid, kind: $kind, payload: $payload}' 2>/dev/null) || exit 0

# Fire and forget — 200ms wall budget, output discarded. aria-agent stamps ts.
( curl -s --max-time 0.2 -X POST "$ENDPOINT" \
    -H "Content-Type: application/json" \
    -d "$BODY" >/dev/null 2>&1 ) </dev/null >/dev/null 2>&1 &
disown 2>/dev/null || true

exit 0
