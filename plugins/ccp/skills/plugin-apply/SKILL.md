---
name: plugin-apply
description: Apply a generated plugin sync plan to one profile, only after explicit user confirmation. Use when the user has reviewed /ccp:plugin-sync-plan output and says "apply the plugin plan", "install the missing plugins", or "sync now". Asks which profile (team/max/both), shows the exact commands first, requires confirmation, then runs only the selected generated script. Afterward tells the user to run /reload-plugins and re-verify with /ccp:plugin-inventory.
---

# CCP: plugin-apply

Execute the reviewed sync plan — carefully, and only with the user's explicit go-ahead. This is the only CCP skill that changes profile state, so it is deliberately gated.

## Steps

1. **Confirm the plan exists.** Read `.claude/ccp/plugins/PLUGIN_SYNC_PLAN.md` and the relevant `install-missing-*.sh` script. If they're missing, run `/ccp:plugin-sync-plan` first.

2. **Ask the user which target profile** to apply to:
   - **team** (`claude-team`)
   - **max** (`claude-max`)
   - **both**

   For **both**, apply them as two separate, individually-confirmed steps — never as one silent batch.

3. **Show the exact commands first.** Run the apply script in its default dry-run mode so the user sees precisely what would execute (and what is commented out / skipped):
   ```bash
   bash "${CLAUDE_PLUGIN_ROOT}/scripts/plugin-apply.sh" team        # dry run
   bash "${CLAUDE_PLUGIN_ROOT}/scripts/plugin-apply.sh" max         # dry run
   ```

4. **Require explicit confirmation.** Only after the user clearly approves, run with `--yes` for the chosen profile:
   ```bash
   bash "${CLAUDE_PLUGIN_ROOT}/scripts/plugin-apply.sh" team --yes
   # or
   bash "${CLAUDE_PLUGIN_ROOT}/scripts/plugin-apply.sh" max --yes
   ```
   This runs only that profile's generated script. High-risk and unknown-marketplace plugins remain commented out unless the user uncommented them during review.

5. **After applying**, tell the user to run:
   ```
   /reload-plugins
   ```
   Then re-run `/ccp:plugin-inventory` to verify the profiles are now aligned.

## Guardrails

- Never apply without showing the commands and getting explicit confirmation.
- Never auto-uncomment high-risk installs on the user's behalf.
- Never touch credentials/OAuth/Keychain data or copy plugin cache directly.
