# SESSION-STATE.md (Active Task RAM)

**Purpose:** Volatile memory for the current session. Captures the **active** state of work in progress — decisions, values, URLs, names, open questions. Replaced wholesale when a new session starts (or compacted to `memory/YYYY-MM-DD.md` on wrap-up).

**Updated:** _(ISO-8601 timestamp)_
**Session:** _(session id or short label)_

---

## Current Task

_(one-paragraph summary: what we're working on, why, expected outcome)_

## Decisions Made This Session

- [ISO timestamp] Decision: ...
- [ISO timestamp] Decision: ...

## Open Questions

- [ISO timestamp] Q: ...
- [ISO timestamp] Q: ...

## Specific Values Captured

- URLs: ...
- Names: ...
- IDs: ...
- Dates: ...
- Paths: ...

## References

- Files involved: ...
- Skills used: ...
- Scripts run: ...

---

## Rules

- **Keep under ~100 lines.** When longer, move durable items to `TOOLS.md` (technical) or `AGENTS.md` (workflow) per `lib/learning-loop.md` promotion criteria.
- **NEVER include:** secrets, tokens, long tool output, full code blocks.
- **Always include:** decisions, values, names, URLs that the user said and you might forget.
- **Truncate on session end** — move to `memory/YYYY-MM-DD.md` as a daily entry, then reset.

## Relationship to Other Files

| File | Role | Lifecycle |
|---|---|---|
| `SESSION-STATE.md` | Active task RAM | Volatile, replaced per session |
| `memory/working-buffer.md` | Danger zone log (raw exchanges) | Survives compaction |
| `memory/YYYY-MM-DD.md` | Daily log | Append-only, daily rotation |
| `MEMORY.md` | Curated long-term | Distilled periodically from daily logs |
| `TOOLS.md` | Tool gotchas, lessons | Durable, promoted from `.learnings/` |
| `AGENTS.md` | Workflow rules | Durable, promoted from `.learnings/` |
| `.learnings/ERRORS.md`, `LEARNINGS.md`, `FEATURE_REQUESTS.md` | Kaizen log | Append-only, reviewed periodically |

## WAL Protocol (Write-Ahead Logging)

Whenever the user says something with a correction, decision, value, URL, name, or specific date, **write it here FIRST** before responding. See `lib/wal-protocol.md`.
