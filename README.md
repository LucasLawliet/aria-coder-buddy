# aria-coder-buddy

Bridge AI coding agents (Claude Code, OpenAI Codex, Kimi, ...) to the **Aria** desktop avatar — your VRM character reacts to your coding session in real time. Type a prompt, watch her think; finish a task, watch her cheer; idle too long, watch her wander off.

## Status

| Agent | Path | Status |
|---|---|---|
| Claude Code | `plugins/cc/` | ✅ working (v0.1.0) |
| OpenAI Codex CLI | `plugins/codex/` | ⏳ planned |
| Kimi / Moonshot | `plugins/kimi/` | ⏳ planned |

Each subdirectory is a self-contained plugin for that agent's plugin format. They all POST to the same backend — the `aria-agent` server (separate Python service in the [aria](https://github.com/LucasLawliet/aria) repo) on `http://127.0.0.1:8000`.

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

Plugins forward **event metadata only** — `kind` / `outcome` / `tool_name` / `notification_kind`. Prompts, tool inputs, and tool outputs are **never sent**.

## Install (local dev)

Pick the plugin matching your agent:

```bash
git clone https://github.com/LucasLawliet/aria-coder-buddy ~/Documents/Projects/aria-coder-buddy
```

**Claude Code**:
```
/plugin add ~/Documents/Projects/aria-coder-buddy/plugins/cc
```

Or wire it via `~/.claude/settings.json`:
```json
{
  "plugins": ["~/Documents/Projects/aria-coder-buddy/plugins/cc"]
}
```

See [`plugins/cc/README.md`](plugins/cc/README.md) for the full Claude Code setup, hook list, and slash commands.

## Layout

```
aria-coder-buddy/
├── plugins/
│   └── cc/                # Claude Code plugin (declarative JSON + bash)
├── README.md              # this file
└── .gitignore
```

Future plugins (Codex, Kimi) will land under `plugins/<agent>/`. Shared infrastructure (`bin/post-event.sh` / `bin/ensure-aria.sh` style logic) lives inside each plugin for now — when the second plugin lands we'll factor out a `lib/` directory.

## License

MIT (see individual plugin manifests).

## Related

- [aria](https://github.com/LucasLawliet/aria) — desktop avatar, `aria-agent` server, behavior engine spec (`docs/aria-cc-buddy/spec.md`)
