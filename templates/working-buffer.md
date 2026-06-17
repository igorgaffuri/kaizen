# Working Buffer (Danger Zone Log)

**Purpose:** Capture EVERY exchange between memory flush and context compaction. This file survives compaction. When `SESSION-STATE.md` gets truncated, this is the recovery source.

**Status:** INACTIVE
**Started:** _(timestamp when context first crossed 60%)_
**Trigger:** `session_status` reports `context.percent > 60`

---

## How to use

1. When context crosses 60% threshold:
   - If buffer is `INACTIVE` or stale (>24h old): clear it, set status to `ACTIVE`, record start timestamp.
   - If buffer is already `ACTIVE`: keep appending.
2. **Every message after 60%**: append a section in the format below BEFORE responding.
3. After compaction: read this file FIRST, extract context to `SESSION-STATE.md`.
4. Leave buffer as-is until next 60% threshold clears it again.

---

## Format

```markdown
## [ISO-8601 timestamp] Human
[their full message, verbatim]

## [ISO-8601 timestamp] Agent (summary)
[1-2 sentence summary of your response + key decisions/corrections/names captured]
```

---

## Why this works

- This file is on disk — it survives compaction.
- Even if `SESSION-STATE.md` wasn't updated, the buffer has it.
- Compaction Recovery protocol reads this FIRST.

## The rule

Once context hits 60%, EVERY exchange gets logged. No exceptions. No "this one's not important." You're not the judge in the danger zone — the buffer is.

---

## Active log (entries go below this line)


---

## Self-Correction State

Used by the [Self-Correction Loop](../lib/self-correction-loop.md). Persisted
here so it survives compaction.

```yaml
retry_count: 0
last_failure_iso: null
last_failed_assertions: []
last_task_verbatim: ""
```

Reset to `retry_count: 0` when:
- Binary Assertions passes
- New day (cron `kaizen-daily-digest` 13:30 BRT)
- User sends an unrelated message
