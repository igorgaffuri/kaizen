# Recurring Patterns Log

**Purpose:** Track requests, workflows, and bug patterns that appear 3+ times. When a pattern hits `Recurrence-Count >= 3`, propose automation.

**Auto-populated by:** monthly cron `pattern-automation-monthly` (day 1, 10:00 BRT).
**Manual edits:** OK for patterns you spot before the cron runs.

---

## Format

```markdown
## [YYYY-MM-DD detected] [PAT-XXX] Pattern title

**Pattern-Key:** stable identifier (e.g., `simplify.dead_code`, `harden.input_validation`, `manual.systemctl_check`)
**Recurrence-Count:** N
**First-Seen:** YYYY-MM-DD
**Last-Seen:** YYYY-MM-DD
**Tasks observed:** task-id-1, task-id-2, task-id-3

### Description
What keeps happening, in 1-2 sentences.

### Proposed Automation
What could be built to eliminate the manual repetition.

### Effort Estimate
small | medium | large

### Status
detected | proposed | approved | implemented | dropped
```

---

## Detected Patterns (pending review)

_(cron populates this section)_

## Approved & Implemented

_(format: [YYYY-MM-DD] [PAT-XXX] title — implementation summary)_

## Dropped

_(format: [YYYY-MM-DD] [PAT-XXX] title — why dropped)_

---

## Detection Algorithm (cron)

1. Read `memory/YYYY-MM-DD.md` for the last 30 days
2. Extract:
   - User requests that appear 3+ times
   - Bug/error messages that appear 3+ times
   - Manual workflow steps the user mentioned 3+ times
3. For each pattern:
   - Generate a stable `Pattern-Key`
   - Check `LEARNINGS.md` for existing entry with that key
   - If found: increment `Recurrence-Count`, update `Last-Seen`
   - If not: create new entry
4. Surface all patterns with `Recurrence-Count >= 3` to main session
5. Update `proactive-tracker.md` → "Surprises Delivered"

---

## Relationship to Other Files

- `proactive-tracker.md` — when a pattern is acted on, log there too
- `outcome-journal.md` — if automation is approved, link to a decision
- `.learnings/LEARNINGS.md` — if the pattern is a recurring tool gotcha, also log there

## Anti-patterns

- ❌ Pattern detection without `Pattern-Key` (can't dedupe)
- ❌ Patterns without effort estimate (can't prioritize)
- ❌ Approved patterns without implementation summary
- ❌ Counting 3 mentions of the same word in 1 day as "recurring" (must span 2+ tasks/days)
