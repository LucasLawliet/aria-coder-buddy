---
description: Edit Aria's soul (system prompt / persona / memory) via conversation
allowed-tools: Bash, Read, Edit, Write
---

The user wants to edit Aria's soul — her system prompt, persona, and memory.

1. Fetch current soul via the helper script:
   ```bash
   "${CLAUDE_PLUGIN_ROOT}/bin/soul.sh" get
   ```
   The script returns JSON with `prompt`, `persona`, `memory` fields.

2. Show the user the current soul (concise summary, not the full prompt unless asked).

3. Ask the user what they want to change. Have a real conversation — refine
   based on their feedback, propose phrasings, iterate.

4. When the user confirms the new soul, write it back:
   ```bash
   "${CLAUDE_PLUGIN_ROOT}/bin/soul.sh" set '<json>'
   ```
   where `<json>` is the updated JSON (single-quoted, escape inner quotes).

5. Tell the user the change takes effect on Aria's next response (server hot-reloads on save).
