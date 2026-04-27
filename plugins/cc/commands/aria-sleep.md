---
description: Sleep the Aria desktop avatar (avatar plays farewell, process stays warm)
allowed-tools: Bash(curl:*)
---

!`curl -s --max-time 0.2 -X POST "${ARIA_AGENT_URL:-http://127.0.0.1:8000}/events/cc" -H 'Content-Type: application/json' -d '{"kind":"sleep","payload":{}}' >/dev/null 2>&1 ; echo "sleep dispatched"`

Aria avatar sleep event sent. No response needed — just acknowledge briefly.
