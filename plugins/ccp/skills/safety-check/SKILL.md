---
name: safety-check
description: Check whether it's safe to hand off or take over by scanning the working tree for risky conditions. Use when the user asks "is it safe to switch/hand off", "any blockers", "check for secrets/conflicts before I switch profiles", or before/after /ccp:handoff and /ccp:takeover. Runs the git safety script and reports repo status, staged/unstaged/untracked/deleted files, merge conflicts, large files, likely secret files, and likely secrets in the diff. Writes .claude/ccp/handoff/SAFETY_CHECK.md.
---

# CCP: safety-check

Decide whether the current repo state is safe to hand off or take over. This is a fast, read-only gate that surfaces the conditions most likely to cause data loss or a secret leak when switching profiles.

## Steps

1. **Run the safety script:**
   ```bash
   bash "${CLAUDE_PLUGIN_ROOT}/scripts/git-safety-check.sh"
   ```
   (If the path differs in this install, find `git-safety-check.sh` under the CCP plugin's `scripts/` directory.)

2. **It writes `.claude/ccp/handoff/SAFETY_CHECK.md`** covering:
   - Is this a git repo? Current branch.
   - Staged changes
   - Unstaged (modified, tracked) changes
   - Untracked files
   - Deleted files
   - Merge conflicts
   - Large files (> 1 MB) in pending changes
   - Likely secret files by name (`.env`, `*.pem`, `id_rsa`, `.credentials.json`, etc.)
   - Likely secrets inside the diff (counted via the conservative redactor)

3. **Summarize the verdict** for the user: safe / proceed-with-caution / not-safe-yet, and list the specific things to address first (e.g. "resolve the merge conflict in `app.ts`", "untracked `.env` is in the changeset — exclude it").

## Read-only

This skill inspects only. It never stages, commits, deletes, or installs anything.

## What this skill must never do

- Never switch accounts or touch credentials/OAuth/Keychain data.
- Never install plugins.
- Never print a discovered secret's value — locations and counts only.
