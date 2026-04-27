# aria-cc-plugin

[English](README.md) | [中文]

Claude Code plugin, 把 CC session 生命周期事件桥接到运行在 `http://127.0.0.1:8000` 的 **Aria 桌面形象** (`aria-agent` server).

刻意做得很轻: 声明式 `hooks/hooks.json` + 几个 bash 脚本. 不用 Node, 不用 SDK. CC 触发 hook → bash 重塑 JSON → `curl POST /events/cc` → 头像做出反应.

## 功能

- **Hook**: `SessionStart` / `UserPromptSubmit` / `Stop` / `StopFailure` / `PreToolUse` / `PostToolUse` / `Notification` / `PermissionRequest` → POST 事件元数据给 aria-agent.
- **Slash command**:
  - `/aria-wake` — 唤醒头像 (一次性 wake 事件)
  - `/aria-sleep` — 显式 sleep (CC 没 SessionEnd hook, 这是唯一显式入眠方式)
  - `/aria-mood <happy|tired|focused|...>` — 手动 mood 设置 (占位; aria-agent 还没接 `mood` reaction)
- **启动**: `SessionStart` 跑 `bin/ensure-aria.sh` — 探测 `:8000`; 如果 aria-agent 不在则后台 spawn.

## 隐私

只送事件**元数据** — `kind` / `outcome` / `tool_name` / `notification_kind`. 你的 prompt、工具输入输出**永不上送**.

## 安装

**推荐 — 走 marketplace**:

```
/plugin marketplace add LucasLawliet/aria-coder-buddy
/plugin install aria-cc-plugin@aria-coder-buddy
```

**或本地 clone**:

```bash
git clone https://github.com/LucasLawliet/aria-coder-buddy ~/Documents/Projects/aria-coder-buddy
# 在 CC session 里:
/plugin add ~/Documents/Projects/aria-coder-buddy/plugins/cc
```

或 `~/.claude/settings.json` 里直接配:

```json
{
  "plugins": [
    "~/Documents/Projects/aria-coder-buddy/plugins/cc"
  ]
}
```

## 配置

两个 env 都可选:

| 变量 | 默认值 | 用途 |
|---|---|---|
| `ARIA_AGENT_URL` | `http://127.0.0.1:8000` | plugin POST event 的目标地址 |
| `ARIA_AGENT_DIR` | (未设) | `aria` 仓 `Server/` 目录的绝对路径; 设了之后 `SessionStart` 会自动 spawn `aria-agent` |

## 依赖

- `PATH` 里要有 `bash`, `curl`, `jq`
- `aria-agent` 监听 `$ARIA_AGENT_URL` (或可由 `bin/ensure-aria.sh` 启动)

## 目录结构

```
.claude-plugin/plugin.json   manifest
hooks/hooks.json              CC hook → bin/post-event.sh 调度
commands/                     /aria-wake, /aria-sleep, /aria-mood
bin/post-event.sh             读 stdin JSON → curl POST /events/cc, 200ms timeout
bin/ensure-aria.sh            SessionStart 启动脚本
```

## 排查

- **头像没反应**: `curl http://127.0.0.1:8000/companion/state` — 没响应就手动跑 `bin/ensure-aria.sh`
- **hook 没触发**: 看 `~/.claude/logs/*`, 确认 `bin/*.sh` 有执行权限 (`chmod +x bin/*.sh`)
- **频繁超时**: aria-agent 应在 50ms 内返回 `204`; `--max-time 0.2` 超过会静默失败

## Heartbeat 策略

本 plugin **不发**周期性 heartbeat. aria-agent 用 *Strategy A* — 任何 cc event 都会 reset 它的 idle timer. CC 没有"定时触发"的 hook, 且让 plugin 后台跑 daemon 太脆弱. 当用户闲置时, 自然没 hook fire → 头像逐渐进入 `relax` / `session_lost`.

详见 `aria/docs/aria-cc-buddy/spec.md` § 5.2.
