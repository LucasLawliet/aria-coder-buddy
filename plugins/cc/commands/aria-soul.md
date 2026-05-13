---
description: Edit Aria's soul (system prompt / persona) via conversation
allowed-tools: Bash, Read, Write
---

The user wants to edit Aria's soul — her system prompt / persona text.

1. Fetch current soul:
   ```bash
   "${CLAUDE_PLUGIN_ROOT}/bin/soul.sh" get
   ```
   Returns JSON `{"content": "...", "is_default": bool}`. If `is_default: true`,
   she's using the built-in default; otherwise the user has customized.

2. Show the user the current `content` (paste it as-is so they see exactly
   what's there). Mention if it's the default.

3. Ask the user what they want to change. Have a real conversation — refine
   based on their feedback, propose phrasings, iterate.

4. When the user confirms the new soul, write it back:
   ```bash
   "${CLAUDE_PLUGIN_ROOT}/bin/soul.sh" set "<new soul text>"
   ```
   The script wraps the raw text in JSON automatically.

5. Tell the user the change takes effect on Aria's next response.

If the user wants to restore the default:
```bash
"${CLAUDE_PLUGIN_ROOT}/bin/soul.sh" reset
```

Note: memory (user facts / emotional anchors / conversation history) and
character model are managed separately — see the desktop app settings page
or /aria-model.
