---
name: kaizen
version: 1.0.0
description: "Continuous improvement skill for OpenClaw agents. Combines self-improving pattern capture (pskoett) with proactive memory/context survival (halthelobster). Survives compaction, learns from every interaction, surfaces what you didn't ask for."
author: igorgaffuri
license: MIT
source: https://github.com/igorgaffuri/kaizen
---

# Kaizen — Continuous Agent Improvement

**The shokunin loop for AI agents: write → learn → survive → surprise.**

Kaizen (改善) is Japanese for "continuous improvement." This skill unifies two proven patterns into a single, OpenClaw-native loop:

- **Self-improving pattern capture** (pskoett/self-improving-agent) — log errors, corrections, and feature requests to `.learnings/`, promote broadly-applicable learnings to project memory.
- **Proactive memory & context survival** (halthelobster/proactive-agent v3.1.0) — WAL Protocol, Working Buffer, Heartbeat System, Reverse Prompting, Proactive Surprise.

The result: a single skill that teaches your agent to **write first, learn continuously, survive compaction, and surprise you with value you didn't ask for**.

---

## What This Skill Does

| Feature | Trigger | Writes to |
|---|---|---|
| **WAL Protocol** | Before every response: correction, decision, value, URL, name | `SESSION-STATE.md` |
| **Reflexion Loop** | After non-trivial task (code change, multi-step workflow, decision with trade-offs, failure recovered) | `notes/areas/reflexion-log.md` (agent SELF-eval; see `lib/reflexion-loop.md`) |
| **Self-Correction Loop** | After Binary Assertions fails on a non-trivial output (max 3 retries; circuit breaker) | `memory/working-buffer.md` → `## Self-Correction State` (see `lib/self-correction-loop.md`) |
| **Pre-Conclusion Gate** | Before any non-trivial assertion (default, version, "best practice", external tool behavior) | Cite tier used: `[mem]` / `[doc]` / `[web]` (see `lib/pre-conclusion-gate.md`) |
| **Binary Assertions** | After every non-trivial output (code, config, command, recommendation) | Pass/fail checklist; any `no` = task incomplete (see `lib/binary-assertions.md`) |
| **Learning Loop** | After errors, corrections, feature requests | `.learnings/ERRORS.md`, `LEARNINGS.md`, `FEATURE_REQUESTS.md` |
| **Working Buffer** | Context > 60% (via `session_status`) | `memory/working-buffer.md` |
| **Heartbeat System** | Every ~30min (runtime-driven) | `HEARTBEAT.md` checklist (rotate 1-2 items) |
| **Daily Digest** | Daily cron (13:30 BRT) | Telegram (main session) — formato compacto: `Daily DD/MM HH:MM BRT` + `Pendencias:`/`Sinais:`/`Sugestoes:` |
| **Reverse Prompting** | Weekly cron (Sunday 18:00 BRT) | `notes/areas/proactive-tracker.md` + Telegram |
| **Learning Review** | Weekly cron (Saturday 10:00 BRT) | `TOOLS.md`, `AGENTS.md`, `MEMORY.md` (gated) + Telegram |
| **Pattern Detection** | Monthly cron (day 1, 10:00 BRT) | `notes/areas/proactive-tracker.md` + Telegram |
| **Tool Migration** | Manual: when deprecating/swapping a tool | Run `scripts/tools-migration-check.sh` |
| **Proactive Surprise** | After every response (5s pause) | Inline draft + tracker entry |
| **Compaction Recovery** | After context truncation | Read `working-buffer.md` FIRST |

---

## Cron Schedule (source of truth)

Live source: `openclaw cron action=list` / `~/.openclaw/workspace/.learnings/ERRORS.md` (when schedules change).

| Cron | Owner | Schedule (BRT) | Cron expr | Stagger | What it does |
|---|---|---|---|---|---|
| **kaizen-daily-digest** | kaizen | Daily 13:30 | `30 13 * * *` | 120s | Read what was done (memory + learnings + tracker + outcome journal) of current + previous day → understand context → remind open items that need user action → suggest concrete next steps. Output: `Daily DD/MM HH:MM BRT` + `Pendencias:`/`Sinais:`/`Sugestoes:` (see `kaizen-digest-format`). |
| **kaizen-reverse-prompting-weekly** | kaizen | Sunday 18:00 | `0 18 * * 0` | 60s | Read tracker + last 7d memory → 1-2 fresh reverse-prompting questions → post to Telegram. |
| **kaizen-learning-review-weekly** | kaizen | Saturday 10:00 | `0 10 * * 6` | 90s | Promote `.learnings/` items with `Recurrence-Count >= 3` to `TOOLS.md` / `AGENTS.md`. |
| **kaizen-pattern-automation-monthly** | kaizen | Day 1, 10:00 | `0 10 1 * *` | 120s | Detect patterns in last 30d memory (3+ repetitions) → propose automations. |
| **kaizen-docs-curator-weekly** | kaizen | Saturday 11:00 | `0 11 * * 6` | 90s | Detect descompasso entre `memory/` + `.learnings/` (source of truth) e `AGENTS.md`/`TOOLS.md`/`SKILL.md` (docs) → propor patch (NUNCA aplicar sozinho). |
| **Memory Dreaming Promotion** | memory-core | Every 6h | `0 */6 * * *` | 300s | Promote weighted short-term recalls to `MEMORY.md` (managed by `memory-core`, not kaizen). |

