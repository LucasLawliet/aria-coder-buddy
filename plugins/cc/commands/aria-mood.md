---
description: Manually set the Aria avatar mood (happy / tired / focused / curious / ...)
allowed-tools: Bash(curl:*)
argument-hint: <mood>
---

!`MOOD="$ARGUMENTS"; if [ -z "$MOOD" ]; then echo "usage: /aria-mood <mood>"; else BODY=$(printf '{"kind":"mood","payload":{"mood":"%s"}}' "$MOOD"); curl -s --max-time 0.2 -X POST "${ARIA_AGENT_URL:-http://127.0.0.1:8000}/events/cc" -H 'Content-Type: application/json' -d "$BODY" >/dev/null 2>&1 ; echo "mood set: $MOOD"; fi`

Aria avatar mood event sent. No response needed — just acknowledge briefly.

Note: aria-agent currently has no `kind=mood` reaction wired up; this is a placeholder for future mood-injection work (see spec § 12).
