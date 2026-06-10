# CCP — changeClaudeProfile

CCP is a local Claude Code plugin that supports a macOS workflow where you run **two Claude Code launchers from the same repository**:

- `claude-team` — Teams / work account
- `claude-max` — personal Max account

It solves two problems:

1. **Safe handoff/takeover.** You start work in one profile, run low on usage, and need to continue from the *same folder* in the other profile without losing context.
2. **Plugin alignment.** Plugins available in one profile should be discoverable and reproducible in the other — **without ever copying secrets, credentials, OAuth tokens, Keychain data, or the raw plugin cache.**

Everything CCP generates lives under `.claude/ccp/`. CCP is **review-first, apply-second**: it produces files and scripts you read before anything changes, and it never switches accounts for you.

Invocation namespace: `/ccp:<skill-name>`.

---

## Sound familiar?

If any of these is you, this is the plugin you're looking for:

- You **ran out of usage / hit the limit in Claude Teams** mid-task and want to **continue in your Claude Max** account — or the other way around.
- You use **two Claude accounts** (work + personal) and want to **switch Claude account** without losing context **in the same repo / project**.
- You run **`claude-team` and `claude-max` from the same folder** and need a safe **handoff and takeover** between them.
- You want the **same plugins available in both Claude profiles**.

`ccp` (**change Claude profile**) captures your work state in one profile and lets the other profile pick it up safely — it **never copies credentials, OAuth tokens, Keychain data, or plugin cache** between accounts.

---

## Prerequisites: the two launchers

`ccp` assumes you launch Claude Code as **`claude-team`** (Teams/work) and **`claude-max`** (personal Max) — two accounts with isolated config directories. If you don't have them yet, create them from a clone of the marketplace repo:

```bash
bash scripts/setup-profiles.sh
```

Each launcher is just `exec env CLAUDE_CONFIG_DIR="$HOME/.claude-team" claude "$@"` (and likewise for `claude-max`) — a real executable on your PATH, not a shell alias, so `ccp`'s scripts can call it. Sign into each once, then run `/ccp:profile-doctor` to verify.

---

## Install / reload CCP

CCP is distributed through the `codecraftersautomation` marketplace. Install it with:

```
/plugin marketplace add codecraftersautomation/claude-code
/plugin install ccp@codecraftersautomation
/reload-plugins
```

To develop or test it locally from a clone, add the marketplace from the repo root by path instead:

```
/plugin marketplace add /path/to/claude-code
/plugin install ccp@codecraftersautomation
```

