---
name: plugin-sync-plan
description: Create a reviewable plan plus generated install scripts to align plugins across both Claude profiles (claude-team and claude-max). Use after /ccp:plugin-inventory or /ccp:plugin-export when the user wants to "sync plugins between profiles", "make my accounts have the same plugins", or "generate install commands". Writes PLUGIN_SYNC_PLAN.md, install-missing-team.sh, and install-missing-max.sh under .claude/ccp/plugins/. The scripts are NOT auto-run; high-risk plugins are commented out by default.
---

# CCP: plugin-sync-plan

Produce a plan and two **reviewable, non-executing** install scripts that would bring each profile up to parity with the other. This is the "review-first" half of CCP's review-first, apply-second model — `/ccp:plugin-apply` is the second half.

## Steps

1. **Generate the plan and scripts:**
   ```bash
   bash "${CLAUDE_PLUGIN_ROOT}/scripts/plugin-sync-plan.sh"
   ```
   It reads the inventory (`team-plugins.txt`, `max-plugins.txt`) and `PLUGINS.lock.json` if present, then writes:
   - `.claude/ccp/plugins/PLUGIN_SYNC_PLAN.md`
   - `.claude/ccp/plugins/install-missing-team.sh`
   - `.claude/ccp/plugins/install-missing-max.sh`

2. **The generated scripts are designed to be read first.** Each one:
   - starts with `set -euo pipefail`
   - states its target profile, generated date, and source lock file in the header
   - is executable but **never** auto-run
   - uses `claude-team plugin install ...` (Team) or `claude-max plugin install ...` (Max)
   - **skips** plugins with unknown marketplace/source entirely (no guessing)
   - **comments out** high-risk plugins with a "manual review required" note

   High risk = hooks, MCP servers, LSP servers, shell-executing behavior, local-path sources, or unknown source.

3. **Walk the user through the plan.** Summarize what would be added to each profile, call out the high-risk/commented items, and recommend scopes:
   - repo-specific → `--scope project` (e.g. `claude plugin install plugin@marketplace --scope project`)
   - generic personal tools → `--scope user`
   - personal repo-only → `--scope local`
   - managed → out of CCP's control
   - local-path plugin sources → register the local marketplace first where possible, rather than a remote install.

4. Optionally spawn the `plugin-sync-reviewer` agent for an independent read of the mismatches, risks, and scope recommendations.

## Next step

Once the user has reviewed the scripts, run `/ccp:plugin-apply` and choose a target profile.

## What this skill must never do

- Never run the generated install scripts automatically.
- Never install high-risk plugins without explicit review.
- Never touch credentials/OAuth/Keychain data or copy plugin cache.
