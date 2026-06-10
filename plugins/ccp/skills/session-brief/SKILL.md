---
name: session-brief
description: Write a human-readable summary of the current Claude session — the reasoning, decisions, and context behind the work — combined with current repo state. Use when the user asks for a "session summary", "brief", "what did we do/decide", "write up this session", or to complement /ccp:workstate before a profile switch. Writes .claude/ccp/handoff/SESSION_BRIEF.md. Explains that WORKSTATE = mechanical repo state while SESSION_BRIEF = reasoning and context.
---

# CCP: session-brief

Capture the *thinking* of this session — the part that lives in the conversation and would otherwise be lost when the user switches to another Claude profile. Where the workstate records what the repo looks like, the session brief records why it looks that way and where the reasoning was heading.

## Steps

1. **Summarize the session from conversation context:**
   - What the user set out to do and why.
   - Key decisions and the reasoning/tradeoffs behind them.
   - Approaches tried, what worked, what was abandoned and why.
   - Open questions and things still undecided.
   - Anything the next session would be surprised to learn the hard way.

2. **Combine with repository state.** If `.claude/ccp/handoff/WORKSTATE.md` exists, reference it; otherwise note the current branch and modified files so the narrative is grounded in real changes. (You can run `/ccp:workstate` first if you want the mechanical snapshot to cite.)

3. **Write `.claude/ccp/handoff/SESSION_BRIEF.md`** as readable prose — sections, not a raw dump.

4. **Include this distinction near the top** so readers use the right file for the right thing:

   > **WORKSTATE** = mechanical repo state (branch, diff, commits).
   > **SESSION_BRIEF** = reasoning, decisions, and context.

## Quality bar

Write for a competent stranger. The value here is the *why* — the decisions and dead-ends that aren't visible in the diff. Keep secrets out of the prose.

## What this skill must never do

- Never switch accounts or touch credentials/OAuth/Keychain data.
- Never install plugins.
