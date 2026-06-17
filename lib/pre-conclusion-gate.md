# Pre-Conclusion Verification Gate (Kaizen)

**Purpose:** Before affirming anything non-trivial (a fact, a recommendation, a code change, a default, a "best practice"), the agent MUST verify against three tiers of evidence, in order. This is the "never assume, always verify" rule made mechanical.

> Source: distilled from agent-self-improvement literature (Reflexion paper, Addy Osmani self-improving coding agents 2026, MemGPT) and the user's TOOLS.md "REGRA ZERO — BUSCA ANTES DE AFIRMAR" (which until now applied only to the main session).

---

## The 3 tiers (in order)

Walk through these tiers before concluding. Use the LOWEST tier that gives a confident answer.

### Tier 1 — Local memory

Cheapest and most specific to this user. Check first.

- `MEMORY.md` (curated long-term facts about the user)
- `memory/YYYY-MM-DD.md` (daily logs, current + previous day)
- `notes/areas/proactive-tracker.md` (open items, follow-ups)
- `notes/areas/outcome-journal.md` (decisions and follow-ups)
- `.learnings/` (errors, corrections, knowledge gaps)

**Stop here if:** the user told you this fact, OR today's/yesterday's log records it, OR the outcome-journal has the decision.

### Tier 2 — Local docs

Project-local documentation.

- `TOOLS.md` (tool gotchas, config notes)
- `AGENTS.md` (workflow rules, behavior gates)
- `SOUL.md` / `IDENTITY.md` (persona, identity)
- `USER.md` (user preferences, contact)
- `skills/*/SKILL.md` (current skill behavior)
- Skill-specific `lib/*.md` (protocols, triggers)

**Stop here if:** the answer is in TOOLS.md (known gotcha), AGENTS.md (workflow rule), or the relevant SKILL.md (current behavior).

### Tier 3 — Web

Last resort for anything that changes after 2026-01 (knowledge cutoff) or anything the local docs don't cover.

- `web_search` (Tavily — default provider, basic or advanced depth)
- `web_fetch` (Firecrawl — for pages with JS / anti-bot)
- Fallback: `tavily_search` / `firecrawl_search` / `firecrawl_scrape`

**Use this for:** external tool behavior, API signature, library feature, version-specific default, 2026+ change, "best practice" the local docs don't already encode.

---

## What to cite

When you conclude, cite the tier you actually used:

- `[mem]` — found in `MEMORY.md` or `memory/`
- `[doc]` — found in `TOOLS.md` / `AGENTS.md` / `SKILL.md` / `USER.md`
- `[web]` — found via `web_search` / `web_fetch` (include URL)
- `[mem+web]` — local memory + external confirmation
- `[guess]` — NOT ALLOWED. If you can't find a tier, say "I don't have a confident source" and either search more or explicitly flag uncertainty.

This makes every assertion auditable.

---

## Triggers — when to apply

Apply the gate before:

- Asserting a default value, number, version, or "best practice"
- Recommending an action that touches config / scheduler / infra
- Citing external tool behavior, API signature, or library feature
- Telling the user "you should / can / must do X" about anything external
- Saying "this is how OpenClaw / systemd / Caddy / Linux works"

**Do NOT apply** for:

- Pure opinions or preferences
- User's own statements being repeated back
- Trivial file reads the user already knows the content of

---

## Concrete trigger patterns (from real sessions)

These are cases that actually happened and got flagged. Apply mechanically.

### Listing 3+ external tools, frameworks, or libraries

**Trigger:** user asks "what's the X for Y?" (e.g. "what's the vitest for testing AI agent skills?", "what eval frameworks exist?") and you respond with a list of 3+ tools.

**Required:** `web_search` FIRST, then write the list with [web] citation per tool. **Even if you remember the names** — status (acquired, deprecated, EOL, pivot) and current focus change after 2026-01.

**Why:** example: 2026-06-16 session — user asked about eval frameworks, I listed 9 tools from memory including Promptfoo as "for prompt testing." Promptfoo was acquired by OpenAI in 2026 and now focuses on AI security / red-teaming. I missed DeepEval v4.0.3, Braintrust, Arize Phoenix, Comet Opik entirely. User caught it: "Encontrou isso buscando na web?"

**Lesson:** the cost of remembering "shape" of an ecosystem is that you miss the 2026-specific deltas. Cost of searching: 3-5s.

### Citing project status (acquired, deprecated, abandoned, EOL)

**Trigger:** saying "X is OSS" / "X is maintained" / "X is the default" about any external project.

**Required:** `web_search` to confirm current status. The "shape" of a project can change without you noticing (acquisition, pivot, sunsetting).

**Why:** example: same session as above. Promptfoo homepage now opens with "Promptfoo is now part of OpenAI" — that's a material change.

### Recommending a numeric default or limit

**Trigger:** "use 1000 tokens" / "set timeout to 30s" / "keep 50MB" / "max 3 retries" — any specific number that isn't in the local docs.

**Required:** `web_search` to confirm the current best practice, OR cite a local source (`[doc]` with file:line).

### Mentioning a "current best practice"

**Trigger:** saying "the recommended way to X is Y" or "you should use Z pattern" about anything in the wider tech ecosystem.

**Required:** `web_search` for "Z best practice 2026" before stating it as recommended. Best practices churn.

---

## Cost of searching vs cost of being wrong

| Action | Cost |
|---|---|
| `web_search` (Tavily basic) | 3-5s, near-free |
| `web_fetch` (Firecrawl) | 5-15s, cheap |
| Being wrong | Retrabalho + perda de confiança do user (TOOLS.md REGRA ZERO) |

The math is obvious. When in doubt, search.

---

## Kaizen cron integration

The 4 Kaizen crons already have a `REGRA DE BUSCA` (Tier 3) embedded in their payloads. The Verification Gate extends that to also require checking Tier 1 (local memory: `memory/`, `.learnings/`, `proactive-tracker.md`) and Tier 2 (local docs: `TOOLS.md`, `SKILL.md`) BEFORE going to Tier 3.

When a cron makes a suggestion with evidence from only Tier 3 (web) without checking Tier 1 or 2, that's a violation — promote to `kaizen-learning-review-weekly`.

---

*Apply mechanically. The agent that verifies is the agent that's trusted.*
