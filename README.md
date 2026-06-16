# Kaizen

> Continuous improvement skill for OpenClaw agents. Survives compaction, learns from every interaction, surfaces what you didn't ask for.

**Kaizen** (改善) — Japanese for "continuous improvement." A unified skill that combines two proven patterns:

1. **Self-improving pattern capture** (pskoett/self-improving-agent)
2. **Proactive memory & context survival** (halthelobster/proactive-agent v3.1.0)

The result: a single, OpenClaw-native loop that teaches your agent to **write first, learn continuously, survive compaction, and surprise you with value you didn't ask for**.

## What it does

- **WAL Protocol** — captures corrections, decisions, names, URLs **before** responding
- **Learning Loop** — logs errors, corrections, and feature requests to `.learnings/`
- **Working Buffer** — survives context compaction at 60%+ threshold
- **Heartbeat System** — periodic self-improvement checks (rotated, not exhaustive)
- **Reverse Prompting** — weekly pro-active questions to surface unknown unknowns
- **Pattern Detection** — monthly scan of `memory/` for recurring requests
- **Tool Migration** — reference-checklist when deprecating/swapping tools
- **Proactive Surprise** — drafts unsolicited value after every response

## What it does NOT do

- ❌ Automated git commits
- ❌ Auto-edits of `SOUL.md` / `IDENTITY.md` (immutable without your approval)
- ❌ Hook activation by default
- ❌ External network calls
- ❌ Automatic external messaging (Proactive Surprise is draft-only)

## Installation

```bash
# Clone
git clone https://github.com/igooor7/kaizen.git ~/.openclaw/workspace/skills/kaizen

# Add trigger to AGENTS.md (copy from lib/triggers.md)
# Optionally add crons (see docs/SETUP.md)

# Restart
openclaw restart
```

## Documentation

- [SKILL.md](SKILL.md) — full feature description and triggers
- [docs/SETUP.md](docs/SETUP.md) — cron configuration
- [docs/MIGRATION.md](docs/MIGRATION.md) — migrate from `proactive-agent` + `self-improving-agent`
- [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) — design decisions

## License

MIT — see [LICENSE](LICENSE).

## Credits

- [pskoett/self-improving-agent](https://github.com/peterskoett/self-improving-agent) — log + promote + recurring pattern detection
- [halthelobster/proactive-agent v3.1.0](https://github.com/halthelobster/proactive-agent) — WAL Protocol, Working Buffer, Heartbeat, Reverse Prompting, Proactive Surprise
