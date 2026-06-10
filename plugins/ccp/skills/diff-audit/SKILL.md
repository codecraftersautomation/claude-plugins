---
name: diff-audit
description: Audit the current git diff before a handoff or commit to catch problems. Use when the user asks to "review my changes", "audit the diff", "check before handoff/commit", "did I leave anything bad in here", or before /ccp:handoff. Looks for accidental edits, generated/committed-by-mistake files, secrets, formatting noise, unfinished TODOs, risky permission changes, and destructive changes. Writes .claude/ccp/handoff/DIFF_AUDIT.md and does NOT modify files unless explicitly asked.
---

# CCP: diff-audit

Review the working diff with a skeptical eye before it's handed to another profile or committed. The goal is to catch the things that quietly cause problems later: a debug print left in, a secret pasted into a config, a generated file that shouldn't be tracked, a `chmod 777`, a deletion that wasn't intended.

## Steps

1. **Inspect the diff:**
   ```bash
   git diff
   git diff --staged
   git status
   ```

2. **Look for each of these categories** and report findings with file + line references:
   - **Accidental edits** — debug prints, commented-out code, stray whitespace-only churn, leftover scratch changes.
   - **Generated / vendored files** that probably shouldn't be committed (build output, `node_modules`, lockfile churn that doesn't belong, large generated assets).
   - **Secrets** — tokens, API keys, passwords, `.env` values, private keys. Report the location, not the value.
   - **Formatting issues** — diffs that are 90% reformatting and obscure the real change; inconsistent indentation.
   - **Incomplete TODOs** — `TODO`, `FIXME`, `XXX`, `HACK`, half-finished functions.
   - **Risky permission changes** — files becoming executable, mode `777`, ownership changes.
   - **Destructive changes** — large deletions, removed tests, dropped error handling, schema/migration drops.

3. **Write `.claude/ccp/handoff/DIFF_AUDIT.md`** with a findings list grouped by category, each with severity (info / warning / blocker) and a one-line recommendation.

## Read-only by default

Do **not** modify, stage, revert, or commit anything unless the user explicitly asks you to fix something. The audit informs; the human decides.

## What this skill must never do

- Never switch accounts or touch credentials/OAuth/Keychain data.
- Never install plugins.
- Never reprint a discovered secret in full — reference its location.
