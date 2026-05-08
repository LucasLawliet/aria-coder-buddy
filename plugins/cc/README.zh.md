# aria-cc-plugin

[English](README.md) | [中文]

Claude Code plugin, 把 CC session 生命周期事件桥接到运行在 `http://127.0.0.1:8000` 的 **Aria 桌面形象** (`aria-agent` server).

刻意做得很轻: 声明式 `hooks/hooks.json` + 几个 bash 脚本. 不用 Node, 不用 SDK. CC 触发 hook → bash 重塑 JSON → `curl POST /events/cc` → 头像做出反应.

## 功能

- **Hook**: `SessionStart` / `UserPromptSubmit` / `Stop` / `StopFailure` / `PreToolUse` / `PostToolUse` / `Notification` / `PermissionRequest` → POST 事件元数据给 aria-agent.
- **Slash command** (唯一控制 app 生命周期的入口):
  - `/aria-awake` — (1) 后台 git pull 自更新 plugin, (2) 拉起 Aria.app, 没装则**自动打开浏览器跳官方下载页**, (3) 发 wake 事件
  - `/aria-sleep` — 发道别事件让头像播告别动画, 等 1s 后 graceful quit Aria.app
- **Hook 行为**: Aria.app 没在跑时, 其它 hook (Stop / UserPromptSubmit / PreToolUse...) 都是 `curl --max-time 0.2` 打到关闭的端口, 静默 timeout. 用户在 CC 里输入任何内容**都不会**拉起 Aria.app — 只有 `/aria-awake` 会.
- **自更新**: `/aria-awake` 后台 `git pull` marketplace mirror (`~/.claude/plugins/marketplaces/aria-coder-buddy`). 新 plugin 代码下次 CC session 启动时生效, 不打断当前 session.

## 隐私

Plugin 上送的是事件**元数据** (`kind` / `outcome` / `tool_name` / `notification_kind`); `Stop` / `StopFailure` 时还会带 CC transcript `.jsonl` 的**本地路径**. transcript 文件本身不离开你的机器 — `aria-agent` (也跑在本地) 自己读, 把 tail 喂给 Anthropic API 让 Aria 角色说一句贴当前任务的话. 你的 prompt、工具输入输出 plugin 自己不直接 POST.

如果不开 Aria 桌面应用, `:8000` 没人监听 — plugin 所有 POST 都 `--max-time 0.2` 静默超时, **不消耗任何 token**.

## 快速开始

**1. 在 Claude Code 里装 plugin**:

```
/plugin marketplace add LucasLawliet/aria-coder-buddy
/plugin install aria-cc-plugin@aria-coder-buddy
```

**2. 确保 `aria-agent` 跑在 `:8000`**.

最省事 — 设 `ARIA_AGENT_DIR`, plugin 自动帮你 spawn:

```bash
# 写到 ~/.zshrc 或 ~/.bashrc:
export ARIA_AGENT_DIR=/path/to/aria/Server
```

下次开 CC session, `SessionStart` 跑 `bin/ensure-aria.sh` → 探 `:8000` → 没在就 `cd $ARIA_AGENT_DIR && nohup uv run aria-agent start &`. 日志 `/tmp/aria-agent.log`.

也可以手动起:
```bash
cd /path/to/aria/Server && uv run aria-agent start
```

**3. 正常用 Claude Code** — 每次 prompt / tool / stop 都触发 hook → POST 到 `:8000`. 头像自动反应, 不需要做别的.

**4. Slash command** (唯一控制 app 生命周期的方式):
- `/aria-awake` — Aria.app 没开就拉起来, 然后发 wake 事件
- `/aria-sleep` — graceful quit (头像播道别动画, 进程退出)

Aria.app **没在跑**时, 普通 hook (Stop / UserPromptSubmit...) 打到关闭的 `:8000` 静默 timeout — 不会偷偷拉起 app. 想让她出来用 `/aria-awake`.

## 备选安装 (本地 clone, 不走 marketplace)

```bash
git clone https://github.com/LucasLawliet/aria-coder-buddy ~/Documents/Projects/aria-coder-buddy
# 在 CC session 里:
/plugin add ~/Documents/Projects/aria-coder-buddy/plugins/cc
```

或 `~/.claude/settings.json`:
```json
{ "plugins": ["~/Documents/Projects/aria-coder-buddy/plugins/cc"] }
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
commands/                     /aria-awake, /aria-sleep (skill 格式)
bin/post-event.sh             读 stdin JSON → curl POST /events/cc, 200ms timeout
bin/ensure-aria.sh            SessionStart 启动脚本 (探 :8000, 拉起 Aria.app)
bin/awake.sh                  /aria-awake 入口: ensure-aria + POST wake
bin/sleep.sh                  /aria-sleep 入口: POST sleep
```

## 排查

- **头像没反应**: `curl http://127.0.0.1:8000/companion/state` — 没响应就手动跑 `bin/ensure-aria.sh`
- **hook 没触发**: 看 `~/.claude/logs/*`, 确认 `bin/*.sh` 有执行权限 (`chmod +x bin/*.sh`)
- **频繁超时**: aria-agent 应在 50ms 内返回 `204`; `--max-time 0.2` 超过会静默失败

## Heartbeat 策略

本 plugin **不发**周期性 heartbeat. aria-agent 用 *Strategy A* — 任何 cc event 都会 reset 它的 idle timer. CC 没有"定时触发"的 hook, 且让 plugin 后台跑 daemon 太脆弱. 当用户闲置时, 自然没 hook fire → 头像逐渐进入 `relax` / `session_lost`.

详见 `aria/docs/aria-cc-buddy/spec.md` § 5.2.