> **Note:** All Kaizen crons use `sessionTarget: "isolated"` (autonomous `agentTurn`) with `delivery: announce → telegram:8157279145`. Memory-core dreaming is `delivery: none` (writes locally only). If you change a schedule here, also update the cron via `cron action=update` — this table is documentation, not config.

### Digest Output Format (kaizen-digest-format)

Compact Telegram-only format used by `kaizen-daily-digest`:

```
Daily DD/MM HH:MM BRT
Pendencias:
- descricao curta da pendencia - pergunta/decisao pendente
- ...
Sinais:
- descricao curta do sinal observado
- ...
Sugestoes:
- (acao|melhoria|automacao) descricao. Esforco: pequeno|medio|grande.
- ...
```

Rules: no blank lines between sections, bullet `-` (not `•`), no markdown bold/italic (literal in Telegram), no `[N3.a]` prefix on items (use a single `(refs: ...)` footer line), max 3 items per section (extras omitted with `(+N secundarias omitidas)`), suppress empty sections, 1-2 lines per item.

### Search Rule (embedded in all Kaizen cron payloads)

Kaizen cron sessions run `isolated` and do **not** load `TOOLS.md` automatically. The "REGRA ZERO — BUSCA ANTES DE AFIRMAR" from `TOOLS.md` is therefore **embedded directly** in each cron's `payload.message` (see `docs/SETUP.md` → "Regra de Busca"). The agent is instructed to use `web_search` / `web_fetch` (Tavily or Firecrawl) before asserting anything about external tools, official docs, defaults, or best practices, and to cite the source URL.

---

## What This Skill Does NOT Do (intentional)

- ❌ **No automated git commits** — you commit when ready
- ❌ **No SOUL.md/IDENTITY.md auto-edits** — immutable without your approval
- ❌ **No hook activation by default** — triggers in `AGENTS.md` are safer and more debuggable
- ❌ **No external network calls** — everything is local markdown
- ❌ **No automatic external messaging** — Proactive Surprise is draft-only, never published
- ❌ **No cron auto-creation** — you opt-in per cron (see `docs/SETUP.md`)

---

## Installation

### Option 1: Local install (recommended for development)

```bash
# Drop into your OpenClaw skills folder
cp -r kaizen/ ~/.openclaw/workspace/skills/

# Add the unified trigger to your AGENTS.md
# (copy from lib/triggers.md → paste before "## Make It Yours")

# Optionally add crons (see docs/SETUP.md)
```

### Option 2: ClawdHub (when published)

```bash
clawdhub install kaizen
```

### Restart

```bash
openclaw restart
```

---

## Triggers (the unified loop)

### Before Every Response

1. **WAL check** — does the user's message contain a correction, decision, value, URL, proper noun, or specific date? If yes, **write to `SESSION-STATE.md` FIRST**, then respond.
2. **Learning check** — did a command fail, did the user correct you, or did the user request a missing feature? If yes, append to the appropriate `.learnings/` file.
3. **Context check** — run `session_status`. If `context.percent > 60` and the working buffer is INACTIVE or stale (>24h), create/reset `memory/working-buffer.md` from `templates/working-buffer.md` and start logging every exchange.

### Every Heartbeat (~30min, runtime-driven)

Rotate 1-2 items from `HEARTBEAT.md`:

- **Memory check** (low cost) — context %, MEMORY.md review, SESSION-STATE staleness
- **Tracker check** (low cost) — `proactive-tracker.md` items >7d overdue
- **Self-healing** (medium cost) — only if something visibly broke
- **Proactive Surprise** (high cost) — only if you have a genuinely useful draft

If nothing actionable, stay silent (`HEARTBEAT_OK`).

### Weekly (cron: Sunday 18:00 BRT)

- Read `notes/areas/proactive-tracker.md` and `memory/` (last 7 days)
- Formulate 1-2 fresh reverse-prompting questions
- Post to main session (Telegram) with delivery `announce`
- Log to tracker

### Monthly (cron: day 1, 10:00 BRT)

- Read `memory/` (last 30 days)
- Detect patterns: requests 3+ times, recurring bugs, manual workflows appearing 3+ times
- Propose 1-2 automations to main session
- If no patterns, stay silent

### Manual: Tool Migration

```bash
./scripts/tools-migration-check.sh --old <old-tool> --new <new-tool>
```

