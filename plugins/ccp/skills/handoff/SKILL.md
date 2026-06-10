---
name: handoff
description: Prepare a full handoff so work can continue in the other Claude Code profile (claude-team <-> claude-max) from the same repository. Use this whenever the user is about to switch Claude accounts/launchers, is running low on usage in one profile, says "hand this off", "I need to continue in my other account", "switch to claude-max/claude-team", or wants to capture the current state of work before changing profiles. Writes .claude/ccp/handoff/HANDOFF.md plus a mechanical workstate and a safety report. Does NOT switch accounts or touch credentials.
---

# CCP: handoff

Prepare a complete, self-contained handoff so a *different* Claude profile (opened in the same repo) can continue the work without your conversation memory. The receiving side will run `/ccp:takeover`.

This skill never switches accounts and never touches credentials, OAuth tokens, or Keychain data. It only writes repo-local handoff files.

## Steps

1. **Capture mechanical state first.** Run the workstate generator so the prose handoff sits on top of ground truth:
   ```bash
   bash "${CLAUDE_PLUGIN_ROOT}/scripts/generate-workstate.sh"
   ```
   This writes `.claude/ccp/handoff/WORKSTATE.md`, `GIT_STATUS.txt`, `DIFF.patch`, `RECENT_COMMITS.txt` (all redacted). If the path differs in this install, locate the script under the CCP plugin's `scripts/` directory.

2. **Run the safety check** so the handoff flags risky state (uncommitted work, conflicts, possible secrets):
   ```bash
   bash "${CLAUDE_PLUGIN_ROOT}/scripts/git-safety-check.sh"
   ```
   This writes `.claude/ccp/handoff/SAFETY_CHECK.md`.

3. **Write `.claude/ccp/handoff/HANDOFF.md`.** Use `templates/HANDOFF.template.md` as the structure and fill every section from the conversation plus the workstate. Include:
   - Objective
   - Current technical / business context
   - Current profile, if detectable (e.g. inferred from how the session was launched; if unknown, say "unknown")
   - Current branch
   - Modified files
   - Commands / tests already run
   - Commands / tests still needed
   - Errors / blockers
   - Important decisions
   - Known assumptions
   - Things that must NOT be changed
   - Next recommended prompt (concrete, copy-pasteable)

4. **End the handoff with this exact line** so the next session knows what to do:

   > Open the same repository with `claude-max` or `claude-team`, then run `/ccp:takeover`.

## Quality bar

The whole point is that someone with *zero* conversation context can resume. If a section would be empty, say so explicitly ("No tests run yet") rather than omitting it — silence reads as "nothing to know," which is rarely true.

Redact anything that looks like a secret from your prose; the scripts already redact their captured output, but your hand-written summary must not reintroduce a token, key, or password.

Optionally spawn the `handoff-reviewer` agent to validate completeness and catch leaked secrets before the user switches profiles.

## What this skill must never do

- Never copy or read credentials, `.credentials.json`, OAuth tokens, cookies, or Keychain data.
- Never attempt to switch accounts or log in/out.
- Never install plugins.
