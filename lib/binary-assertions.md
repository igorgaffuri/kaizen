# Binary Assertions for Self-Check (Kaizen)

**Purpose:** After every non-trivial output (code change, command, config edit, decision), the agent runs a checklist of binary (pass/fail) assertions to verify the work. Replaces subjective "looks good?" self-evaluation with concrete checks.

> Source attribution: distilled from MindStudio's "Binary assertions vs subjective evals" (2026). The thesis: you can't build a feedback loop from a score of "7 out of 10" — you can from a list of `pass/fail` checks that tell you exactly which properties the output did or didn't have.

---

## The Problem

Subjective self-evaluation is unreliable:

- "Did I do this right?" → "Yeah, looks good" (always)
- "Is this code clean?" → "Pretty clean" (vague)
- "Will the user accept this?" → "Probably" (no signal)

This produces no actionable signal. The agent finishes the task, says "done", and either the user catches the bug later or it ships broken.

## The Solution: Binary Assertions

After producing the output, run a checklist. Each item is a yes/no question. Any `no` means the task is NOT done — go back and fix.

```markdown
## Self-check ([task-slug])

- [ ] User asked for X — did I deliver X? (no = rewrite)
- [ ] Output is reversible (rollback path clear) (no = STOP and ask user)
- [ ] All affected files are listed (no = user is surprised later)
- [ ] Tested locally / dry-run passed (no = run the test, don't claim done)
- [ ] Documented the change (commit message / comment / log) (no = add it)
- [ ] No silent side effects (other services / configs / schedules) (no = explicit warning)
- [ ] Evidence tier cited ([mem] / [doc] / [web] — see Pre-Conclusion Gate) (no = back to gate)
- [ ] Format matches the channel's convention (Telegram compact, code block, etc) (no = reformat)
- [ ] No emoji, no "great question", no fluff (no = strip)
- [ ] If anything was uncertain, flagged explicitly with [uncertain: ...] (no = add flag)
```

If any item is `no`, the task is incomplete. Either fix it now or surface it to the user as an open item.

---

## By Output Type

Different outputs need different assertions. Default checklist (above) is the minimum; add task-specific checks on top.

### Code change (edit, refactor, new file)

- [ ] Syntax compiles / lints clean
- [ ] Existing tests still pass
- [ ] New behavior has at least one test or manual verification step
- [ ] No debug prints / `console.log` / `.DS_Store` left behind
- [ ] No unrelated changes mixed in (commit hygiene)

### Config edit (cron, systemd, nginx, caddy, OpenClaw config)

- [ ] Service reload / restart was triggered
- [ ] Status was checked AFTER restart (not before)
- [ ] User-facing impact was communicated (downtime? new port? cron change?)
- [ ] Old config backed up or diff captured
- [ ] No hardcoded secrets in the config file (use SecretRefs / env)

### Recommendation (advice, "you should X")

- [ ] Recommendation is concrete (specific command / file / value, not "consider X")
- [ ] Recommendation is reversible (or explicitly irreversible with user buy-in)
- [ ] Evidence tier cited
- [ ] Alternative considered and rejected (or noted)
- [ ] User's stated preferences (USER.md) not violated

### Cron payload / scheduled task

- [ ] Schedule (cron expr + tz) correct
- [ ] Session target appropriate (main vs isolated)
- [ ] Delivery mode correct (announce / none / webhook)
- [ ] `nextRunAtMs` reviewed
- [ ] Payload tested with `--runMode force` if high-impact

### Voice note / audio file

- [ ] Provider configured (google / minimax / etc)
- [ ] Voice matches user's preference (see USER.md → "TTS")
- [ ] Audio file in `/tmp/openclaw/` (HTML rule, but good practice for any attachment)
- [ ] Timestamp in filename (no cache bust)
- [ ] `[[audio_as_voice]]` directive present in response (for Telegram)

### Git commit / push

- [ ] Commit message is meaningful (not "fix" or "wip")
- [ ] No secrets in diff (token, key, password, .env)
- [ ] Author email is the one user wants (not always yahoo.com.br)
- [ ] Push destination is correct (main / feature branch)
- [ ] If PR: description is non-empty

---

## How to use

After completing the output, copy the relevant checklist into a temporary self-check block, fill pass/fail, and act on the failures:

```markdown
## Self-check (commit 3 binary-assertions)

- [x] User asked for binary-assertions lib — I wrote it
- [x] Output is reversible — yes (just a new .md file)
- [x] All affected files listed — lib/binary-assertions.md
- [x] Tested locally — N/A (no code, just docs)
- [x] Documented — this file + commit message
- [x] No silent side effects — none
- [x] Evidence tier cited — [doc] (MindStudio blog)
- [x] Format matches convention — markdown lib/ format, matches reflexion-loop.md
- [x] No emoji, no fluff — checked
- [x] Uncertainty flagged — none
```

If 3+ items are `no`, the task is in trouble. Surface to the user.

## Compaction survival

Binary assertions are per-task, not durable. Do NOT write them to `notes/areas/reflexion-log.md` (that's for outcome-level reflection, not pass/fail checks). The pass/fail is meant to gate the OUTPUT, not to be journaled.

If a particular assertion fails repeatedly across tasks, that's a pattern → write to `notes/areas/recurring-failures.md` and let `kaizen-pattern-automation-monthly` detect it.

---

*Pass/fail beats 7/10. Always.*
