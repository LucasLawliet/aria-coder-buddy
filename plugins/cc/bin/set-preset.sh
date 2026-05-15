#!/usr/bin/env bash
# aria-cc-plugin · set-preset — 把 builtin preset 切到运行中的 aria.app.
# 用法: set-preset.sh <preset_name> [<category>]
#   preset_name: maomao | fulilian | aniya | ... (见 skills/aria-pick-character/SKILL.md)
#   category:    builtin (default) | custom

set -euo pipefail

PRESET="${1:-}"
CATEGORY="${2:-builtin}"

if [ -z "$PRESET" ]; then
  echo "usage: set-preset.sh <preset_name> [<category>]" >&2
  exit 2
fi

# aria-agent 监听本地 127.0.0.1:8000. aria.app 没启动时 connection refused.
RESP_CODE=$(curl -sS -o /dev/null -w "%{http_code}" -X POST \
  http://127.0.0.1:8000/events/cc/load_preset \
  -H "Content-Type: application/json" \
  -d "{\"preset_name\": \"$PRESET\", \"category\": \"$CATEGORY\"}" \
  --connect-timeout 3 --max-time 5 2>/dev/null || echo "000")

if [ "$RESP_CODE" = "204" ]; then
  echo "ok: switched to $PRESET ($CATEGORY)"
  exit 0
fi

if [ "$RESP_CODE" = "000" ]; then
  echo "error: aria.app/agent 没响应 (是否在运行?)" >&2
  exit 1
fi

echo "error: aria-agent HTTP $RESP_CODE — preset=$PRESET" >&2
exit 1
