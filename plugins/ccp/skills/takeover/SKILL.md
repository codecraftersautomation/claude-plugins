---
name: takeover
description: Continue work safely in this Claude Code profile from a handoff left by the other profile (claude-team <-> claude-max). Use this right after opening the repo in a different Claude account/launcher, when the user says "take over", "continue from the handoff", "pick up where the other account left off", or after a previous session ran /ccp:handoff or /ccp:compact-handoff. Reads the handoff and workstate, compares against live git state, and reports the safe next step. Does NOT edit files until the user explicitly says to continue.
---

# CCP: takeover

Resume work that another Claude profile handed off. Your job is to **orient and verify**, not to start editing. The user has just switched accounts/launchers in the same repository and needs to know whether it is safe to continue.

## Steps

1. **Read the handoff.** Read `.claude/ccp/handoff/HANDOFF.md` (or `COMPACT_HANDOFF.md` if that's what exists). This is the human intent and context.

2. **Read the mechanical workstate.** Read `.claude/ccp/handoff/WORKSTATE.md` (and `GIT_STATUS.txt`, `DIFF.patch`, `RECENT_COMMITS.txt` if you need detail). This is ground truth as of the handoff moment.

3. **Inspect the live repo.** Run:
   ```bash
   git status
   git diff --stat
   git rev-parse --abbrev-ref HEAD
   ```

4. **Compare handoff vs. reality.** Does the branch match? Do the modified files match? Does HEAD match the recent commits in the handoff? Detect drift.

5. **Summarize** for the user:
   - Previous objective
   - Current repo state (branch, modified files, HEAD)
   - Risks
   - The next safe step

   You may use `templates/TAKEOVER.template.md` as the shape of this summary.

## Staleness handling

If the handoff references commits/files that no longer exist, the branch differs, or there are changes the handoff doesn't mention, **warn clearly and prominently**. Do not paper over divergence — a confident-but-wrong takeover is worse than a cautious one. Tell the user exactly what to reconcile.

## Do not edit yet

Do **not** modify, stage, or commit anything until the user explicitly tells you to continue. End your summary with the safe next step and wait for the go-ahead.

For a rigorous check, consider spawning the `takeover-reviewer` agent to independently confirm the repo still matches the handoff.

## What this skill must never do

- Never switch accounts or touch credentials/OAuth/Keychain data.
- Never install plugins.
- Never assume the handoff is current without checking live git state.
