# WAL Protocol (Kaizen)

**The Law:** You are a stateful operator. Chat history is a BUFFER, not storage. `SESSION-STATE.md` is your "RAM" — the only place specific details are safe across turns.

> Source attribution: distilled from halthelobster/proactive-agent v3.1.0 "WAL Protocol." Refined here with explicit triggers and OpenClaw-default-aware destinations.

---

## Trigger — SCAN EVERY MESSAGE FOR:

- ✏️ **Corrections** — "It's X, not Y" / "Actually..." / "No, I meant..."
- 📍 **Proper nouns** — Names, places, companies, products
- 🎨 **Preferences** — Colors, styles, approaches, "I like/don't like"
- 📋 **Decisions** — "Let's do X" / "Go with Y" / "Use Z"
- 📝 **Draft changes** — Edits to something being worked on
- 🔢 **Specific values** — Numbers, dates, IDs, URLs, paths

---

## The Protocol

**If ANY of these appear:**

1. **STOP** — do not start composing the response yet
2. **WRITE** — append to `~/.openclaw/workspace/SESSION-STATE.md` (template: `templates/session-state.md`)
3. **THEN** — respond

**The urge to respond is the enemy.** The detail feels obvious in context — but context will vanish. Write first.

---

## Where to Write What

| Type | Destination | Why |
|---|---|---|
| Decision in progress, current task state, open questions | `SESSION-STATE.md` | Volatile, replaced by next session's content |
| Lesson learned after the fact, recurring tool gotcha | `TOOLS.md` | Durable, distilled from `.learnings/` later |
| Behavioral change (rare, requires approval) | `AGENTS.md` | Goes through promotion gate first |
| Identity / personality / principles | **NEVER** auto-write | `SOUL.md` and `IDENTITY.md` are immutable without user approval |

---

## What Does NOT Belong in `SESSION-STATE.md`

- Long conversation logs (use `memory/working-buffer.md` for danger zone)
- Completed-task summaries (move to `memory/YYYY-MM-DD.md` when wrapping up)
- Pre-calculated math, intermediate reasoning
- Tool output dumps (link to file path instead)

If `SESSION-STATE.md` grows beyond ~100 lines, it's overloaded. Move durable items out, leave only the volatile state.

---

## Example

```
Human says: "Use the blue theme, not red"

WRONG: "Got it, blue!" (seems obvious, why write it down?)
RIGHT: Write to SESSION-STATE.md: "Theme: blue (not red)" → THEN respond
```

---

## Why This Works

The trigger is the human's INPUT, not your memory. You don't have to remember to check — the rule fires on what they say. Every correction, every name, every decision gets captured automatically.

---

## Recovery from `SESSION-STATE.md` loss

If compaction truncates `SESSION-STATE.md`:

1. Read `memory/working-buffer.md` (if active) FIRST — it has the raw exchanges
2. Extract volatile state from buffer
3. Reconstruct `SESSION-STATE.md`
4. Promote any durable lessons to `TOOLS.md` (per `lib/learning-loop.md`)

See `lib/working-buffer.md` for the full protocol.