After any change, run `/reload-plugins`. Then confirm the skills appear (they're namespaced `/ccp:...`) and run `/ccp:profile-doctor` once to verify your launchers are set up.

---

## Workflow 1 — Handoff from Team to Max (or Max to Team)

In the profile that's running low:

1. `/ccp:handoff` — writes `.claude/ccp/handoff/HANDOFF.md`, plus a mechanical workstate and a safety report.

Then:

2. Open the **same repository** with the other launcher: `claude-max` (or `claude-team`).
3. `/ccp:takeover` — reads the handoff, compares it to live git state, and reports the safe next step. It will **not** edit files until you tell it to continue.

---

## Workflow 2 — Emergency handoff (almost out of usage)

When you're about to hit the limit and tokens are scarce:

1. `/ccp:compact-handoff` — writes a short (~1000–1500 word) `COMPACT_HANDOFF.md` fast.
2. `/ccp:workstate` — *if you still have a little usage left*, capture exact git state (cheap, mechanical, makes takeover safer).

Then switch profiles and run `/ccp:takeover` as above.

---

## Workflow 3 — Plugin sync between profiles

1. `/ccp:plugin-inventory` — capture and compare plugins in both profiles → `team-plugins.txt`, `max-plugins.txt`, `PLUGIN_INVENTORY.md`.
2. `/ccp:plugin-export` — record the desired set → `PLUGINS.lock.json`.
3. `/ccp:plugin-sync-plan` — generate the plan and install scripts → `PLUGIN_SYNC_PLAN.md`, `install-missing-team.sh`, `install-missing-max.sh`.
4. **Review the generated scripts.** High-risk plugins are commented out; unknown-marketplace plugins are skipped.
5. `/ccp:plugin-apply` — choose a target profile, see the exact commands, confirm, then apply only the selected script.
6. `/reload-plugins` inside Claude Code, then re-run `/ccp:plugin-inventory` to verify alignment.

You can also run `/ccp:diff-audit` and `/ccp:safety-check` around any handoff, and `/ccp:session-brief` to capture the reasoning behind the work.

---

## Workflow 4 — Profile diagnosis

`/ccp:profile-doctor` — verifies `claude`, `claude-team`, `claude-max` exist and respond to `--version`, checks for environment overrides that could silently redirect auth (presence only — never values), and writes `.claude/ccp/PROFILE_DOCTOR.md`.

---

## Safety model

CCP is built around a hard boundary: **coordinate, never copy secrets.**

- CCP does **not** copy credentials, API keys, OAuth tokens, cookies, or `.credentials.json`.
- CCP does **not** copy Keychain data.
- CCP does **not** copy the raw Claude Code plugin cache directly between profiles.
- CCP does **not** switch accounts automatically.
- CCP **does** create handoff files, plugin inventory files, a lock file, and reviewable install plans.
- CCP **redacts** likely secrets from every report and diff it generates (see `scripts/redact-sensitive-output.sh`).
- CCP **never** auto-installs plugins with hooks, MCP servers, or LSP servers — those are surfaced and commented out for explicit review.

---

## Recommended plugin scopes

- **Project scope** — repo-specific tools that should travel with this repository (`--scope project`).
- **User scope** — generic personal tools useful across all your repos (`--scope user`).
- **Local scope** — personal tools you only want in this repo, not shared (`--scope local`).
- **Managed scope** — controlled by your organization. CCP cannot change managed plugins.

---

## Generated files

```
.claude/ccp/
├── PROFILE_DOCTOR.md           # /ccp:profile-doctor
├── handoff/
│   ├── HANDOFF.md              # /ccp:handoff
│   ├── COMPACT_HANDOFF.md      # /ccp:compact-handoff
│   ├── WORKSTATE.md            # /ccp:workstate (+ GIT_STATUS.txt, DIFF.patch, RECENT_COMMITS.txt)
│   ├── GIT_STATUS.txt
│   ├── DIFF.patch
│   ├── RECENT_COMMITS.txt
│   ├── DIFF_AUDIT.md           # /ccp:diff-audit
│   ├── SAFETY_CHECK.md         # /ccp:safety-check
│   └── SESSION_BRIEF.md        # /ccp:session-brief
└── plugins/
    ├── team-plugins.txt        # /ccp:plugin-inventory
    ├── max-plugins.txt
    ├── PLUGIN_INVENTORY.md
    ├── PLUGINS.lock.json        # /ccp:plugin-export
    ├── PLUGIN_SYNC_PLAN.md      # /ccp:plugin-sync-plan
    ├── install-missing-team.sh
    └── install-missing-max.sh
```

---

## Cleanup

The generated state is disposable. To clean up:

```bash
rm -rf .claude/ccp/handoff/
rm -rf .claude/ccp/plugins/
```

(You can remove all of `.claude/ccp/` to clear the profile report too.) The CCP plugin itself lives at `plugins/ccp/` in the marketplace repo and is unaffected.

---

## Limitations

- CCP **cannot** move active conversation memory from one profile to another — that's why handoff files exist.
- CCP **cannot** bypass account usage limits.
- CCP **cannot** make OAuth sessions interchangeable between accounts.
- CCP **cannot** guarantee a plugin is installable in the other profile if its marketplace/source is unknown — those are marked manual and skipped by the generated scripts.

---

## Skills

| Skill | Purpose |
|-------|---------|
| `/ccp:handoff` | Full handoff to the other profile |
| `/ccp:takeover` | Safely continue from a handoff |
| `/ccp:compact-handoff` | Fast emergency handoff |
| `/ccp:workstate` | Mechanical repo snapshot |
| `/ccp:diff-audit` | Audit the diff before handoff/commit |
| `/ccp:safety-check` | Is it safe to hand off / take over? |
| `/ccp:session-brief` | Human-readable session reasoning |
| `/ccp:plugin-inventory` | Compare plugins across profiles |
| `/ccp:plugin-export` | Write `PLUGINS.lock.json` |
| `/ccp:plugin-sync-plan` | Generate reviewable install plan |
| `/ccp:plugin-apply` | Apply the plan to one profile (confirmed) |
| `/ccp:profile-doctor` | Diagnose the profile/launcher setup |

## Agents

- `handoff-reviewer` — validates a handoff package before switching.
- `takeover-reviewer` — confirms the repo still matches the handoff.
- `plugin-sync-reviewer` — read-only review of plugin alignment and scope.
