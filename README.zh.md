# aria-coder-buddy

[English](README.md) | [中文]

把 AI coding agent (Claude Code / OpenAI Codex / Kimi / ...) 桥接到 **Aria** 桌面虚拟形象 — 让 VRM 角色实时回应你的写代码过程: 你敲提示她在思考, 任务完成她在欢呼, 你太久没动她跑去看书发呆.

## 状态

| Agent | 路径 | 状态 |
|---|---|---|
| Claude Code | `plugins/cc/` | ✅ 可用 (v0.1.0) |
| OpenAI Codex CLI | `plugins/codex/` | ⏳ 计划中 |
| Kimi / Moonshot | `plugins/kimi/` | ⏳ 计划中 |

每个子目录是一个独立的、对应 agent plugin 格式的 plugin. 所有 plugin 都 POST 到同一后端 — `aria-agent` server (单独的 Python 服务, 在 [aria](https://github.com/LucasLawliet/aria) 仓库里), 监听 `http://127.0.0.1:8000`.

## 整体架构

```
┌─────────────┐  hook 事件      ┌─────────────┐  WebSocket    ┌──────────────┐
│ AI agent    │ ──────────────► │ aria-agent  │ ────────────► │ Aria desktop │
│ (CC, Codex, │  POST /events/* │ (FastAPI    │  behavior     │ (Unity +     │
│  Kimi, ...) │                 │  on :8000)  │  command      │  Flutter)    │
└─────────────┘                 └─────────────┘               └──────────────┘
       ▲                              │
       │ slash command                │ HTTPS (token 从 CC OAuth 或 env 取)
       │ (用户触发)                   ▼
                              ┌──────────────────┐
                              │ Anthropic API    │
                              │ (随机说话)       │
                              └──────────────────┘
```

`aria-agent` 是大脑: 它追踪 companion state, 跑 behavior engine, 决定头像该做什么, 通过 WebSocket 把命令推给桌面端. 这个仓里每个 plugin 都是个轻量适配器, 把宿主 agent 的事件转发出去.

## 隐私

Plugin 只转发**事件元数据** — `kind` / `outcome` / `tool_name` / `notification_kind`. 你的 prompt、工具的输入输出**永不上送**.

## 安装

本仓自身就是个 Claude Code **plugin marketplace** (见 `.claude-plugin/marketplace.json`). 推荐安装方式:

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

还需要本地起 `aria-agent` 监听 `:8000` — 看 [aria 仓库](https://github.com/LucasLawliet/aria) 的安装说明. 设了 `ARIA_AGENT_DIR=/path/to/aria/Server` 之后, plugin 的 `SessionStart` hook 会自动帮你 spawn.

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

- [aria](https://github.com/LucasLawliet/aria) — 桌面 avatar 本体、`aria-agent` server、behavior engine 设计 (`docs/aria-cc-buddy/spec.md`)
