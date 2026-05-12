# aria-coder-buddy

[English](README.md) | [中文]

把 AI coding agent (Claude Code / OpenAI Codex / Kimi / ...) 桥接到 **Aria** 桌面虚拟形象 — 让 VRM 角色实时回应你的写代码过程: 你敲提示她在思考, 任务完成她在欢呼, 你太久没动她跑去看书发呆.

## ⚡ 一键安装 — 复制这段贴进 Claude Code

```
按照 https://github.com/LucasLawliet/aria-coder-buddy/blob/main/README.zh.md
的「首次安装」段落, 帮我装 Aria 桌面虚拟形象.
```

Claude Code 会 fetch README, 按 install 步骤走 (下 .app、引导你敲 2 条 slash command、首次启动). 装完之后只要 `/aria-awake` 就能拉她回来.

## 状态

| Agent | 路径 | 状态 |
|---|---|---|
| Claude Code | `plugins/cc/` | ✅ 可用 (v0.1.7) |
| OpenAI Codex CLI | `plugins/codex/` | ⏳ 计划中 |
| Kimi / Moonshot | `plugins/kimi/` | ⏳ 计划中 |

每个子目录是一个独立的、对应 agent plugin 格式的 plugin. 所有 plugin 都 POST 到同一后端 — `aria-agent` server, 它是 **Aria 桌面应用** 内置的 Python 服务 (macOS Apple Silicon).

## 整体架构

> 下图为 ASCII 架构图, 为对齐用纯英文标注. 三个 box 对应: AI agent 进程 (CC / Codex / Kimi 等) → aria-agent server (FastAPI on :8000) → Aria 桌面应用 (Unity + Flutter).

```
┌─────────────┐  hook events    ┌─────────────┐  WebSocket    ┌──────────────┐
│ AI agent    │ ──────────────► │ aria-agent  │ ────────────► │ Aria desktop │
│ (CC, Codex, │  POST /events/* │ (FastAPI    │  behavior     │ (Unity +     │
│  Kimi, ...) │                 │  on :8000)  │  command      │  Flutter)    │
└─────────────┘                 └─────────────┘               └──────────────┘
       ▲                              │
       │ slash commands               │ HTTPS (token from CC OAuth or env)
       │ (user-triggered)             ▼
                              ┌──────────────────┐
                              │ Anthropic API    │
                              │ (random speech)  │
                              └──────────────────┘
```

`aria-agent` 是大脑: 它追踪 companion state, 跑 behavior engine, 决定头像该做什么, 通过 WebSocket 把命令推给桌面端. 这个仓里每个 plugin 都是个轻量适配器, 把宿主 agent 的事件转发出去.

## 隐私

Plugin 转发的是**事件元数据** (`kind` / `outcome` / `tool_name` / `notification_kind`); `Stop` / `StopFailure` 时还会带 agent transcript 文件的**本地路径**, 让同样跑在你机器上的 `aria-agent` 自己读, 给 avatar 的聊天气泡生一句贴当前任务的话. transcript 文件本身只在本机进程间传, 不会被 plugin 自己 POST 到远端. 你的 prompt、工具输入输出 plugin 自己**永不上送**.

如果不开 Aria 桌面应用, `:8000` 没人监听 — plugin 所有 POST 都静默超时, **不消耗任何 token**.

## 首次安装 (复制下面整段贴进 Claude Code)

最省事路径 — 把这段贴进 Claude Code 对话, 它会带你下 Aria 桌面应用 + 装 plugin + 首次启动. 之后所有 session 都直接 `/aria-awake`.

