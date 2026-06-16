# Architecture & Design Decisions

This document captures **why** Kaizen is structured the way it is. Read this before suggesting structural changes.

---

## Core Principle

**Kaizen unifies two skills that overlap heavily but solve slightly different problems.** The unification favors:

1. **OpenClaw defaults are sacred.** Kaizen does NOT replace `memory-core`, `MEMORY.md` management, or session/channel routing. It adds behavior on top.
2. **One trigger block, not 5.** Multiple triggers = maintenance burden + drift. Kaizen ships a single `AGENTS.md` block (`lib/triggers.md`) that captures the entire loop.
3. **Promotion has a gate.** Anything written to `SOUL.md` / `IDENTITY.md` / `MEMORY.md` requires explicit user approval. Kaizen is a learner, not a self-editor of identity.
4. **Drafts over actions.** Proactive Surprise is draft-only. Never publish externally without approval.
5. **Survives compaction.** Working Buffer is the canonical recovery source. `SESSION-STATE.md` is the canonical "RAM" during a session. `MEMORY.md` is the canonical long-term curated memory.

---

## File Layout Rationale

```
kaizen/
├── SKILL.md                 # Single source of truth for "what is Kaizen"
├── README.md                # Public overview (shorter, friendlier)
├── LICENSE                  # MIT
├── lib/                     # Protocol details (deep dives)
│   ├── wal-protocol.md
│   ├── learning-loop.md
│   ├── working-buffer.md
│   ├── heartbeat.md
│   ├── reverse-prompting.md
│   ├── tool-migration.md
│   └── triggers.md          # Drop-in AGENTS.md block
├── templates/               # Drop-in markdown templates
│   ├── working-buffer.md
│   ├── session-state.md
│   ├── outcome-journal.md
│   └── recurring-patterns.md
├── scripts/
│   └── tools-migration-check.sh
└── docs/
    ├── SETUP.md
    ├── MIGRATION.md
    └── ARCHITECTURE.md      # This file
```

**Why `lib/` and `templates/` separate?**

- `lib/` is for the agent to read. Detailed protocols with rationale, anti-patterns, examples.
- `templates/` is for the agent to copy. Drop-in blank structures with brief headers.

**Why one `triggers.md` in `lib/`?**

Because the trigger block in `AGENTS.md` is the entry point. It should be a single, copy-pasteable block. Detail is in the other `lib/` files.

---

## Memory Hierarchy (the canonical model)

```
session (volatile)
  └─ SESSION-STATE.md          ← WAL writes here, replaced per session
  └─ memory/working-buffer.md  ← danger zone, survives compaction
                                ↓
daily (append-only)
  └─ memory/YYYY-MM-DD.md      ← raw daily log
                                ↓
curated (distilled)
  └─ MEMORY.md                 ← memory-core dreaming promotes here (NOT Kaizen)
                                ↓
lessons (durable)
  └─ TOOLS.md                  ← tech gotchas promoted from .learnings/
  └─ AGENTS.md                 ← workflow improvements promoted from .learnings/
                                ↓
immutable (gate required)
  └─ SOUL.md                   ← NEVER auto-edited
  └─ IDENTITY.md               ← NEVER auto-edited
```

**Why no overlap between Kaizen and `memory-core`?**

`memory-core` (OpenClaw built-in) does the **automatic** promotion of high-weight recalls from short-term memory to `MEMORY.md`. Kaizen does the **manual** promotion of lessons captured in `.learnings/`. They are orthogonal:

- `memory-core`: "what does the user seem to value / use frequently?"
- Kaizen: "what did the user explicitly correct me on, and what should future agents know?"

Mixing them would conflate signal sources. Better to keep them separate.

---

## Promotion Criteria (unified)

Kaizen merges two promotion systems from the source skills:

| System | Source | Criterion | When to use |
|---|---|---|---|
| Recurring pattern | pskoett | `Recurrence-Count >= 3` + `2+ tasks` + `30d window` | Tech gotcha, recurring bug, repeated tool mistake |
| Weighted score | proactive-agent ADL/VFM | Score >= 50 (4 dimensions, see below) | Behavioral/structural change to the agent's own rules |

**ADL/VFM dimensions:**

| Dimension | Weight | Question |
|---|---|---|
| High Frequency | 3x | Will this be used daily? |
| Failure Reduction | 3x | Does this turn failures into successes? |
| User Burden | 2x | Can human say 1 word instead of explaining? |
| Self Cost | 2x | Does this save tokens/time for future-me? |

