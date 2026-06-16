# Learning Loop (Kaizen)

**Purpose:** Capture errors, corrections, knowledge gaps, and feature requests to `.learnings/` for later review and promotion. Broadly applicable learnings get promoted to `TOOLS.md` or `AGENTS.md`.

> Source attribution: distilled from pskoett/self-improving-agent. Refined here with Kaizen-specific destinations and OpenClaw-default-aware promotion criteria.

---

## Detection Triggers (automatic)

Log when you notice:

### Errors → `.learnings/ERRORS.md`

- Command returns non-zero exit code
- Exception or stack trace
- Unexpected output or behavior
- Timeout or connection failure

### Corrections → `.learnings/LEARNINGS.md` (category: `correction`)

- "No, that's not right..." / "Actually, it should be..." / "That's outdated..."

### Knowledge Gaps → `.learnings/LEARNINGS.md` (category: `knowledge_gap`)

- User provides information you didn't know
- Documentation you referenced is outdated
- API behavior differs from your understanding

### Best Practices → `.learnings/LEARNINGS.md` (category: `best_practice`)

- Found a better approach for a recurring task

### Feature Requests → `.learnings/FEATURE_REQUESTS.md`

- "Can you also..." / "I wish you could..." / "Is there a way to..."

---

## Logging Format

### Learning entry (`.learnings/LEARNINGS.md`)

```markdown
## [LRN-YYYYMMDD-XXX] category

**Logged**: ISO-8601 timestamp
**Priority**: low | medium | high | critical
**Status**: pending
**Area**: backend | infra | docs | config | workflows | other

### Summary
One-line description

### Details
What happened, what was wrong, what's correct

### Suggested Action
Specific fix or improvement

### Metadata
- Source: conversation | error | user_feedback
- Related Files: path/to/file.ext
- Tags: tag1, tag2
- See Also: LRN-YYYYMMDD-XXX
- Pattern-Key: simplify.dead_code | harden.input_validation (optional, for recurring-pattern tracking)
- Recurrence-Count: 1
- First-Seen: YYYY-MM-DD
- Last-Seen: YYYY-MM-DD
```

### Error entry (`.learnings/ERRORS.md`)

```markdown
## [ERR-YYYYMMDD-XXX] skill_or_command_name

**Logged**: ISO-8601 timestamp
**Priority**: high
**Status**: pending
**Area**: backend | infra | docs | config | other

### Summary
Brief description of what failed

### Error
Actual error message or output (redacted if needed)

### Context
- Command/operation attempted
- Input or parameters used
- Environment details if relevant

### Suggested Fix
What might resolve this

### Metadata
- Reproducible: yes | no | unknown
- Related Files: path/to/file.ext
- See Also: ERR-YYYYMMDD-XXX (if recurring)
```

### Feature Request entry (`.learnings/FEATURE_REQUESTS.md`)

```markdown
## [FEAT-YYYYMMDD-XXX] capability_name

**Logged**: ISO-8601 timestamp
**Priority**: medium
**Status**: pending
**Area**: backend | infra | docs | config | workflows | other

### Requested Capability
What the user wanted to do

### User Context
Why they needed it, what problem they're solving

### Complexity Estimate
simple | medium | complex

### Suggested Implementation
How this could be built

### Metadata
- Frequency: first_time | recurring
- Related Features: existing_feature_name
```

---

## ID Generation

- `LRN-YYYYMMDD-XXX` (learning)
- `ERR-YYYYMMDD-XXX` (error)
- `FEAT-YYYYMMDD-XXX` (feature request)
- `XXX` is sequential or random 3 chars

---

## Resolving Entries

When fixed, update:

```markdown
**Status**: pending → resolved
```

Add a `### Resolution` block with timestamp, commit/PR, and notes.

Other status values: `in_progress`, `wont_fix`, `promoted`.

---

## Promotion Criteria (unified with ADL/VFM)

Kaizen merges two promotion systems:

| Source | Criterion | Target |
|---|---|---|
| **pskoett style** (recurring) | `Recurrence-Count >= 3` + seen across `2+ tasks` + within `30d window` | Tech learning → `TOOLS.md` or `AGENTS.md` |
| **ADL/VFM style** (scored) | Weighted score >= 50 (4 dimensions: High Frequency 3x, Failure Reduction 3x, User Burden 2x, Self Cost 2x) | Behavioral/structural change → `AGENTS.md` |
| **Forbidden** (ADL) | Adds complexity without verification, uses vague concepts, sacrifices stability for novelty | **REJECT** |

### Promotion targets (in priority order)

1. `TOOLS.md` — tool gotchas, configuration fixes
2. `AGENTS.md` — workflow improvements, automation rules
3. `SOUL.md` / `IDENTITY.md` — **requires explicit user approval**
4. `MEMORY.md` — **NEVER directly** (use `memory-core` dreaming instead)

### How to promote

1. Distill the learning into a concise rule or fact
2. Add to appropriate section in target file (create file if needed)
3. Update original entry: `**Status**: pending → promoted`
4. Add `**Promoted**: TOOLS.md | AGENTS.md`

---

## Recurring Pattern Detection

When logging something similar to an existing entry:

```bash
# Search first
grep -r "keyword" ~/.openclaw/workspace/.learnings/
```

If similar entry found:
- Link with `**See Also**: LRN-YYYYMMDD-XXX`
- Bump priority if issue keeps recurring
- Increment `Recurrence-Count`
- Update `Last-Seen`

If pattern hits `Recurrence-Count >= 3`:
- Promote to `TOOLS.md` (for tool/config) or `AGENTS.md` (for workflow)
- Link original entries

---

## What NEVER Goes in `.learnings/`

- Secrets, tokens, private keys, environment variables
- Full source/config files
- Long transcripts (use summaries or redacted excerpts)
- Personal/identifying user information beyond what the user has explicitly shared

Prefer short summaries or redacted excerpts over raw command output.

---

## Best Practices

- **Log immediately** — context is freshest right after the issue
- **Be specific** — future agents need to understand quickly
- **Include reproduction steps** — especially for errors
- **Link related files** — makes fixes easier
- **Suggest concrete fixes** — not just "investigate"
- **Use consistent categories** — enables filtering
- **Promote aggressively** — if in doubt, add to `TOOLS.md` or `AGENTS.md`
- **Review regularly** — see `lib/heartbeat.md` for cadence
