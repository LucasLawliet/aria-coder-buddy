# aria-coder-buddy

[English](README.md) | [中文]

把 AI coding agent (Claude Code / OpenAI Codex / Kimi / ...) 桥接到 **Aria** 桌面虚拟形象 — 让 VRM 角色实时回应你的写代码过程: 你敲提示她在思考, 任务完成她在欢呼, 你太久没动她跑去看书发呆.

## 状态

| Agent | 路径 | 状态 |
|---|---|---|
| Claude Code | `plugins/cc/` | ✅ 可用 (v0.1.0) |
| OpenAI Codex CLI | `plugins/codex/` | ⏳ 计划中 |
| Kimi / Moonshot | `plugins/kimi/` | ⏳ 计划中 |

每个子目录是一个独立的、对应 agent plugin 格式的 plugin. 所有 plugin 都 POST 到同一后端 — `aria-agent` server, 它是 **Aria 桌面应用** 内置的 Python 服务 (公开发布链接待补; 当前版本未公开).

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

Plugin 只转发**事件元数据** — `kind` / `outcome` / `tool_name` / `notification_kind`. 你的 prompt、工具的输入输出**永不上送**.

## 安装

### 一键 (复制下面整段贴进 Claude Code)

最省事路径 — 把这段提示词贴进 Claude Code 的对话, 它会引导你走完安装:

```
帮我装 aria-coder-buddy plugin (Aria 桌面 avatar 桥接).

仓库在 https://github.com/LucasLawliet/aria-coder-buddy, 走 Claude Code 的
marketplace 机制. 流程:

1. 告诉我应该在 CC 里敲哪两条 slash command 完成安装 — 一条添加
   marketplace LucasLawliet/aria-coder-buddy, 一条从 marketplace 装
   aria-cc-plugin.
2. 我敲完反馈给你, 你帮我验证装好了 — 查 ~/.claude/settings.json 或 plugin 列表.
3. 询问我 Aria 桌面应用安装在哪里 (它内置 aria-agent server; 当前可能尚未公开
   发布, 没有就跳过这步). 我有的话, 帮我把 `export ARIA_AGENT_DIR=<路径>`
   写到我的 shell rc.
4. 告诉我下次 CC session 启动时预期看到什么.
```

CC 不能自己触发 slash command, 所以第 1, 2 步还得你手动敲 — 但其它 (验证 / 环境变量配置) CC 全包.

### 手动

```
/plugin marketplace add LucasLawliet/aria-coder-buddy
/plugin install aria-cc-plugin@aria-coder-buddy
```

之后想升级:

```
/plugin marketplace update aria-coder-buddy
```

**或者本地 clone 不走 marketplace**:

```bash
git clone https://github.com/LucasLawliet/aria-coder-buddy ~/Documents/Projects/aria-coder-buddy
# 在 CC session 里:
/plugin add ~/Documents/Projects/aria-coder-buddy/plugins/cc
```

还需要本地起 `aria-agent` 监听 `:8000` — 它在 Aria 桌面应用里 (待公开发布). 设了 `ARIA_AGENT_DIR=<aria-app-Server-目录>` 之后, plugin 的 `SessionStart` hook 会自动帮你 spawn.

详见 [`plugins/cc/README.zh.md`](plugins/cc/README.zh.md), 含完整的 Claude Code 配置 / hook 列表 / slash command.

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

- **Aria 桌面应用** — VRM 角色 + `aria-agent` server + behavior engine. 公开下载链接待补.