Exit 0 = migration clean. Exit 1 = references remaining (apply suggested `sed`).

### After Every Response: Proactive Surprise

Pause 5 seconds. Ask: *"What would genuinely delight my human that he didn't ask for?"*

- If the answer is useful and internal: draft it, log to `proactive-tracker.md` → "Surprises Delivered", offer inline ("enquanto tava nisso, rascunhei X — vê se te serve").
- If the answer requires external action: **stop**. Never publish externally without approval.

---

## Architecture

```
kaizen/
├── SKILL.md                       # This file
├── README.md                      # Public overview
├── LICENSE                        # MIT
├── lib/                           # Protocol details
│   ├── wal-protocol.md
│   ├── learning-loop.md
│   ├── working-buffer.md
│   ├── heartbeat.md
│   ├── reverse-prompting.md
│   ├── tool-migration.md
│   └── triggers.md                # Drop-in AGENTS.md block
├── templates/                     # Drop-in markdown templates
│   ├── working-buffer.md
│   ├── session-state.md
│   ├── outcome-journal.md
│   └── recurring-patterns.md
├── scripts/
│   └── tools-migration-check.sh
└── docs/
    ├── SETUP.md                   # Cron configuration
    ├── MIGRATION.md               # Migrate from proactive-agent + self-improving-agent
    └── ARCHITECTURE.md            # Design decisions
```

---

## OpenClaw Default Integration

Kaizen does **not** replace OpenClaw's built-in systems. It **integrates** with them:

| OpenClaw Default | Kaizen Interaction |
|---|---|
| `memory-core` (dreaming) | Remains primary source for `MEMORY.md`. Kaizen does NOT write to MEMORY.md. |
| `AGENTS.md` | Kaizen writes "tech learnings" here. Behavioral rules → ADL/VFM gate first. |
| `TOOLS.md` | Kaizen writes "tool gotchas" promoted from `.learnings/`. |
| `SOUL.md` / `IDENTITY.md` | **NEVER touched** by Kaizen. Immutable without explicit user approval. |
| `memory/YYYY-MM-DD.md` | **NEVER touched** by Kaizen. Already exists. |
| `HEARTBEAT.md` | Kaizen provides the checklist content (replace empty file with `HEARTBEAT.md` content). |
| Sessions / channels | Kaizen uses standard `cron` for autonomous work, never publishes externally without approval. |

**Implication:** if you already use OpenClaw's defaults, installing Kaizen is additive. If you already have `proactive-agent` or `self-improving-agent` installed, follow `docs/MIGRATION.md` to consolidate.

---

## Promoted Learning Criteria (unified)

Kaizen merges two promotion criteria into one:

| Source | Criterion | Target |
|---|---|---|
| **pskoett style** (recurring) | `Recurrence-Count >= 3` + seen across `2+ tasks` + within `30d window` | Tech learning → `TOOLS.md` or `AGENTS.md` |
| **ADL/VFM style** (scored) | Weighted score >= 50 (4 dimensions: High Frequency 3x, Failure Reduction 3x, User Burden 2x, Self Cost 2x) | Behavioral/structural change → `AGENTS.md` |
| **Forbidden** (ADL) | Adds complexity without verification, uses vague concepts, sacrifices stability for novelty | **REJECT** |

Promotion targets (in priority order):
1. `TOOLS.md` — tool gotchas, configuration fixes
2. `AGENTS.md` — workflow improvements, automation rules
3. `SOUL.md` / `IDENTITY.md` — **requires explicit user approval**
4. `MEMORY.md` — **NEVER directly** (use `memory-core` dreaming instead)

---

## Quick Sanity Check (after install)

```bash
# 1. Working buffer template exists
test -f ~/.openclaw/workspace/templates/working-buffer.md && echo "OK"

# 2. Skill files accessible
ls ~/.openclaw/workspace/skills/kaizen/{lib,templates,scripts}

# 3. Script executable
test -x ~/.openclaw/workspace/skills/kaizen/scripts/tools-migration-check.sh && echo "OK"

# 4. Tool migration dry-run
~/.openclaw/workspace/skills/kaizen/scripts/tools-migration-check.sh --old __nonexistent_test__
# expected: "OK: zero references..."

# 5. AGENTS.md has Kaizen trigger block
grep -A2 "## 🛠 Kaizen Loop" ~/.openclaw/workspace/AGENTS.md
```

---

## License

MIT — see `LICENSE`. Use, modify, redistribute. No warranty.

## Credits

- **pskoett/self-improving-agent** — log + promote + recurring pattern detection
- **halthelobster/proactive-agent v3.1.0** — WAL Protocol, Working Buffer, Heartbeat, Reverse Prompting, Proactive Surprise
- Both merged, deduplicated, and OpenClaw-default-aware into this single skill.

---

*Every day, ask: How can I improve myself? How can I surprise my human?*
