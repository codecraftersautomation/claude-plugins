---
name: plugin-inventory
description: Inventory and compare the plugins available in both Claude Code profiles (claude-team and claude-max). Use when the user wants to know "which plugins are in each account", "compare my profiles' plugins", "what's installed where", or before syncing plugins between profiles. Runs plugin-inventory.sh, captures each launcher's `plugin list`, and writes team-plugins.txt, max-plugins.txt, and PLUGIN_INVENTORY.md under .claude/ccp/plugins/. Installs nothing.
---

# CCP: plugin-inventory

See, at a glance, what plugins each profile has — so you can decide what to align. This is purely a read step; it installs and changes nothing.

## Steps

1. **Run the inventory script:**
   ```bash
   bash "${CLAUDE_PLUGIN_ROOT}/scripts/plugin-inventory.sh"
   ```
   It invokes `claude-team plugin list` and `claude-max plugin list`, captures each separately, and redacts the output. If one launcher is missing or errors, the script records that safely and still produces a report for the other.

2. **It writes** under `.claude/ccp/plugins/`:
   - `team-plugins.txt` — raw (redacted) Team capture
   - `max-plugins.txt` — raw (redacted) Max capture
   - `PLUGIN_INVENTORY.md` — comparison: only-Team, only-Max, common, plus any enabled/disabled and scope info that the raw output happened to include

3. **Summarize** the diff for the user: which plugins are only in one profile, which are shared, and the recommended next move (`/ccp:plugin-export` → `/ccp:plugin-sync-plan` → review → `/ccp:plugin-apply`).

## Notes on parsing

`plugin list` output varies by Claude Code version, so the comparison is best-effort. Treat `team-plugins.txt` and `max-plugins.txt` as authoritative; the markdown diff is a convenience. If a launcher isn't found, point the user at `/ccp:profile-doctor`.

## What this skill must never do

- Never install, enable, or disable any plugin.
- Never copy plugin cache between profiles.
- Never touch credentials/OAuth/Keychain data.
