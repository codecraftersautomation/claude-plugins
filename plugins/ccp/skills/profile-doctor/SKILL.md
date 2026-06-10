---
name: profile-doctor
description: Diagnose the Claude Code profile setup for the claude-team / claude-max workflow. Use when handoff, takeover, or plugin commands behave unexpectedly, when the user asks "check my profile setup", "are my launchers working", "why is claude-max/claude-team failing", or before relying on CCP for the first time. Verifies the launchers exist and respond to --version, checks for env overrides that could redirect auth (presence only, never values), and writes .claude/ccp/PROFILE_DOCTOR.md.
---

# CCP: profile-doctor

Sanity-check the environment that the whole CCP workflow depends on, so problems show up here instead of mid-handoff. Read-only, and it never reveals secret values — only whether a sensitive variable is set.

## Steps

1. **Run the doctor:**
   ```bash
   bash "${CLAUDE_PLUGIN_ROOT}/scripts/profile-doctor.sh"
   ```

2. **It checks and writes `.claude/ccp/PROFILE_DOCTOR.md`** covering:
   - Whether `claude`, `claude-team`, and `claude-max` exist in PATH, and their `--version` if they answer.
   - Whether risky environment overrides are **present** (never their values):
     - `ANTHROPIC_API_KEY`
     - `ANTHROPIC_AUTH_TOKEN`
     - `CLAUDE_CODE_USE_BEDROCK`
     - `CLAUDE_CODE_USE_VERTEX`
     - `CLAUDE_CODE_USE_FOUNDRY`
   - Current working directory and whether it's a git repo.
   - Whether the CCP plugin is loaded (`${CLAUDE_PLUGIN_ROOT}` is set) and `.claude/ccp` is writable.
   - Best-effort note on profile config directories (e.g. `CLAUDE_CONFIG_DIR`).

3. **Interpret the results** for the user:
   - Missing launcher → they need to set up that alias/wrapper before CCP handoff or sync will work.
   - A set `ANTHROPIC_API_KEY` / `ANTHROPIC_AUTH_TOKEN` can silently override the account a profile uses — flag it if it looks unintended.
   - `CLAUDE_CODE_USE_BEDROCK/VERTEX/FOUNDRY` set means a non-default backend; confirm that's intended for these profiles.

## What this skill must never do

- Never print the value of any environment variable or secret.
- Never switch accounts, log in/out, or modify config.
- Never install plugins.
