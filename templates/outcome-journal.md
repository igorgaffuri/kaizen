# Outcome Journal (Decisions & Follow-ups)

**Purpose:** Track decisions with a "promise to revisit" date. Anything >7d old that hasn't been revisited gets surfaced in heartbeat / weekly review.

---

## How to use

When you make a decision that warrants follow-up:

```markdown
## [YYYY-MM-DD] [DEC-ID] Decision title

**Context:** Why this decision was made
**Decision:** What was decided
**Reversibility:** easy | hard | irreversible
**Follow-up date:** YYYY-MM-DD
**Status:** open | reviewing | resolved | dropped

### Notes
- ...
```

When the follow-up date arrives, the weekly cron (`reverse-prompting-weekly`) or heartbeat surfaces it.

---

## Active Decisions

_(format: [YYYY-MM-DD] [DEC-XXX] title — follow-up YYYY-MM-DD — status)_

## Resolved Decisions

_(format: [YYYY-MM-DD resolved] [DEC-XXX] title — outcome)_

## Dropped Decisions

_(format: [YYYY-MM-DD] [DEC-XXX] title — why dropped)_

---

## Relationship to other Kaizen files

- `notes/areas/proactive-tracker.md` — ongoing ideas, surprises, questions (rolling)
- `notes/areas/outcome-journal.md` — decisions with explicit follow-up dates (this file)
- `notes/areas/recurring-patterns.md` — patterns detected from `memory/` (monthly cron)
- `.learnings/LEARNINGS.md` — raw log of corrections, gaps, best practices

## Anti-patterns

- ❌ Decisions without follow-up date (will never be revisited)
- ❌ Follow-up date too far in the future (>30d → easy to forget)
- ❌ Marking `resolved` without a real outcome entry
- ❌ Adding decisions that are too small to track (use `proactive-tracker.md` instead)
