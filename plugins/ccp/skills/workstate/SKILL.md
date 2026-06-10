---
name: workstate
description: Capture a mechanical snapshot of the repository (branch, git status, diff, recent commits, detected build/test commands) independent of conversation memory. Use whenever the user wants a ground-truth record of the repo before a profile switch, asks for "current repo state", "workstate", "snapshot the changes", or as a companion to /ccp:handoff and /ccp:takeover. Writes WORKSTATE.md, GIT_STATUS.txt, DIFF.patch, RECENT_COMMITS.txt under .claude/ccp/handoff/, with secrets redacted.
---

# CCP: workstate

Produce the *mechanical* truth about the repository — the part that doesn't depend on anyone's memory of the conversation. A handoff's prose can drift; the workstate is what the takeover side trusts.

## Steps

1. **Run the generator:**
   ```bash
   bash "${CLAUDE_PLUGIN_ROOT}/scripts/generate-workstate.sh"
   ```
   (If the path differs in this install, find `generate-workstate.sh` under the CCP plugin's `scripts/` directory.)

2. **Confirm it wrote** these files under `.claude/ccp/handoff/`:
   - `WORKSTATE.md` — human-readable summary
   - `GIT_STATUS.txt` — `git status` (branch + porcelain)
   - `DIFF.patch` — full staged + unstaged diff
   - `RECENT_COMMITS.txt` — last 20 commits

3. **Summarize** what the snapshot shows: current directory, branch, count of modified/untracked/deleted files, diff size, and any build/test commands the script detected. Point the user at `WORKSTATE.md` for the full picture.

The script captures: `pwd`, branch, `git status`, `git diff --stat`, full `git diff`, recent commits, and best-effort detected build/test commands.

## Redaction

All captured output is piped through CCP's redactor so tokens, keys, and `.env`-style secrets don't get persisted into these files. If you add anything by hand, keep it secret-free.

## Relationship to other CCP files

- **WORKSTATE = mechanical repo state** (this skill).
- **SESSION_BRIEF = reasoning, decisions, and context** (`/ccp:session-brief`).

A good handoff usually has both: the workstate proves *what* changed; the session brief explains *why*.

## What this skill must never do

- Never switch accounts or touch credentials/OAuth/Keychain data.
- Never install plugins.
