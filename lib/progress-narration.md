# Progress Narration (kaizen v1.2)

When the agent runs multi-step operations, narrate progress to the user so they
can distinguish "working" from "stuck/broken."

This pattern is the **visibility** counterpart to the Self-Correction Loop
(quality). They coexist: narration keeps the user informed, the loop retries
internally when output fails assertions.

---

## When to trigger

Fire narration when **ANY** of these holds:

- 3+ tool calls planned for the current turn
- Long-running op (deploy, migration, build, integration) — single op > 30s
- Tool call returns non-OK (error, fail, partial, exit code != 0)
- Tool call **ABORTS** (SIGTERM, missing result, transport failure) — distinct from error
- > 60s of tool execution total without a user-visible message
- > 2 min since the last narration tick
- User message arrives mid-task (treat as narration reset boundary)

If **none** hold: stay silent. Do NOT narrate trivial single-call ops like
`ls`, `read`, `cat`, single `web_search`. (Igor's rule: short responses,
no filler.)

---

## Format

Fixed template, parseable, **no emoji** (Igor's rule):

```
[step N/M: <description>] <status>
[next: <preview>]
```

Status values: `ok` | `partial` | `fail` | `abort` | `retrying`

Each tick: 1-2 lines max. No markdown bold/italic. No emoji.

### Examples

Routine:
```
[step 1/5: validating SESSION-STATE] ok
[next: 2/5 patch plugin]
```

Error (DO narrate errors immediately, do NOT bury):
```
[step 3/5: openclaw cron add] fail: scope upgrade pending approval
[next: 4/5 patch sqlite directly (workaround)]
```

Abort (NEW — friday's contribution, was missing in v1.1):
```
[step 2/5: restart gateway] abort: SIGTERM on child process
[next: 3/5 retry with nohup wrapper]
```

Continuing after fix:
```
[step 4/5: patch sqlite] ok
[note: was blocked on scope, used direct insert as workaround]
[next: 5/5 verify]
```

---

## Anti-patterns

- ❌ Narrate trivial single tool calls (`ls`, `read`, `cat`, single `web_search`)
- ❌ Group all progress into the final summary (defeats the purpose)
- ❌ Stop narrating at the first error — **do the opposite**; errors are highest-priority
- ❌ Skip "continuing after fix" narration
- ❌ Substitute the final summary with progress (do BOTH)
- ❌ Use emoji in narration (Igor's global rule, no exceptions)
- ❌ Internal tool reasoning exposed as narration (narration is for the user, not self-talk)

---

## Reset / Boundary

- Each user-visible message counts as a narration tick.
- A new user message mid-task is a **narration reset boundary**: acknowledge
  the user's input, then continue or pivot.
- Task complete → write a final summary (NOT just a narration tick; the
  summary is a different artifact).
- Task error → narrate the error AND the next attempt. Never silently retry.

---

## Interaction with other patterns

| Pattern | Relation |
|---|---|
| **Self-Correction Loop** (v1.1) | Loop handles quality retries; narration tells user. If a retry fires, narrate: `[retry 2/3: <reason>]`. |
| **Binary Assertions** | Assertions run on the FINAL output, not on narration ticks. Don't bloat ticks with checklist output. |
| **WAL Protocol** | WAL is for the NEXT session. Narration is for the CURRENT user. Different audiences. |
| **Heartbeat** | Heartbeat is autonomous self-improvement. Narration is task-driven user updates. |

---

## Trigger block (copy into AGENTS.md)

```markdown
## Progress Narration (kaizen v1.2)

During multi-step operations, narrate progress to the user so they can
distinguish "working" from "stuck":

- Trigger if ANY: 3+ tool calls planned, single op > 30s, tool error/abort,
  > 60s without user-visible message, > 2 min since last tick, user message
  arrives mid-task.
- Format: `[step N/M: <desc>] <ok|partial|fail|abort|retrying>` + `[next: <preview>]`.
  1-2 lines, no emoji, no markdown.
- Don't narrate trivial single-call ops.
- Don't stop at first error — narrate CONTINUATION after fix too.
- Do BOTH progress narration AND a final summary.
- On tool ABORT (SIGTERM, missing result, transport fail) — narrate
  IMMEDIATELY. Distinct from error: an abort may be transient and
  recoverable; an error usually needs decision.
```

Full spec: `skills/kaizen/lib/progress-narration.md`.

---

## Failure case evidence (see `.learnings/ERRORS.md`)

- **2026-06-17 Sia session** (this workspace): 19 min of silence during
  gateway restart + plugin debug, with multiple user re-prompts
  ("Puta que pariu, você fica parando", "Olaaaa", "Parou de novo").
- **2026-06-17 friday session** (separate server, same Igor): 14 min of
  silence during 12-step kaizen update, user saw a transient `tool-error`
  and assumed the agent had halted. Recurrence: 2 (same pattern, two agents,
  one user, one day).

The trigger that would have caught both: "> 60s without user-visible
message" and "tool call ABORTS → narrate immediately."

---

## Version

v1.0 (2026-06-17). Implements proposal by agent friday (other server),
with Sia's critique applied (added "abort" trigger, fixed anti-pattern
"stop at first error", fixed format spec). Acceptance criteria met:
- [x] `lib/progress-narration.md` exists with Trigger block + anti-patterns
- [x] `SKILL.md` feature table updated
- [x] ERRORS.md evidence captured
- [x] Trigger block is copy-pasteable
- [x] Smoke test added in `scripts/smoke-test.sh`