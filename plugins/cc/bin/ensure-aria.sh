#!/usr/bin/env bash
# SessionStart bootstrap: 检查 Aria GUI 是否在前台, 没就启动 Aria.app.
# Aria.app 启动时**自身会 spawn aria-agent + Unity binary** (launcher 内部逻辑),
# 不要让 plugin 重复 spawn aria-agent.
#
# 启动策略 (Flutter Claude 提供, 跟 Aria distribution 模型对齐):
# 1. 优先 macOS LaunchServices `open -b com.sensebeing.aria` — 用户至少 launch
#    过一次 Aria 后, LaunchServices 已注册 bundle id, 这条最稳
# 2. Fallback 常见路径 (/Applications/, ~/Applications/, ~/Desktop/, ~/Downloads/)
# 3. 都失败 → 静默 (用户首次安装且 Aria 没 launch 过 + 放罕见路径). CC 体验
#    > 头像保真度
#
# Usage (from hooks.json): ${CLAUDE_PLUGIN_ROOT}/bin/ensure-aria.sh
set -u

ARIA_BUNDLE_ID="${ARIA_BUNDLE_ID:-com.sensebeing.aria}"

# 直接问 macOS LaunchServices "Aria GUI 在不在" — 比 :8000 端口探测可靠.
# (旧逻辑只 probe 端口, 但 zombie aria-agent 进程不带 GUI 也会占 :8000 →
# skip launch → 用户看到 "Aria 不在".) osascript 不在 PATH 时降级为 0/1 noop.
if command -v osascript >/dev/null 2>&1; then
  APP_RUNNING="$(osascript -e 'application id "'"$ARIA_BUNDLE_ID"'" is running' 2>/dev/null || echo "")"
  if [ "$APP_RUNNING" = "true" ]; then
    exit 0
  fi
fi

# 1. LaunchServices by bundle id (推荐路径, 用户至少打开过一次 Aria 就 work)
if open -b "$ARIA_BUNDLE_ID" 2>/dev/null; then
  echo "[ensure-aria] launched via bundle id: $ARIA_BUNDLE_ID" >&2
  exit 0
fi

# 2. Fallback 常见路径 (大小写都试)
for path in \
  "/Applications/aria.app" \
  "/Applications/Aria.app" \
  "$HOME/Applications/aria.app" \
  "$HOME/Applications/Aria.app" \
  "$HOME/Desktop/aria.app" \
  "$HOME/Desktop/Aria.app" \
  "$HOME/Downloads/aria.app" \
  "$HOME/Downloads/Aria.app"; do
  if [ -d "$path" ]; then
    open "$path"
    echo "[ensure-aria] launched: $path" >&2
    exit 0
  fi
done

# 3. 都没找到 — 静默 (CC 体验优先)
echo "[ensure-aria] Aria.app 未找到 (bundle id 未注册 + 常见路径都没). 用户需手动打开一次 Aria 或用 ARIA_BUNDLE_ID env 指定" >&2
exit 0
