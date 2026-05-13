# aria-coder-buddy

[English] | [中文](README.zh.md)

Bridge AI coding agents (Claude Code, OpenAI Codex, Kimi, ...) to the **Aria** desktop avatar — your VRM character reacts to your coding session in real time. Type a prompt, watch her think; finish a task, watch her cheer; idle too long, watch her wander off.

## ⚡ Quickstart — paste this into Claude Code

```
Install Aria desktop avatar by reading and following the "First-time install" section
of https://github.com/LucasLawliet/aria-coder-buddy/blob/main/README.md
```

Claude Code will fetch the README, follow the install steps (download .app, guide you through 2 slash commands, first launch). After that, just `/aria-awake` to bring her back.

## Status

| Agent | Path | Status |
|---|---|---|
| Claude Code | `plugins/cc/` | ✅ working (v0.1.7) |
| OpenAI Codex CLI | `plugins/codex/` | ⏳ planned |
| Kimi / Moonshot | `plugins/kimi/` | ⏳ planned |

Each subdirectory is a self-contained plugin for that agent's plugin format. They all POST to the same backend — the `aria-agent` server, a separate Python service shipped inside the **Aria desktop app** (macOS, Apple Silicon).

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

## First-time install (paste this into Claude Code)

The fastest path — paste this prompt into a Claude Code session, it walks you through downloading the Aria desktop app + installing the plugin + first launch. Subsequent sessions just use `/aria-awake`.

```
Help me install Aria desktop avatar + aria-coder-buddy plugin from
https://github.com/LucasLawliet/aria-coder-buddy. Do these in order:

0. **Check for old install + zombie processes FIRST** (must do before step 1
   or cp will fail with "Resource busy"):
   - ls -la /Applications/aria.app 2>/dev/null  (check existing install)
   - pgrep -fl "/aria\.app|uvicorn main:app|AriaFlutterBridge|aria-agent"  (zombies?)
   - Report findings: existing version + any live processes.
   - If existing install found:
     * osascript -e 'tell application id "com.sensebeing.aria" to quit' 2>/dev/null || true
     * sleep 2 && pkill -9 -f "/aria\.app|uvicorn main:app|AriaFlutterBridge|aria-agent" 2>/dev/null || true
     * rm -rf /Applications/aria.app
     * rm -rf "$HOME/Library/Caches/Aria"  (old Unity bundles, ~1GB; will redownload)
     * rm -rf "$HOME/Library/Application Support/Aria"  (old aria-agent runtime)
   - Verify clean: ls /Applications/aria.app 2>&1 should report "No such file"

1. Download + install Aria.app (macOS Apple Silicon, ~250 MB):
   - Get exact URL: gh release view --repo LucasLawliet/aria-coder-buddy --json assets --jq '.assets[] | select(.name|startswith("aria-")) | .browser_download_url'
   - curl -L -o /tmp/aria.zip <url>
   - mkdir -p /tmp/aria-extract && unzip -oq /tmp/aria.zip -d /tmp/aria-extract/
   - cp -R /tmp/aria-extract/aria.app /Applications/aria.app
   - xattr -dr com.apple.quarantine /Applications/aria.app 2>/dev/null || true
   - Verify: defaults read /Applications/aria.app/Contents/Info CFBundleShortVersionString
   - Tell me what version got installed.

2. Patch `~/.claude/settings.json` first (next-session fallback so plugin is
   guaranteed installed even if user skips step 3):
   ```python
   python3 << 'EOF'
   import json, os
   p = os.path.expanduser('~/.claude/settings.json')
   if os.path.exists(p):
       with open(p) as f: data = json.load(f)
   else:
       data = {}
   data.setdefault('enabledPlugins', {})['aria-cc-plugin@aria-coder-buddy'] = True
   data.setdefault('extraKnownMarketplaces', {})['aria-coder-buddy'] = {
       'source': {'source': 'github', 'repo': 'LucasLawliet/aria-coder-buddy'}
   }
   with open(p, 'w') as f: json.dump(data, f, indent=2)
   print('settings.json patched')
   EOF
   ```
   Tell me the patch landed.

3. Tell me to run these two slash commands inside Claude Code NOW (so
   /aria-awake / /aria-sleep work in the current session — without these
   the plugin only loads on next CC session start):
     /plugin marketplace add LucasLawliet/aria-coder-buddy
     /plugin install aria-cc-plugin@aria-coder-buddy
   Wait for my confirmation that both succeeded. You cannot trigger them
   yourself — slash commands are user-typed only.

4. Launch the Aria desktop app:
     open -b com.sensebeing.aria
   First run downloads ~400 MB of 3D avatar assets (90-120 s). Tell me to
   wait for the character to appear.

5. After the character is visible, tell me from now on I run /aria-awake
   to bring her back when she's offline, /aria-sleep to put her to sleep.
```

After install, **all subsequent sessions** — just run `/aria-awake` and she comes back.

### Manual install (without the prompt)

```
# 1. Download + install Aria.app
gh release download --repo LucasLawliet/aria-coder-buddy --pattern 'aria-*.zip' --output /tmp/aria.zip
mkdir -p /tmp/aria-extract && unzip -oq /tmp/aria.zip -d /tmp/aria-extract/
rm -rf /Applications/aria.app && cp -R /tmp/aria-extract/aria.app /Applications/aria.app
xattr -dr com.apple.quarantine /Applications/aria.app 2>/dev/null || true

# 2. Inside Claude Code, run:
/plugin marketplace add LucasLawliet/aria-coder-buddy
/plugin install aria-cc-plugin@aria-coder-buddy

# 3. First launch:
open -b com.sensebeing.aria
# (wait ~2 min for first-run 3D asset download)
```

To update plugin later:

```
/plugin marketplace update aria-coder-buddy
```

The Aria desktop app updates itself in-place (checks GitHub releases on launch, downloads + swaps when a new version ships).

### Alternative — local clone, no marketplace

```bash
git clone https://github.com/LucasLawliet/aria-coder-buddy ~/Documents/Projects/aria-coder-buddy
# In a CC session:
/plugin add ~/Documents/Projects/aria-coder-buddy/plugins/cc
```

See [`plugins/cc/README.md`](plugins/cc/README.md) for the full Claude Code setup, hook list, and slash commands.

## Daily use

| Command | When |
|---|---|
| `/aria-awake` | Bring Aria back when she's offline (also auto-launches Aria.app if not running) |
| `/aria-sleep` | Send her to sleep (avatar plays farewell, process stays warm for fast `/aria-awake`) |

Plugin hooks fire automatically on Claude Code session start / tool use / stop / etc. — Aria reacts without you typing anything.

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

- **Aria desktop app** (this repo's GitHub releases) — VRM character + `aria-agent` server + behavior engine. macOS Apple Silicon. In-place auto-update on launch.
