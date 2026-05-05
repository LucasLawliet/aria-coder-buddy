# aria-coder-buddy

[English] | [中文](README.zh.md)

Bridge AI coding agents (Claude Code, OpenAI Codex, Kimi, ...) to the **Aria** desktop avatar — your VRM character reacts to your coding session in real time. Type a prompt, watch her think; finish a task, watch her cheer; idle too long, watch her wander off.

## Status

| Agent | Path | Status |
|---|---|---|
| Claude Code | `plugins/cc/` | ✅ working (v0.1.0) |
| OpenAI Codex CLI | `plugins/codex/` | ⏳ planned |
| Kimi / Moonshot | `plugins/kimi/` | ⏳ planned |

Each subdirectory is a self-contained plugin for that agent's plugin format. They all POST to the same backend — the `aria-agent` server, a separate Python service shipped with the **Aria desktop app** (TBD — public download link will be published here once available).

## How the parts fit

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

`aria-agent` is the brain: it tracks companion state, runs a behavior engine, decides what the avatar should do, and pushes commands over WebSocket. Each plugin in this repo is a thin adapter that forwards its host agent's events.

## Privacy

Plugins forward **event metadata** (`kind` / `outcome` / `tool_name` / `notification_kind`) plus, on `Stop` / `StopFailure`, the **local path** to the agent's transcript file so `aria-agent` (also running on your machine) can summarize what just happened in the avatar's chat bubble. The transcript itself never leaves your box over the wire — only the path is sent in-process to a localhost service. Prompts and tool inputs/outputs are **never** POSTed to a remote server by the plugins themselves.

If you do not run the Aria desktop app, port `8000` has no listener and every plugin POST silently fails — **zero token cost** when the avatar is offline.

## Install

### One-shot (paste this into Claude Code)

The fastest path — paste this prompt into a Claude Code session and it'll walk you through:

```
Help me install aria-coder-buddy plugin (Aria desktop avatar bridge).

The plugin lives at https://github.com/LucasLawliet/aria-coder-buddy and ships
through Claude Code's marketplace mechanism. Steps:

1. Tell me which two slash commands I should run inside CC to install:
   one to add the marketplace LucasLawliet/aria-coder-buddy, and one to
   install the aria-cc-plugin from it.
2. After I report back, verify the plugin landed by checking
   ~/.claude/settings.json or the plugin list.
3. Ask me where the Aria desktop app is installed (it bundles aria-agent;
   may not be publicly released yet — if so, just skip this step). If
   I have it, append `export ARIA_AGENT_DIR=<path>` to my shell rc.
4. Tell me what to expect on the next CC session start.
```

CC can't trigger its own slash commands programmatically, so steps 1+2 still need you to type them — but everything else (verification, env setup) it handles for you.

### Manual

```
/plugin marketplace add LucasLawliet/aria-coder-buddy
/plugin install aria-cc-plugin@aria-coder-buddy
```

To update later:

```
/plugin marketplace update aria-coder-buddy
```

**Alternative — local clone, no marketplace**:

```bash
git clone https://github.com/LucasLawliet/aria-coder-buddy ~/Documents/Projects/aria-coder-buddy
# In a CC session:
/plugin add ~/Documents/Projects/aria-coder-buddy/plugins/cc
```

You also need `aria-agent` running locally on `:8000` — it ships with the Aria desktop app (TBD). Set `ARIA_AGENT_DIR=<aria-app-Server-dir>` and the plugin's `SessionStart` hook will spawn it for you.

See [`plugins/cc/README.md`](plugins/cc/README.md) for the full Claude Code setup, hook list, and slash commands.

## Layout

```
aria-coder-buddy/
├── .claude-plugin/marketplace.json   # marketplace catalog (this repo lists itself)
├── plugins/
│   └── cc/                            # Claude Code plugin (declarative JSON + bash)
├── README.md                          # English (this file)
├── README.zh.md                       # 中文
└── .gitignore
```

Future plugins (Codex, Kimi) will land under `plugins/<agent>/` and get added to `marketplace.json`. Shared infrastructure (`bin/post-event.sh` / `bin/ensure-aria.sh` style logic) lives inside each plugin for now — when the second plugin lands we'll factor out a `lib/` directory.

## License

MIT (see individual plugin manifests).

## Related

- **Aria desktop app** — VRM character + `aria-agent` server + behavior engine. Public download TBD.
