---
name: plugin-export
description: Export the desired plugin set into a repo-local lock file (.claude/ccp/plugins/PLUGINS.lock.json). Use after /ccp:plugin-inventory when the user wants to "record/pin which plugins this repo should use", "create a plugin lock file", or "capture the plugin set to sync to the other profile". Records name, marketplace, version, scope, enabled state, source profile, components, and a risk level per plugin. Contains no secrets and no cache paths. Installs nothing.
---

# CCP: plugin-export

Turn the inventory into a declarative record of the plugin set this repo *should* have, so it can be synced to the other profile deliberately rather than by hand.

## Steps

1. **Make sure inventory exists.** If `.claude/ccp/plugins/team-plugins.txt` / `max-plugins.txt` aren't present, run `/ccp:plugin-inventory` first.

2. **Generate the lock file:**
   ```bash
   bash "${CLAUDE_PLUGIN_ROOT}/scripts/plugin-export.sh"
   ```
   This writes `.claude/ccp/plugins/PLUGINS.lock.json`. The script parses best-effort and, when a line is ambiguous, preserves the original under a `raw` field and marks uncertain fields `"unknown"` rather than guessing.

3. **Review and refine the lock file.** For each plugin record, confirm/improve:
   - `name`
   - `marketplace` (leave `"unknown"` if it genuinely isn't known — do not invent one)
   - `version` (if available)
   - `scope`: `user` / `project` / `local` / `managed` / `unknown`
   - `enabled`: `true` / `false` / `"unknown"`
   - `source_profile`: `team` / `max` / `both`
   - `components`: skills, agents, hooks, mcp_servers, lsp_servers (if known)
   - `risk`: `low` / `medium` / `high`

   See `templates/PLUGINS.lock.template.json` for the shape.

## Scope guidance

- Prefer **project** scope for repo-specific plugins (they should travel with this repo).
- Prefer **user** scope only for generic personal tools.
- Mark **managed** when an org controls the plugin — CCP can't change those.

## Risk flagging

**Warn the user** about any plugin that ships **hooks, MCP servers, LSP servers, or shell-executing behavior**, or comes from a **local path / unknown source** — mark these `risk: high`. The sync plan will comment those out by default so they're never installed without explicit review.

## What this skill must never do

- Never include secrets, OAuth tokens, or credentials in the lock file.
- Never include plugin cache paths unless clearly useful and safe.
- Never guess a marketplace name.
- Never install anything.
