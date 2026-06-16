# Kaizen

> Continuous improvement skill for OpenClaw agents. Write first, learn continuously, survive compaction, verify before concluding, surprise with value you didn't ask for.

**Kaizen** (改善) — Japanese for "continuous improvement." A unified skill that teaches your agent to be **autonomous, expert-of-itself, and never forget** — combining self-improving pattern capture with proactive memory survival and rigorous self-verification.

**v2.0** — adds Reflexion Loop, Pre-Conclusion Verification Gate (3 tiers), Binary Assertions, WAL-Read at turn start, and the Docs Curator cron. The agent now reflects on its own work, cites evidence tiers, runs pass/fail self-checks, and recovers context across sessions. See [CHANGELOG](#v20-changelog).

## What it does

### Self-improvement loops

| Feature | Trigger | Writes to |
|---|---|---|
| **WAL Protocol** | Before every response: correction, decision, value, URL, name | `SESSION-STATE.md` |
| **WAL-Read** | Turn start, if `SESSION-STATE.md` > 24h or > 5KB | reads state to recover context |
| **Reflexion Loop** | After non-trivial task (code, workflow, decision, failure recovered) | `notes/areas/reflexion-log.md` (agent SELF-eval) |
| **Learning Loop** | After errors, corrections, feature requests | `.learnings/ERRORS.md`, `LEARNINGS.md`, `FEATURE_REQUESTS.md` |
| **Pre-Conclusion Gate** | Before any non-trivial assertion (default, version, "best practice", external tool) | Cite tier used: `[mem]` / `[doc]` / `[web]` |
| **Binary Assertions** | After every non-trivial output | Pass/fail checklist; any `no` = task incomplete |

### Memory & context survival

| Feature | Trigger | Effect |
|---|---|---|
| **Working Buffer** | Context > 60% (via `session_status`) | `memory/working-buffer.md` (raw exchanges) |
| **Heartbeat System** | Every ~30min (runtime-driven) | `HEARTBEAT.md` checklist (rotate 1-2 items) |
| **Compaction Recovery** | After context truncation | Read `working-buffer.md` FIRST |

### Proactive behaviors

| Feature | Trigger | Effect |
|---|---|---|
| **Reverse Prompting** | Weekly cron (Sunday 18:00 BRT) | 1-2 fresh questions to main session |
| **Pattern Detection** | Monthly cron (day 1, 10:00 BRT) | Propose automations for 3+ repetitions |
| **Tool Migration** | Manual: when deprecating/swapping a tool | `scripts/tools-migration-check.sh` |
| **Proactive Surprise** | After every response (5s pause) | Inline draft + tracker entry |
| **Docs Curator** | Weekly cron (Saturday 11:00 BRT) | Detect drift between `memory/` + `.learnings/` and main docs, propose patches |

## The 5 crons

| Cron | Schedule (BRT) | Cron expr | What it does |
|---|---|---|---|
| **kaizen-daily-digest** | Daily 13:30 | `30 13 * * *` | Read what was done (memory + learnings + tracker + outcome journal) of current + previous day → understand context → remind open items → suggest concrete next steps. Telegram-compact output. |
| **kaizen-reverse-prompting-weekly** | Sunday 18:00 | `0 18 * * 0` | Read tracker + last 7d memory → 1-2 fresh reverse-prompting questions → post to Telegram. |
| **kaizen-learning-review-weekly** | Saturday 10:00 | `0 10 * * 6` | Promote `.learnings/` items with `Recurrence-Count >= 3` to `TOOLS.md` / `AGENTS.md`. |
| **kaizen-docs-curator-weekly** | Saturday 11:00 | `0 11 * * 6` | Detect descompasso between `memory/` + `.learnings/` and `AGENTS.md`/`TOOLS.md`/`SKILL.md` → propose patch (NUNCA aplicar sozinho). |
| **kaizen-pattern-automation-monthly** | Day 1, 10:00 | `0 10 1 * *` | Detect patterns in last 30d memory (3+ repetitions) → propose automations. |

All 5 are `isolated agentTurn` with `delivery: announce → telegram`. See [docs/SETUP.md](docs/SETUP.md) for payload examples.

## The lib/ protocols (deep dives)

- [WAL Protocol](lib/wal-protocol.md) — write before respond, read at turn start
- [Reflexion Loop](lib/reflexion-loop.md) — agent SELF-evaluation (Shinn 2023)
- [Pre-Conclusion Verification Gate](lib/pre-conclusion-gate.md) — 3-tier evidence (mem → doc → web)
- [Binary Assertions](lib/binary-assertions.md) — pass/fail self-checks (MindStudio 2026)
- [Learning Loop](lib/learning-loop.md) — capture errors, corrections, knowledge gaps
- [Working Buffer](lib/working-buffer.md) — compaction recovery
- [Heartbeat](lib/heartbeat.md) — periodic self-checks
- [Reverse Prompting](lib/reverse-prompting.md) — surface unknown unknowns
- [Tool Migration](lib/tool-migration.md) — deprecation checklist

## What it does NOT do (intentional)

- ❌ Automated git commits
- ❌ Auto-edits of `SOUL.md` / `IDENTITY.md` (immutable without user approval)
- ❌ Hook activation by default
- ❌ External network calls (the crons DO use `web_search`/`web_fetch` when triggered — that's the only network surface)
- ❌ Automatic external messaging (digest is opt-in via cron; surprise is draft-only)
- ❌ Self-modification of crons

## Installation

```bash
# Clone
git clone https://github.com/igorgaffuri/kaizen.git ~/.openclaw/workspace/skills/kaizen

# Add trigger to AGENTS.md (copy from lib/triggers.md)
# Optionally add the 5 crons (see docs/SETUP.md)

# Restart
openclaw restart
```

## Documentation

- [SKILL.md](SKILL.md) — full feature description and triggers
- [docs/SETUP.md](docs/SETUP.md) — cron configuration (5 crons, payload examples)
- [docs/MIGRATION.md](docs/MIGRATION.md) — migrate from `proactive-agent` + `self-improving-agent`
- [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) — design decisions

## v2.0 Changelog

What changed from v1.x:

- **Reflexion Loop** (new) — agent writes post-mortem SELF-evaluation after non-trivial tasks. Complements WAL (user input) and Learning Loop (external feedback). Source: Shinn et al. 2023.
- **Pre-Conclusion Verification Gate** (new) — before any non-trivial assertion, walk through 3 evidence tiers (mem → doc → web) and cite which one you used. Replaces ad-hoc "I think X" with auditable `[mem]` / `[doc]` / `[web]` citation.
- **Binary Assertions** (new) — pass/fail self-check checklist after every non-trivial output. Replaces subjective "looks good?" with concrete checks. Source: MindStudio 2026.
- **WAL-Read at turn start** (new) — symmetric operation to WAL's write. Reads `SESSION-STATE.md` if > 24h or > 5KB, recovering context from previous sessions.
- **Docs Curator cron** (new) — weekly scan that detects drift between `memory/` + `.learnings/` (source of truth) and `AGENTS.md`/`TOOLS.md`/`SKILL.md` (docs), proposes small reversible patches. NUNCA aplica sozinho.
- **Daily Digest output format** (changed) — Telegram-compact: `Daily DD/MM HH:MM BRT` + `Pendencias:` / `Sinais:` / `Sugestoes:` sections, bullet `-`, no blank lines, max 3 items/section, suppress empty sections. Replaces verbose 2026-06-15 format.
- **Search Rule** (new, embedded in all 5 crons) — explicit `web_search` / `web_fetch` rule with knowledge cutoff 2026-01, replacing implicit "achar que sabe" behavior.

## License

MIT — see [LICENSE](LICENSE).

## Credits

- [pskoett/self-improving-agent](https://github.com/peterskoett/self-improving-agent) — log + promote + recurring pattern detection
- [halthelobster/proactive-agent v3.1.0](https://github.com/halthelobster/proactive-agent) — WAL Protocol, Working Buffer, Heartbeat, Reverse Prompting, Proactive Surprise
- Shinn et al. 2023, "Reflexion: an autonomous agent with dynamic memory" (Princeton / MIT) — Reflexion Loop
- Addy Osmani, "Self-Improving Coding Agents" (2026) — agent autonomy patterns
- MindStudio, "Binary assertions vs subjective evals" (2026) — pass/fail self-check pattern
