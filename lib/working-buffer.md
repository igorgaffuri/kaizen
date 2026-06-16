# Working Buffer Protocol (Kaizen)

**Purpose:** Capture EVERY exchange in the danger zone between memory flush and context compaction. This file survives compaction. When `SESSION-STATE.md` gets truncated, this is the recovery source.

> Source attribution: distilled from halthelobster/proactive-agent v3.1.0 "Working Buffer Protocol." Refined here with OpenClaw-default integration and explicit recovery steps.

---

## When to Activate

1. Check `session_status` before composing a response.
2. If `context.percent > 60` AND the working buffer is `INACTIVE` or stale (>24h old):
   - Create/reset `memory/working-buffer.md` from `templates/working-buffer.md`
   - Set status to `ACTIVE`, record start timestamp
3. From this message onward, log every exchange **before** responding.

If `context.percent <= 60%`, no action needed. The buffer is for the danger zone only.

---

## Format

Append to `memory/working-buffer.md` BEFORE responding:

```markdown
## [ISO-8601 timestamp] Human
[full message verbatim]

## [ISO-8601 timestamp] Agent (summary)
[1-2 line summary of response + key decisions/corrections captured]
```

---

## Rules

- **Every exchange** — no "this one isn't important." You're not the judge in the danger zone.
- **Verbatim for human** — capture exactly what was said
- **Summarized for agent** — 1-2 lines + key facts (values, names, decisions)
- **No full tool output** — link to file or summarize, don't dump JSON

---

## Why This Works

- This file is on disk → it survives compaction
- Even if `SESSION-STATE.md` wasn't updated properly, the buffer has it
- `Compaction Recovery` (below) reads this file FIRST

---

## Compaction Recovery

When waking up after compaction, OR if you suspect context loss:

1. **FIRST:** Read `memory/working-buffer.md` (if it exists and is `ACTIVE`)
2. Extract the volatile task state from buffer entries
3. Update `SESSION-STATE.md` with the current task
4. If still missing context, search `memory/YYYY-MM-DD.md` (today + yesterday)
5. If still missing, run `memory_search` over `MEMORY.md` and daily logs
6. **Present:** "Recovered from working buffer. Last task was X. Continue?"
7. **DO NOT** ask "what were we discussing?" — the buffer has it

---

## When to Deactivate

The buffer stays `ACTIVE` as long as context > 60%. When context drops back below 60% (rare, usually after compaction resets), you can:

- Set status back to `INACTIVE` in the buffer header
- Leave entries for future reference (don't delete — they're the audit trail)
- The next activation will reset and start fresh if >24h has passed

---

## What Does NOT Belong in the Buffer

- Long tool output (link or summarize)
- Code blocks > 20 lines (use `references/` or `tmp/`)
- Full file contents (use `read` and link path)
- Secrets or credentials (NEVER)

---

## Edge Cases

| Situation | Action |
|---|---|
| Buffer doesn't exist | Create from `templates/working-buffer.md` |
| Buffer exists but `Status: INACTIVE` and >24h old | Reset, set `ACTIVE` |
| Buffer is `ACTIVE` and recent | Keep appending, don't reset |
| Context jumps from 30% to 70% in one turn (huge prompt) | Create buffer immediately, log this turn as the first entry |
| Multiple sessions in parallel (different agents) | Each session has its own buffer; do not share |
