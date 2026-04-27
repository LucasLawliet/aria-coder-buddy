#!/usr/bin/env bash
# SessionStart bootstrap: probe aria-agent on :8000; if absent, attempt to
# spawn it from $ARIA_AGENT_DIR. Failures are silenced — CC must continue
# even when the avatar pipeline cannot start.
#
# Usage (from hooks.json):
#   ${CLAUDE_PLUGIN_ROOT}/bin/ensure-aria.sh
set -u

PORT="${ARIA_AGENT_PORT:-8000}"

# Probe via bash builtin /dev/tcp (no nc dependency). Already running → done.
if (echo > /dev/tcp/127.0.0.1/$PORT) 2>/dev/null; then
  exit 0
fi

DIR="${ARIA_AGENT_DIR:-}"
if [ -z "$DIR" ] || [ ! -d "$DIR" ]; then
  echo "[aria-cc-plugin] aria-agent not on :$PORT; set ARIA_AGENT_DIR to auto-spawn." >&2
  exit 0
fi

# Spawn detached so CC isn't blocked by its lifetime.
(
  cd "$DIR" || exit 0
  nohup uv run aria-agent start >/tmp/aria-agent.log 2>&1 &
) </dev/null >/dev/null 2>&1
disown 2>/dev/null || true

exit 0
