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

# 检查 Aria 是否在跑. 顺序 (从准到弱):
# 1. pgrep Unity binary path — Aria.app 内嵌 Unity 进程在跑 = Aria 真活着
#    (osascript 'is running' 在 app 半死状态 e.g. WS 断时会返回 false 误杀)
# 2. fallback: osascript LaunchServices (Unity 路径未匹配时兜底)
# 3. 都 false → fall through 到 launch path
if pgrep -f "AriaFlutterBridge.app/Contents/MacOS/Arai" >/dev/null 2>&1; then
  exit 0
fi
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

# 3. 都没找到 → 拉 latest.json 拿到 download_url, 用浏览器 (open) 拉起下载
#    Aria.app 没装的用户首次跑 /aria-awake, 自动获得 zip 下载 (macOS Safari /
#    默认浏览器自动 unzip + 提示拖到 /Applications/). 跟 CC plugin install 一行
#    搭一起做到 "两条命令完整 onboarding" UX.
LATEST_URL="${ARIA_LATEST_URL:-https://aria-release.oss-cn-beijing.aliyuncs.com/latest.json}"
DOWNLOAD_URL=""
if command -v curl >/dev/null 2>&1 && command -v python3 >/dev/null 2>&1; then
  DOWNLOAD_URL="$(curl -fsSL --max-time 5 "$LATEST_URL" 2>/dev/null \
    | python3 -c "import json,sys; print(json.load(sys.stdin).get('download_url',''))" 2>/dev/null \
    || echo "")"
fi

if [ -n "$DOWNLOAD_URL" ]; then
  echo "[ensure-aria] Aria.app 未安装. 浏览器打开下载链接 → $DOWNLOAD_URL" >&2
  open "$DOWNLOAD_URL"
else
  echo "[ensure-aria] Aria.app 未安装且 latest.json 拉不到 ($LATEST_URL). 手动从 https://aria-release.oss-cn-beijing.aliyuncs.com/ 下载" >&2
fi
exit 0
