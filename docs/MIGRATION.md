# Migration from proactive-agent + self-improving-agent

**If you already have either of these skills installed**, follow this guide to consolidate into Kaizen. **Do not uninstall them first** — that's where the risk is. Migrate in waves, validate between.

---

## Pre-Migration Audit

```bash
# 1. Check what's currently installed
ls ~/.openclaw/workspace/skills/
# Expect: proactive-agent/ self-improving-agent/ skill-vetter/ ...

# 2. Check existing crons
cron action=list
# Note any crons from proactive-agent (reverse-prompting, pattern-automation) or self-improving-agent

# 3. Check workspace files
ls ~/.openclaw/workspace/
# Look for: SESSION-STATE.md, .learnings/, notes/areas/proactive-tracker.md, templates/working-buffer.md

# 4. Check AGENTS.md
grep -A2 -B1 "proactive-agent\|self-improving\|WAL\|Working Buffer" ~/.openclaw/workspace/AGENTS.md
```

Save this output. You'll diff against it post-migration.

---

## Wave 1: Install Kaizen (additive, no breaking changes)

1. Drop `kaizen/` into `~/.openclaw/workspace/skills/kaizen/`
2. Add the trigger block from `lib/triggers.md` to your `AGENTS.md` (BEFORE the `## Make It Yours` section)
3. **DO NOT** remove the old triggers yet
4. Restart OpenClaw
5. **Validate:** the system now has BOTH old and Kaizen triggers. Some duplication is OK temporarily.

```bash
openclaw restart
# Verify skill loaded
ls ~/.openclaw/workspace/skills/kaizen/SKILL.md
```

## Wave 2: Replace templates

If you already have these files from proactive-agent, replace with Kaizen's:

| File | Source |
|---|---|
| `~/.openclaw/workspace/templates/working-buffer.md` | `kaizen/templates/working-buffer.md` (identical structure, refined wording) |
| `~/.openclaw/workspace/HEARTBEAT.md` | Use `kaizen/lib/heartbeat.md` content as the new `HEARTBEAT.md` |
| `~/.openclaw/workspace/notes/areas/proactive-tracker.md` | Keep your existing tracker; Kaizen uses the same format |
| `~/.openclaw/workspace/notes/areas/outcome-journal.md` | `kaizen/templates/outcome-journal.md` (NEW) |
| `~/.openclaw/workspace/notes/areas/recurring-patterns.md` | `kaizen/templates/recurring-patterns.md` (NEW) |
| `~/.openclaw/workspace/SESSION-STATE.md` | `kaizen/templates/session-state.md` (NEW) |
| `~/.openclaw/workspace/.learnings/LEARNINGS.md` | Initialize per `kaizen/lib/learning-loop.md` (NEW) |
| `~/.openclaw/workspace/.learnings/ERRORS.md` | Initialize (NEW) |
| `~/.openclaw/workspace/.learnings/FEATURE_REQUESTS.md` | Initialize (NEW) |

**Before overwriting**, diff against the proactive-agent versions to make sure you don't lose data.

## Wave 3: Consolidate crons

```bash
cron action=list
```

For each cron that overlaps with Kaizen:

| Existing cron | Kaizen equivalent | Action |
|---|---|---|
| `reverse-prompting-weekly` (proactive-agent) | `kaizen-reverse-prompting-weekly` | Disable old, add Kaizen version |
| `pattern-automation-monthly` (proactive-agent) | `kaizen-pattern-automation-monthly` | Disable old, add Kaizen version |
| `Memory Dreaming Promotion` (memory-core) | unchanged | KEEP — Kaizen does NOT replace this |
| Any `simplify-and-harden` cron from self-improving-agent | (no equivalent) | Disable if exists |

```bash
# Disable old
cron action=update --jobId <old-job-id> --patch '{"enabled": false}'

# Add new from kaizen/docs/SETUP.md
# ... (see SETUP.md for the cron JSON payloads)
```

## Wave 4: Remove old skills (only after 1+ week of Kaizen-only operation)

**DO NOT** do this immediately. Run with both for at least 1 week. Verify:

- ✅ Working buffer activates at 60%
- ✅ `.learnings/` gets entries from real interactions
- ✅ Reverse prompting cron delivers on Sunday
- ✅ Pattern detection cron runs on day 1
- ✅ Tool migration script works

After 1+ week, remove the old skills:

```bash
# Archive first (don't delete)
mv ~/.openclaw/workspace/skills/proactive-agent ~/.openclaw/workspace/skills/.archive/proactive-agent-$(date +%Y%m%d)
mv ~/.openclaw/workspace/skills/self-improving-agent ~/.openclaw/workspace/skills/.archive/self-improving-agent-$(date +%Y%m%d)

# Remove old trigger blocks from AGENTS.md
# (search for "proactive-agent" / "self-improving" sections)

# Remove old cron jobs (after disabling)
cron action=remove --jobId <id>
```

## Wave 5: Update TOOLS.md / AGENTS.md promoted content

Kaizen's promotion criteria (unified ADL/VFM + pskoett) replaces 2 separate systems. Review `TOOLS.md` and `AGENTS.md`:

- Are there entries that were promoted by either old system that Kaizen would reject (vague, low-recurrence, unverified)?
- Mark them `[review]` for user to decide.

---

## Post-Migration Verification

```bash
# 1. Kaizen loaded
ls ~/.openclaw/workspace/skills/kaizen/{SKILL.md,lib,scripts}

# 2. Trigger block in AGENTS.md
grep -A3 "## 🔁 Kaizen Loop" ~/.openclaw/workspace/AGENTS.md

# 3. Old crons disabled
cron action=list | grep -B1 -A5 '"enabled": false'

# 4. New crons active
cron action=list | grep "kaizen-"

# 5. Tool migration script works
~/.openclaw/workspace/skills/kaizen/scripts/tools-migration-check.sh --old __test__
# expected: OK: zero references

# 6. .learnings/ initialized
ls ~/.openclaw/workspace/.learnings/

# 7. Templates in place
test -f ~/.openclaw/workspace/SESSION-STATE.md && echo "OK"
test -f ~/.openclaw/workspace/notes/areas/proactive-tracker.md && echo "OK"
```

---

## Rollback

If Kaizen doesn't work for you:

1. Remove the Kaizen trigger block from `AGENTS.md`
2. Restore the old `proactive-agent` / `self-improving-agent` blocks (you kept them in Wave 1)
3. Re-enable the old crons: `cron action=update --jobId <id> --patch '{"enabled": true}'`
4. Move `kaizen/` to `~/.openclaw/workspace/skills/.archive/`
5. Restart

Your data is preserved because we never overwrote `TOOLS.md` / `AGENTS.md` / `MEMORY.md` / `memory/`.
