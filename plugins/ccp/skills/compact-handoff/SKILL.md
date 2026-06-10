---
name: compact-handoff
description: Emergency, fast handoff when the current Claude account is almost out of usage/tokens and there's no time for a full handoff. Use this when the user says they're "about to hit the limit", "running out", "almost out of usage", "quick handoff", "emergency handoff", or needs to switch to the other profile (claude-team <-> claude-max) immediately. Writes a short .claude/ccp/handoff/COMPACT_HANDOFF.md (~1000-1500 words) with objective, state, next 3 steps, risks, and an exact takeover prompt.
---

# CCP: compact-handoff

A speed-optimized handoff for when usage is nearly exhausted and a full `/ccp:handoff` would cost too many tokens. Be fast and concrete. Aim for **roughly 1000–1500 words** — enough to resume, not a novel.

## Steps

1. **Write `.claude/ccp/handoff/COMPACT_HANDOFF.md` immediately.** Don't run heavy tooling first — tokens are scarce. Capture from conversation context:
   - **Objective** — what we're trying to accomplish.
   - **Current state** — where things stand right now, one tight paragraph.
   - **Changed files** — the files touched this session (best recollection; the takeover side will verify against git).
   - **Next 3 steps** — the immediate, ordered actions to continue.
   - **Risks** — what could go wrong or be lost.
   - **Exact takeover prompt** — a copy-pasteable prompt the next profile can run verbatim to resume.

2. **Point to workstate.** End with: "If you still have a little usage left, run `/ccp:workstate` to capture exact git state before switching." Workstate is cheap mechanical truth and makes the takeover far safer.

3. **Tell the user how to resume:** open the same repo with `claude-max` or `claude-team`, then run `/ccp:takeover`.

## Tone

Terse and high-signal. Skip background the next session can re-derive from the code. Prioritize: what to do next, what not to break, how to verify.

## What this skill must never do

- Never switch accounts or touch credentials/OAuth/Keychain data.
- Never install plugins.
- Don't burn the user's remaining tokens on long tool runs — prose first, optional `/ccp:workstate` second.
