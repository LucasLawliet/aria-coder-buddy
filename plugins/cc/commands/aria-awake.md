---
description: Awaken the Aria desktop avatar (launches the app if not running, then fires wake event)
allowed-tools: Bash
---

!`${CLAUDE_PLUGIN_ROOT}/bin/ensure-aria.sh ; curl -s --max-time 0.5 -X POST "${ARIA_AGENT_URL:-http://127.0.0.1:8000}/events/cc" -H 'Content-Type: application/json' -d "{\"kind\":\"wake\",\"payload\":{\"cwd\":\"$PWD\"}}" >/dev/null 2>&1 ; echo "awake dispatched"`

Aria avatar awake — app launched (or already running) and wake event sent. No further response needed.