```
帮我从 https://github.com/LucasLawliet/aria-coder-buddy 装 Aria 桌面 avatar +
aria-coder-buddy plugin. 按顺序做:

0. **先检查旧版 + 僵尸进程** (装新版前必须做, 否则 cp 会因为 "Resource busy" 失败):
   - ls -la /Applications/aria.app 2>/dev/null  (有装过吗)
   - pgrep -fl "/aria\.app|uvicorn main:app|AriaFlutterBridge|aria-agent"  (有僵尸进程吗)
   - 报告: 旧版本号 + 残留进程列表.
   - 有旧版的话清掉:
     * osascript -e 'tell application id "com.sensebeing.aria" to quit' 2>/dev/null || true
     * sleep 2 && pkill -9 -f "/aria\.app|uvicorn main:app|AriaFlutterBridge|aria-agent" 2>/dev/null || true
     * rm -rf /Applications/aria.app
     * rm -rf "$HOME/Library/Caches/Aria"  (老 Unity bundles, ~1GB; 会重下)
     * rm -rf "$HOME/Library/Application Support/Aria"  (老 aria-agent runtime)
   - 验证清干净: ls /Applications/aria.app 2>&1 应该报 "No such file"

1. 下载 + 安装 Aria.app (macOS Apple Silicon, ~250 MB):
   - 拿 URL: gh release view --repo LucasLawliet/aria-coder-buddy --json assets --jq '.assets[] | select(.name|startswith("aria-")) | .browser_download_url'
   - curl -L -o /tmp/aria.zip <url>
   - mkdir -p /tmp/aria-extract && unzip -oq /tmp/aria.zip -d /tmp/aria-extract/
   - cp -R /tmp/aria-extract/aria.app /Applications/aria.app
   - xattr -dr com.apple.quarantine /Applications/aria.app 2>/dev/null || true
   - 验证: defaults read /Applications/aria.app/Contents/Info CFBundleShortVersionString
   - 告诉我装的是哪个版本.

2. 告诉我下面这两条 slash command 在 Claude Code 里手敲 (你不能代我敲):
     /plugin marketplace add LucasLawliet/aria-coder-buddy
     /plugin install aria-cc-plugin@aria-coder-buddy
   等我确认两条都成功了.

3. 我确认后, 帮我验证 plugin 装好了 — 查 ~/.claude/plugins/installed_plugins.json
   看有没有 "aria-cc-plugin@aria-coder-buddy" entry.

4. 首次启动 Aria 桌面应用:
     open -b com.sensebeing.aria
   第一次启动会下载 ~400 MB 的 3D 角色资源 (90-120 秒), 慢. 告诉我等角色出现.

5. 角色出现后, 告诉我以后只要在 Claude Code 里敲 /aria-awake 就能拉她回来,
   /aria-sleep 让她去睡 (进程保活下次拉起更快).
```

装完之后 **所有后续 session** — 只要 `/aria-awake` 她就回来.

### 手动 (不走上面 prompt)

```
# 1. 下载 + 安装 Aria.app
gh release download --repo LucasLawliet/aria-coder-buddy --pattern 'aria-*.zip' --output /tmp/aria.zip
mkdir -p /tmp/aria-extract && unzip -oq /tmp/aria.zip -d /tmp/aria-extract/
rm -rf /Applications/aria.app && cp -R /tmp/aria-extract/aria.app /Applications/aria.app
xattr -dr com.apple.quarantine /Applications/aria.app 2>/dev/null || true

# 2. 在 Claude Code 里敲:
/plugin marketplace add LucasLawliet/aria-coder-buddy
/plugin install aria-cc-plugin@aria-coder-buddy

# 3. 首次启动:
open -b com.sensebeing.aria
# (等 ~2 分钟首次下 3D 资源)
```

之后想升级 plugin:

```
/plugin marketplace update aria-coder-buddy
```

Aria 桌面应用自己会原地升级 (启动时检查 GitHub releases, 有新版本自动下载替换).

### 备选 — 本地 clone, 不走 marketplace

```bash
git clone https://github.com/LucasLawliet/aria-coder-buddy ~/Documents/Projects/aria-coder-buddy
# 在 CC session 里:
/plugin add ~/Documents/Projects/aria-coder-buddy/plugins/cc
```

详见 [`plugins/cc/README.zh.md`](plugins/cc/README.zh.md), 含完整的 Claude Code 配置 / hook 列表 / slash command.

## 日常使用

| 命令 | 何时用 |
|---|---|
| `/aria-awake` | Aria 离线时拉她回来 (如果 Aria.app 没跑, 顺手帮你启动) |
| `/aria-sleep` | 让她去睡 (avatar 播告别动画, 进程保活以便下次 `/aria-awake` 更快) |

Plugin hook 在 Claude Code session 启动 / 工具调用 / 停止 / 等事件自动 fire — 你不打字 Aria 也会自己反应.

## 目录布局

```
aria-coder-buddy/
├── .claude-plugin/marketplace.json   # marketplace 目录 (本仓自挂)
├── plugins/
│   └── cc/                            # Claude Code plugin (声明式 JSON + bash)
├── README.md                          # English
├── README.zh.md                       # 中文 (本文件)
└── .gitignore
```

未来 Codex / Kimi 落地后放 `plugins/<agent>/`, 一并写进 `marketplace.json`. 共享基础设施 (`bin/post-event.sh` / `bin/ensure-aria.sh` 这类) 当前在各 plugin 里独立维护 — 第二个 plugin 进来时再抽到 `lib/`.

## License

MIT (具体见各 plugin 自己的 manifest).

## 关联

- **Aria 桌面应用** (本仓 GitHub releases) — VRM 角色 + `aria-agent` server + behavior engine. macOS Apple Silicon. 启动时原地自动升级.
