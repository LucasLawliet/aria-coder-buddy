# aria-cc-plugin

[English] | [中文](README.zh.md)

Claude Code plugin that bridges CC session lifecycle events to the **Aria desktop avatar** running on `http://127.0.0.1:8000` (the `aria-agent` server).

The plugin is intentionally minimal: declarative `hooks/hooks.json` + a couple of bash scripts. No Node, no SDK. CC fires hook events → bash reshapes the JSON → `curl POST /events/cc`. The avatar reacts.

## What it does

- **Hooks**: `SessionStart` / `UserPromptSubmit` / `Stop` / `StopFailure` / `PreToolUse` / `PostToolUse` / `Notification` / `PermissionRequest` → POST event metadata to aria-agent.
- **Slash commands**:
  - `/aria-wake` — wake the avatar (one-shot wake event)
  - `/aria-sleep` — explicit sleep (CC has no SessionEnd hook, so this is the only way)
- **Bootstrap**: `SessionStart` runs `bin/ensure-aria.sh` — probes `:8000`; if no aria-agent, spawns it detached.

## Privacy

Only event **metadata** is sent — `kind` / `outcome` / `tool_name` / `notification_kind`. Prompts and tool inputs/outputs **are never forwarded**.

## Quick start

**1. Install the plugin (in a Claude Code session)**:

```
/plugin marketplace add LucasLawliet/aria-coder-buddy
/plugin install aria-cc-plugin@aria-coder-buddy
```

**2. Make sure `aria-agent` is running on `:8000`**.

The easiest path — set `ARIA_AGENT_DIR` so the plugin spawns it for you:

```bash
# In your shell profile (~/.zshrc or ~/.bashrc):
export ARIA_AGENT_DIR=/path/to/aria/Server
```

Next CC session, `SessionStart` runs `bin/ensure-aria.sh` → probes `:8000` → if down, `cd $ARIA_AGENT_DIR && nohup uv run aria-agent start &`. Logs land in `/tmp/aria-agent.log`.

Or start it manually:
```bash
cd /path/to/aria/Server && uv run aria-agent start
```

**3. Use Claude Code normally** — every prompt, tool use, and stop fires hooks → POSTs to `:8000`. The avatar reacts. No further action needed.

**4. Slash commands** (when you want explicit control):
- `/aria-wake` — force-wake the avatar (also fires automatically at SessionStart)
- `/aria-sleep` — let her go to sleep (avatar plays farewell, process stays warm)

## Alternative install (local clone, skip marketplace)

```bash
git clone https://github.com/LucasLawliet/aria-coder-buddy ~/Documents/Projects/aria-coder-buddy
# In a CC session:
/plugin add ~/Documents/Projects/aria-coder-buddy/plugins/cc
```

Or in `~/.claude/settings.json`:
```json
{ "plugins": ["~/Documents/Projects/aria-coder-buddy/plugins/cc"] }
```

## Configuration

Both env vars are optional:

| Variable | Default | Purpose |
|---|---|---|
| `ARIA_AGENT_URL` | `http://127.0.0.1:8000` | Where the plugin POSTs events |
| `ARIA_AGENT_DIR` | (unset) | Path to the `aria` repo's `Server/` dir; if set, `SessionStart` bootstrap will spawn `aria-agent` automatically when it's not already running |

## Requirements

- `bash`, `curl`, `jq` on `PATH`
- `aria-agent` reachable at `$ARIA_AGENT_URL` (or spawnable via `bin/ensure-aria.sh`)

## Layout

```
.claude-plugin/plugin.json   manifest
hooks/hooks.json              CC hook → bin/post-event.sh dispatch
commands/                     /aria-wake, /aria-sleep
bin/post-event.sh             reshape stdin JSON → curl POST /events/cc, 200ms timeout
bin/ensure-aria.sh            SessionStart bootstrap
```

## Troubleshooting

- **avatar not reacting**: `curl http://127.0.0.1:8000/companion/state` — if no response, run `bin/ensure-aria.sh` manually
- **hook not firing**: tail `~/.claude/logs/*` and check `bin/*.sh` are executable (`chmod +x bin/*.sh`)
- **rapid timeouts**: aria-agent should respond `204` in < 50ms; `--max-time 0.2` in post-event.sh fails silently if slower

## Heartbeat strategy

This plugin does **not** send a periodic heartbeat. aria-agent uses *Strategy A* — any cc event resets its idle timer. CC has no scheduled-tick hook, and a daemon would be brittle. When the user is idle, no events fire → avatar drifts into `relax` / `session_lost` naturally.

See `aria/docs/aria-cc-buddy/spec.md` § 5.2 for the rationale.
