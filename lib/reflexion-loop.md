# Reflexion Loop (Kaizen)

**Purpose:** After every non-trivial task, the agent writes a SELF-reflexion entry to `notes/areas/reflexion-log.md`. This is the agent's own post-mortem — not a capture of user input (that's the WAL) and not a capture of errors (that's the Learning Loop).

> Source attribution: distilled from Shinn et al. 2023, "Reflexion: an autonomous agent with dynamic memory" (Princeton / MIT). Refined here with concrete triggers, OpenClaw-default-aware destination, and a small template.

---

## Why Reflexion (not just WAL or Learning Loop)

| Loop | Captures | Triggered by |
|---|---|---|
| **WAL** | User input: corrections, decisions, names, URLs | Every user message |
| **Learning Loop** | External feedback: errors, corrections, knowledge gaps | Errors, user corrections |
| **Reflexion** | Agent SELF-evaluation: what worked, what didn't, what to change | End of non-trivial task |

The three are complementary. Reflexion is the only one that asks the agent to *judge its own work* — a verbal self-reflection that compounds across tasks.

---

## Trigger — when to write a reflexion entry

Write a reflexion entry when the task involved any of:

- **Code change** (edit, refactor, fix, config) — write after the change is applied and verified
- **Multi-step workflow** (3+ steps with tool calls) — write at the end
- **Decision with trade-offs** (chose X over Y for some reason) — write the rationale and what you'd do differently
- **Failure recovered from** (something broke, you fixed it) — write what broke and the root cause
- **User said "bom", "show", "ok", "perfeito"** — that's a positive signal worth reflecting on
- **User said "não", "errado", "para", "quebrou"** — that's a negative signal worth reflecting on

**Do NOT write** for trivial Q&A, acknowledgements, or pure lookups (file read, status check).

---

## Schema (template at `templates/reflexion-log.md`)

```markdown
## [ISO-8601 timestamp] [task slug]

**Task:** [1-line description of what was done]
**Outcome:** [success | partial | failure]
**What worked:** [bullet — technique, decision, or pattern that paid off]
**What didn't:** [bullet — mistake, dead-end, or wasted effort]
**Root cause (if failure):** [bullet — why it didn't work, 1 level deep]
**Change for next time:** [bullet — concrete adjustment to make]
**Tied to:** [session-id | memory file | cron | external system, if relevant]
```

Keep entries to 5-8 bullets total. This is a journal, not an essay.

---

## How to write (good vs bad)

**Bad:**
> "I did the thing. It went fine. Maybe next time I'll be faster."

**Good:**
> "**What worked:** cross-checking `telegram/send` log after `message` tool reported `delivered: true` caught the ghost-delivery bug. **What didn't:** assumed the tool's return value was authoritative — should've known better after the first time. **Change for next time:** always grep the `telegram/send` log line before reporting success to user."

The good version is **specific**, **attributable** (you know exactly what to do next time), and **verifiable** (a future agent could check whether you actually did it).

---

## Promotion path

Reflexion entries are private to the agent (not user-facing). They are not promoted to `TOOLS.md` or `AGENTS.md` directly. Instead, the `kaizen-learning-review-weekly` cron (Sáb 10h BRT) reads `reflexion-log.md` along with `.learnings/` and:

- If a `What didn't` or `Change for next time` bullet appears 3+ times in 30 days → promote to `TOOLS.md` (recurring gotcha) or `AGENTS.md` (recurring workflow issue)
- If a single `Root cause` is novel and not in `.learnings/ERRORS.md` yet → add as new entry

This keeps reflexion low-friction (write freely) but ensures patterns surface.

---

## Compaction survival

Because `notes/areas/reflexion-log.md` lives in the workspace, it survives compaction. The agent does NOT need to copy reflexion entries to `SESSION-STATE.md` — the file itself is the durable record.

If the file grows past ~100KB, archive entries older than 90 days to `notes/areas/reflexion-log.archive-YYYY-MM.md`.

---

## Quick Sanity Check

```bash
# Did I write a reflexion entry after the last non-trivial task?
ls -la ~/.openclaw/workspace/notes/areas/reflexion-log.md
tail -20 ~/.openclaw/workspace/notes/areas/reflexion-log.md

# Are recurring patterns showing up?
grep -c "Change for next time:" ~/.openclaw/workspace/notes/areas/reflexion-log.md
```

---

*Compounds across tasks. The agent that reflects is the agent that improves.*