**Forbidden (ADL):**

- ❌ Adds complexity to "look smart" — fake intelligence prohibited
- ❌ Changes that can't be verified worked
- ❌ Vague concepts ("intuition", "feeling") as justification
- ❌ Sacrifices stability for novelty

**Why merge?** Because the two systems were 80% overlapping. The pskoett recurrence test is great for tech learnings. The ADL/VFM score is great for behavioral/structural changes. Using only one would lose the other.

---

## Crons (the autonomous loop)

Kaizen ships 3 recommended crons, all `isolated agentTurn` (autonomous, not prompting):

| Cron | Schedule | Purpose |
|---|---|---|
| `kaizen-reverse-prompting-weekly` | Sunday 18:00 BRT | Ask 1-2 fresh reverse-prompting questions |
| `kaizen-pattern-automation-monthly` | Day 1, 10:00 BRT | Detect 3+ patterns, propose automations |
| `kaizen-learning-review-weekly` | Saturday 10:00 BRT | Promote recurring `.learnings/` items, link related |

**Why `isolated` and not `systemEvent`?**

A `systemEvent` cron sends a prompt to the **main session**. That requires the main session to be available and paying attention. For autonomous maintenance, you want the cron to **do the work** in an isolated session and **announce** the result.

If main session is busy with the user, an isolated cron won't interrupt. If main session is idle, the announcement arrives when the user comes back.

This is the lesson from `halthelobster/proactive-agent v3.1.0` "Autonomous vs Prompted Crons" — verified, not just text.

---

## Why This Skill Does NOT Include Hooks

pskoett's `self-improving-agent` has an optional hook (`openclaw hooks enable self-improvement`) that runs at session start as a reminder. We deliberately did NOT include a hook because:

1. Hooks run before the agent has context — they can prompt actions without situational awareness
2. Hooks bypass the normal `AGENTS.md` trigger path, making debugging harder
3. The reminder pattern is already covered by the `Before every response` block in `lib/triggers.md`

If you want session-start reminders, add them to your `ONBOARDING.md` or `AGENTS.md` startup section manually.

---

## What "OpenClaw-Native" Means Here

Kaizen is "OpenClaw-native" in the sense that:

- ✅ It uses OpenClaw's `cron` system, not external schedulers
- ✅ It uses OpenClaw's `session_status` for context tracking
- ✅ It writes to OpenClaw's standard workspace files (`AGENTS.md`, `TOOLS.md`, etc.)
- ✅ It respects OpenClaw's defaults (`memory-core` is NOT replaced)
- ❌ It does NOT use OpenClaw-specific APIs that don't exist in other agents
- ❌ It does NOT depend on OpenClaw's session routing for core loop

This means a future port to Claude Code, Codex, or other agents would require:
- Replacing the cron jobs with the host's scheduler
- Replacing `session_status` with whatever the host provides for context tracking
- Adjusting the trigger block for the host's prompt structure

The `lib/` and `templates/` content is portable. The `docs/SETUP.md` cron JSON is not.

---

## Open Questions (intentionally unresolved)

1. **Should Kaizen ever auto-promote to `MEMORY.md`?** Currently NO (`memory-core` does this). But what if a learning is super important and should bypass the dreaming cycle? Decision: NO, keep separation of concerns. If you really need it in `MEMORY.md`, do it manually.

2. **Should `proactive-tracker.md` be one file or many?** Currently one file. If it grows huge, split by category (`tracker-prompts.md`, `tracker-surprises.md`, etc). But keep simple for now.

3. **Should the `pattern-automation-monthly` cron also surface outcome-journal items >30d?** Currently NO. Different cadences: patterns are detected from raw memory, outcomes are revisited per their follow-up date. Don't conflate.

4. **Should the working buffer survive multiple sessions (per-agent, not per-session)?** Currently NO — buffer is per-session. If a user wants long-running context across sessions, that's what `SESSION-STATE.md` and `MEMORY.md` are for.

---

## Future Work (NOT in v1.0.0)

- A `kaizen-doctor.sh` script that audits the workspace and reports missing files
- A `kaizen-migrate.sh` script that automates `docs/MIGRATION.md`
- A `lib/context-budget.md` for fine-grained context-percentage triggers (warn at 50%, buffer at 60%, emergency dump at 80%)
- Auto-promotion to `MEMORY.md` for high-confidence learnings (with explicit user opt-in)

These are deliberate omissions. v1.0.0 ships the core loop. Extensibility comes after validation.
