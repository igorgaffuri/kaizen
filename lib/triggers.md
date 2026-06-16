# Kaizen Triggers (drop into AGENTS.md)

**Where:** paste this block into `~/.openclaw/workspace/AGENTS.md`, **before** the `## Make It Yours` section.

---

```markdown
## 🔁 Kaizen Loop (continuous improvement skill)

**Before every response:**

1. **WAL check** — does the message contain a correction, decision, value, URL, name, or date? → Write to `SESSION-STATE.md` FIRST, then respond. See `lib/wal-protocol.md`.
2. **Learning check** — did a command fail, was I corrected, was a feature requested? → Append to `.learnings/ERRORS.md` / `LEARNINGS.md` / `FEATURE_REQUESTS.md`. See `lib/learning-loop.md`.
3. **Context check** — `session_status` reports `context.percent > 60`? → Create/reset `memory/working-buffer.md` from `templates/working-buffer.md` and log every exchange from now on. See `lib/working-buffer.md`.

**Every heartbeat (~30min, runtime-driven):**

Rotate 1-2 items from `HEARTBEAT.md`. Skip silently if nothing actionable. See `lib/heartbeat.md`.

**After every response (Proactive Surprise):**

Pause 5s. Ask: "What would genuinely delight my human that he didn't ask for?" If useful + internal: draft, log to `notes/areas/proactive-tracker.md` → "Surprises Delivered", offer inline. If external: stop. Never publish externally without approval. See `lib/reverse-prompting.md`.

**Weekly (cron: Sunday 18:00 BRT):**

- Read `notes/areas/proactive-tracker.md` and `memory/` (last 7 days)
- Formulate 1-2 fresh reverse-prompting questions (don't repeat <7d)
- Post to main session via delivery `announce`

**Monthly (cron: day 1, 10:00 BRT):**

- Read `memory/` (last 30 days)
- Detect patterns: requests 3+ times, recurring bugs, manual workflows
- Propose 1-2 automations to main session
- If no patterns, stay silent

**Tool migration (manual):**

```bash
~/.openclaw/workspace/skills/kaizen/scripts/tools-migration-check.sh \
  --old <old-tool> --new <new-tool>
```

Exit 0 = clean. Exit 1 = references remain. See `lib/tool-migration.md`.

**Compaction recovery:**

1. Read `memory/working-buffer.md` FIRST
2. Extract volatile state to `SESSION-STATE.md`
3. Search `memory/YYYY-MM-DD.md` and `MEMORY.md` if still missing
4. Present: "Recovered from working buffer. Last task was X. Continue?"

**What NEVER auto-changes:**

- `SOUL.md` / `IDENTITY.md` — immutable without explicit user approval
- `MEMORY.md` — only `memory-core` dreaming writes here, not Kaizen
- `memory/YYYY-MM-DD.md` — log only via the daily log protocol
```

---

## Why this block (and not 4-5 separate blocks)

Kaizen unifies what would otherwise be 4-5 separate triggers:
- WAL (proactive-agent)
- Learning Loop (self-improving-agent)
- Working Buffer (proactive-agent)
- Reverse Prompting (proactive-agent)
- Heartbeat rotation (proactive-agent)
- Tool Migration (proactive-agent)

One block, one set of rules, one place to update when the loop evolves.

---

## Removing Kaizen

If you uninstall Kaizen:

1. Remove this block from `AGENTS.md`
2. Delete `~/.openclaw/workspace/skills/kaizen/`
3. Remove crons that reference Kaizen patterns (check `cron action=list`)
4. Optionally: archive `SESSION-STATE.md` and `.learnings/` for future reference

The system will fall back to OpenClaw defaults (memory-core dreaming, no learning log, no proactive triggers).
