# Tool Migration Checklist (Kaizen)

**When:** deprecating a tool, renaming, or switching to a new system. **Text changes ≠ behavior changes.** References-mortas cause silent failures weeks later.

> Source attribution: distilled from halthelobster/proactive-agent v3.1.0 "Tool Migration Checklist." Refined here with the bundled script and OpenClaw-specific paths.

---

## Before Declaring Done

1. Run `scripts/tools-migration-check.sh --old <old-name> --new <new-name>` from the workspace.
2. If exit code 1 (references remaining), apply the suggested `sed` replacements and re-run.
3. Verify exit code 0.
4. Check `cron action=list` for any crons still referencing the old tool.
5. Update `TOOLS.md`, `AGENTS.md`, `HEARTBEAT.md`, all `SKILL.md` files.

---

## Script Usage

```bash
# From workspace root
~/.openclaw/workspace/skills/kaizen/scripts/tools-migration-check.sh \
  --old <old-tool-name> \
  --new <new-tool-name> \
  --path ~/.openclaw/workspace

# Dry-run against non-existent (expect "OK: zero references")
~/.openclaw/workspace/skills/kaizen/scripts/tools-migration-check.sh --old __test_nonexistent__

# Print sed commands without applying
~/.openclaw/workspace/skills/kaizen/scripts/tools-migration-check.sh \
  --old <old> --new <new> --apply
```

### Exit Codes

- `0` — no references to `--old` found (migration clean)
- `1` — references remain (script printed locations and suggested `sed` lines)
- `2` — usage error (missing `--old` or invalid `--path`)

### Scope

Scans recursively from `--path` (default: `$HOME/.openclaw/workspace`):
- `*.md`, `*.sh`, `*.json`, `*.yaml`, `*.yml`, `*.toml`, `*.service`
- Skips binary files (`--binary-files=without-match`)

### OpenClaw cron check

```bash
# List all cron jobs and grep prompts
cron action=list | grep -B2 -A20 '<old-tool>'

# Or use the migration script with --include-crons flag (future feature)
```

---

## Migration Workflow (canonical)

1. **Identify the old tool name** — exact string as it appears in code/docs
2. **Run scan** with `--old <name>`. If references exist, see where
3. **Apply sed** for each unique file:

   ```bash
   sed -i 's|<old-name>|<new-name>|g' path/to/file
   ```

4. **Re-run scan** to confirm exit 0
5. **Update crons** if any reference the old tool (use `cron action=update`)
6. **Update documentation** — `TOOLS.md` (technical), `AGENTS.md` (workflows), `HEARTBEAT.md` (if mentioned)
7. **Update all skills** that referenced the old tool — check `~/.openclaw/workspace/skills/*/SKILL.md`
8. **Test the new tool** end-to-end before declaring done
9. **Promote the migration** to `.learnings/LEARNINGS.md` (category: `best_practice`) so future agents know

---

## Example: Migrating "openclaw message send" to "msg-cli send"

```bash
# 1. Scan
~/.openclaw/workspace/skills/kaizen/scripts/tools-migration-check.sh \
  --old "openclaw message send" --new "msg-cli send"

# 2. Apply sed for each file listed
# (script outputs suggested sed commands when --apply is set)

# 3. Re-scan
# (expect exit 0)

# 4. Check crons
cron action=list | grep -B1 -A5 "openclaw message"

# 5. Update docs
# TOOLS.md, AGENTS.md, etc
```

---

## What the Script Does NOT Cover

- **Code references outside the workspace** (e.g., `/etc/openclaw/`, `/usr/local/sbin/`)
- **Binary file references** (compiled code, package names)
- **Comments-only references** (e.g., `# TODO: replace openclaw with X`)
- **URL references** (use `web_search` or manual review)

For those, do a manual `grep -r <old-name> / --include='*' 2>/dev/null | head -20` and review.

---

## Verification: Test the New Tool

After migration, actually run the new tool. "Code exists" ≠ "feature works."

```bash
# 1. Run old command — should fail or be unavailable
<old-command>  # expect: command not found

# 2. Run new command — should work
<new-command>  # expect: success

# 3. Trigger a cron that uses the new tool (manually or wait)
cron action=run <job-id>

# 4. Check logs
journalctl -u openclaw-gateway --since "5m ago"
```

---

## Anti-Patterns

- ❌ Updating only the prompt text, not the actual mechanism
- ❌ Running `sed` on the script's own output without reviewing
- ❌ Skipping cron check
- ❌ Declaring done before testing end-to-end
- ❌ Not promoting the migration to `.learnings/` (so it gets re-done wrong next time)
