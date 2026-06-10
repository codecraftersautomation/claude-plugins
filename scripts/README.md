# scripts

Repo-level setup helpers (not part of any single plugin).

| Script | Purpose |
|--------|---------|
| [`setup-profiles.sh`](setup-profiles.sh) | Create the `claude-team` and `claude-max` launchers that the **Change Claude Profile (`ccp`)** plugin coordinates. Each launcher runs Claude Code with its own `CLAUDE_CONFIG_DIR`, giving you two isolated accounts (work ⇄ personal) — no shared credentials. |

## Quick start

```bash
# from a clone of this repo
bash scripts/setup-profiles.sh
```

Then log into each profile once (interactive):

```bash
claude-team     # sign in with your Teams / work account
claude-max      # sign in with your personal Max account
```

Override defaults via env vars:

```bash
INSTALL_DIR=~/.local/bin TEAM_DIR=~/.claude-work MAX_DIR=~/.claude-personal \
  bash scripts/setup-profiles.sh
bash scripts/setup-profiles.sh --force        # overwrite existing launchers
```

**Platform:** tested on macOS; Linux uses the identical mechanism. Windows isn't supported yet (it needs `.cmd`/`.ps1` shims and a different config path) — the script exits cleanly there with guidance.

These scripts create no accounts and never touch credentials, tokens, or Keychain data.
