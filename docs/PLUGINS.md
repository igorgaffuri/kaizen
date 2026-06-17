# Companion Plugins (Optional)

Kaizen (the skill) is **knowledge + reflexes** — it reads, reflects, suggests. To **act automatically** on the signals Kaizen consumes (especially error patterns), pair it with one or more **OpenClaw plugins** that hook into the runtime.

This document covers the **official companion plugin** and how to install, configure, validate, and remove it. Treat plugins as separate from the skill: code lives in `~/.openclaw/plugins/`, not inside `skills/kaizen/`.

---

## `kaizen-guards` — Auto-capture exec failures

**Purpose:** hook `after_tool_call` on the `exec` tool. When a command fails (non-zero exit, throw, or timeout), append a structured entry to `~/.openclaw/workspace/.learnings/RAW_ERRORS.md` with timestamp, command, exit code, duration, and session.

**Why it matters:** the `kaizen-learning-review-weekly` cron (Saturday 10:00 BRT) reads `RAW_ERRORS.md`, groups recurring patterns, and promotes the top three into the curated `ERRORS.md`. Without this plugin, `RAW_ERRORS.md` stays empty and the weekly review has no signal source. This is the **N1.e** signal type ("error patterns").

**Source:** lives in `~/.openclaw/plugins/kaizen-guards/index.js` (and a runtime copy at `~/.openclaw/extensions/kaizen-guards/index.js` — see Gotcha #2).

### What it writes

```markdown
## [2026-06-17T15:28:59.187Z] exec failure

**Command:** `<the failing command>`
**Error:** exit code 7
**Duration:** 1285ms
**Session:** agent:main:telegram:direct:8157279145
**Status:** pending
```

The entry is appended, not overwritten — `RAW_ERRORS.md` is append-only by design. The curator cron promotes entries to `ERRORS.md` and marks them `resolved` or `wontfix`.

---

## Installation

> **Reversible.** Disable with `openclaw plugins disable kaizen-guards`. Remove with `rm -rf ~/.openclaw/plugins/kaizen-guards ~/.openclaw/extensions/kaizen-guards` plus the entry in `openclaw.json`.

### 1. Drop the plugin source

```bash
mkdir -p ~/.openclaw/plugins/kaizen-guards
# Paste the plugin code into ~/.openclaw/plugins/kaizen-guards/index.js
```

The plugin is a single ESM file. No build step. No dependencies.

### 2. Allow the plugin (Gotcha #1)

OpenClaw does **not** auto-load non-bundled plugins unless `plugins.allow` is set. Without this, `register()` is never called and the hook never fires.

Edit `~/.openclaw/openclaw.json`:

```json
"plugins": {
  "allow": ["kaizen-guards"],
  "entries": {
    "kaizen-guards": { "enabled": true, "config": {} }
  }
}
```

To preserve auto-loading of bundled plugins (memory-core, etc.), also set:

```json
"plugins": { "bundledDiscovery": "compat", "allow": ["kaizen-guards"] }
```

### 3. Sync to runtime (Gotcha #2)

OpenClaw keeps **two copies** of every plugin:

| Path | Role |
|---|---|
| `~/.openclaw/plugins/<id>/index.js` | Source (where `openclaw plugins install` writes) |
| `~/.openclaw/extensions/<id>/index.js` | Runtime (what the gateway actually loads) |

Edits to the source **do not propagate** to the runtime. After any code change:

```bash
cp ~/.openclaw/plugins/kaizen-guards/index.js \
   ~/.openclaw/extensions/kaizen-guards/index.js
```

Or reinstall: `openclaw plugins install --force <path>`.

Symptom of forgetting this: `openclaw plugins list` shows the plugin enabled, but `register()` is never called and the hook never fires.

### 4. Restart

```bash
systemctl --user restart openclaw-gateway.service
```

The reload can also pick up `plugins.allow` automatically (see logs for `[reload] config change detected`). If the change is structural, a full restart is required.

---

## Configuration

| Key | Default | Purpose |
|---|---|---|
| `logPath` | `~/.openclaw/workspace/.learnings/RAW_ERRORS.md` | Where entries are appended |
| `maxCommandChars` | `240` | Truncate command field if longer |

Set under `plugins.entries.kaizen-guards.config`:

```json
"kaizen-guards": {
  "enabled": true,
  "config": {
    "logPath": "/custom/path/RAW_ERRORS.md",
    "maxCommandChars": 400
  }
}
```

---

## Validation

End-to-end smoke test:

```bash
# Run a known-failing command
sh -c 'exit 7'

# Wait ~1s, then check the file
cat ~/.openclaw/workspace/.learnings/RAW_ERRORS.md
```

Expected output:

```markdown
## [<ISO timestamp>] exec failure

**Command:** `sh -c 'exit 7'`
**Error:** exit code 7
**Duration:** <ms>ms
**Session:** agent:main:telegram:direct:<your-id>
**Status:** pending
```

If the file does not appear:

1. Check `openclaw plugins list | grep kaizen-guards` — must be `enabled`.
2. Check journal: `journalctl --user -u openclaw-gateway.service --since "5 min ago" | grep -i kaizen` — must show `http server listening (...)` with the plugin listed.
3. Verify the runtime copy is in sync (Gotcha #2).
4. Verify `plugins.allow` (Gotcha #1).

---

## How the hook matches the OpenClaw shape (Gotcha #3)

The `after_tool_call` event for the `exec` tool has this shape:

```js
{
  toolName: "exec",
  params: { command: "..." },
  result: {
    content: [...],
    details: {
      status: "completed",         // "completed" even on non-zero exit
      exitCode: 7,                  // real exit code lives here
      durationMs: 28,
      aggregated: "...",
      cwd: "..."
    },
    terminate: false
  },
  error: undefined                 // only set on throw / timeout, NOT on exit != 0
}
```

A non-zero exit code returns `details.status: "completed"` (not `"error"`) and **does not** populate `event.error`. The plugin checks both:

- `event.error` set → tool threw or timed out
- `event.result.details.exitCode !== 0` → command failed normally

Older plugin code that checks `result.code` or `result.details.code` will silently miss exit codes — both fields are `null` in practice.

---

## Disabling

Disable without removing:

```bash
openclaw plugins disable kaizen-guards
# or
openclaw cron update --jobId <id> --patch '{"enabled": false}'
```

Disable in config (safer, survives reinstalls):

```json
"plugins": {
  "entries": {
    "kaizen-guards": { "enabled": false }
  }
}
```

## Removing

```bash
openclaw plugins disable kaizen-guards
rm -rf ~/.openclaw/plugins/kaizen-guards
rm -rf ~/.openclaw/extensions/kaizen-guards
# Edit openclaw.json: remove the "kaizen-guards" entry from plugins.entries
systemctl --user restart openclaw-gateway.service
```

---

## Plugin vs Skill — what lives where

| Layer | Lives in | Purpose |
|---|---|---|
| **Skill** (`skills/kaizen/`) | Repo `igorgaffuri/kaizen` | Knowledge, reflexes, cron prompts, weekly reviews |
| **Plugin** (`plugins/kaizen-guards/`) | Local `~/.openclaw/plugins/` | Automated hooks that write to the workspace |

Plugins are **not** part of the skill repo. They are runtime companions. If you change a plugin, you do not need to bump the skill version. If you upgrade the skill, plugins keep working independently.

---

## Future companion plugins (roadmap)

Not implemented yet — listed here so future me knows the direction:

- `kaizen-wal-guard` — auto-update `SESSION-STATE.md` when a non-trivial task starts/ends (relieves the agent from manual WAL writes).
- `kaizen-notify-gate` — wraps outbound Telegram messages from crons, suppressing noise if the digest is empty.
- `kaizen-dream-promoter` — when `memory-core` dreaming produces a high-score memory, auto-promote to `MEMORY.md` instead of waiting for manual review.

Each will get its own section here when shipped.
