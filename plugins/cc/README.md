# aria-cc-plugin

Claude Code plugin that bridges CC session lifecycle events to the **Aria desktop avatar** running on `http://127.0.0.1:8000` (the `aria-agent` server).

The plugin is intentionally minimal: declarative `hooks/hooks.json` + a couple of bash scripts. No Node, no SDK. CC fires hook events → bash reshapes the JSON → `curl POST /events/cc`. The avatar reacts.

## What it does

- **Hooks**: `SessionStart` / `UserPromptSubmit` / `Stop` / `StopFailure` / `PreToolUse` / `PostToolUse` / `Notification` / `PermissionRequest` → POST event metadata to aria-agent.
- **Slash commands**:
  - `/aria-wake` — wake the avatar (one-shot wake event)
  - `/aria-sleep` — explicit sleep (CC has no SessionEnd hook, so this is the only way)
  - `/aria-mood <happy|tired|focused|...>` — manual mood override
- **Bootstrap**: `SessionStart` runs `bin/ensure-aria.sh` — probes `:8000`; if no aria-agent, spawns it detached.

## Privacy

Only event **metadata** is sent — `kind` / `outcome` / `tool_name` / `notification_kind`. Prompts and tool inputs/outputs **are never forwarded**.

## Install (local, dev)

```bash
git clone <this-repo> ~/Documents/Projects/aria-cc-plugin
# In a CC session:
/plugin add /Users/lucas/Documents/Projects/aria-cc-plugin
```

Or wire it via `~/.claude/settings.json`:

```json
{
  "plugins": [
    "/Users/lucas/Documents/Projects/aria-cc-plugin"
  ]
}
```

## Requirements

- `bash`, `curl`, `jq` on `PATH`
- `aria-agent` reachable at `http://127.0.0.1:8000` (or spawnable via `bin/ensure-aria.sh`)

## Layout

```
.claude-plugin/plugin.json   manifest
hooks/hooks.json              CC hook → bin/post-event.sh dispatch
commands/                     /aria-wake, /aria-sleep, /aria-mood
bin/post-event.sh             reshape stdin JSON → curl POST /events/cc, 200ms timeout
bin/ensure-aria.sh            SessionStart bootstrap
```

## Troubleshooting

- **avatar not reacting**: `curl http://127.0.0.1:8000/health` — if no response, run `bin/ensure-aria.sh` manually
- **hook not firing**: tail `~/.claude/logs/*` and check `bin/post-event.sh` is executable (`chmod +x bin/*.sh`)
- **rapid timeouts**: aria-agent should respond `204` in < 50ms; `--max-time 0.2` in post-event.sh fails silently if slower

## Heartbeat strategy

This plugin does **not** send a periodic heartbeat. aria-agent uses *Strategy A* — any cc event resets its idle timer. CC has no scheduled-tick hook, and a daemon would be brittle. When the user is idle, no events fire → avatar drifts into `relax` / `session_lost` naturally.

See `aria/docs/aria-cc-buddy/spec.md` § 5.2 for the rationale.
