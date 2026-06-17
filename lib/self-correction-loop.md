# Self-Correction Loop (circuit breaker 3x)

When a response fails Binary Assertions, the agent self-dispatches a retry turn
with explicit correction context. Maximum 3 retries per "task attempt"; on the
4th fail, the agent escalates to the user.

This is **Approach A** (instruction-based). It depends on the agent running
Binary Assertions and following the dispatch rule. It is NOT enforced by a
plugin hook. For hard enforcement, see Approach B (TODO: `lib/self-correction-loop.hook.md`).

---

## When to trigger

The loop fires when **all three** conditions hold:

1. Binary Assertions has at least one `no` on a non-trivial output
   (code, config, command, recommendation, structured doc)
2. The response would normally be the FINAL output to the user (not a
   intermediate step like a tool-call explanation)
3. `retry_count < 3` (read from `memory/working-buffer.md` or, if absent,
   `SESSION-STATE.md` → `## Self-Correction State`)

If the response is for a heartbeat poll, a tool-call intermediate step, a
self-talk check, or a `NO_REPLY`-equivalent silent response, **skip the loop**.

---

## Flow

```
[T] Response drafted
    ↓
[T] Binary Assertions checklist (6 items — see lib/binary-assertions.md)
    ↓ all YES → finalize
    ↓ any NO
        ↓
        [T] Read `retry_count` from working-buffer.md
        ↓
        [T] If retry_count < 3:
        │     - retry_count++
        │     - Update working-buffer.md with new count + failed assertions
        │     - Dispatch new turn in CURRENT session with prompt:
        │       (see template below)
        │     - Do NOT finalize the current response to the user yet.
        │       Return a minimal "self-correcting" notice if needed.
        ↓
        [T] If retry_count >= 3:
              - Do NOT dispatch retry
              - Finalize the response honestly:
                "Auto-correção falhou após 3 tentativas.
                 Bloqueio: <description of what failed>.
                 <what was actually delivered, even if partial>.
                 Preciso de input humano para destravar."
```

### Retry prompt template

```
[Self-Correction Loop — Tentativa N/3]

Tarefa original (verbatim do user):
<quote the user's exact original message>

Resposta anterior falhou nas assertions:
- <failed assertion 1>: <why it failed>
- <failed assertion 2>: <why it failed>
...

Ação: refaça a tarefa do zero, evitando esses erros específicos.
Não repita a mesma resposta. Se a tarefa não é factível no estado
atual, declare isso honestamente em vez de re-tentar com respostas
parciais.

Constraints:
- Continue no mesmo modelo.
- Não consulte `memory/` por novas entradas (apenas o working-buffer).
- Não dispare novos hooks ou crons; responda só com a tarefa.
```

---

## State

Add a `## Self-Correction State` block to `memory/working-buffer.md`:

```yaml
retry_count: 0          # incremented on each failure
last_failure_iso: null  # ISO 8601 of last failed assertion
last_failed_assertions: []  # list of strings, e.g. ["task_completa: missing config"]
last_task_verbatim: ""  # user's original message at the time of failure
```

If `memory/working-buffer.md` does not exist, the agent must create it from
`skills/kaizen/templates/working-buffer.md` before incrementing.

---

## Reset conditions

`retry_count` resets to 0 when any of these occur:

- Binary Assertions passes (a successful non-trivial response)
- A new day starts (cron `kaizen-daily-digest` resets it at 13:30 BRT)
- User sends a new unrelated message (judged by: different topic, no
  reference to the previous failure)
- The user explicitly says "ignore last attempt" or "discard"
- `retry_count > 3` and the user re-sends the same task (treated as a new attempt)

---

## Cost

- Max 3 retries × ~1–3k tokens each = ~3–9k extra tokens per failed task
- Failure case: ~9k tokens "wasted" before escalating to user
- Comparison to current (no loop): 0 extra tokens but responses may be
  silently partial, requiring user re-prompting — which costs more total
  tokens + user time

The 3-cap is intentionally small. A larger cap (e.g. 10) risks loop
self-deception ("try harder, you're so close") without actually fixing
the failure mode.

---

## Known limitations (Approach A)

- **Voluntary check.** Binary Assertions is voluntary. If the agent
  forgets to run the checklist, the loop never fires. Mitigation: the
  reflexion-loop cron (`kaizen-daily-digest`) reviews the previous day
  for tasks that should have self-corrected but didn't.
- **No enforcement across sessions.** If the session ends (compaction or
  crash), `retry_count` is lost unless persisted. The current implementation
  persists to working-buffer.md, which IS read on compaction recovery.
- **Same model, same prompt.** The retry runs the same agent with the
  same prompt. If the failure was due to a model limitation (e.g. the model
  genuinely doesn't know), retries will produce similar failures. Detect
  this and escalate at retry_count = 2 instead of 3.
- **No external escalation channel.** Escalation is to the same Telegram
  chat the user is using. If user is offline, the message sits unread.

For hard enforcement via `before_agent_finalize` hook, see TODO
`lib/self-correction-loop.hook.md` (Approach B, not implemented yet due to
known `gateway_start` race condition — Issue #30257).

---

## Trigger block (copy into AGENTS.md)

```markdown
## Self-Correction Loop (kaizen v1.1)

After every non-trivial output (code, config, command, recommendation,
structured doc), BEFORE finalizing to the user:

1. Run Binary Assertions (6 items, see `lib/binary-assertions.md`).
2. If all YES → finalize normally.
3. If any NO:
   - Read `retry_count` from `memory/working-buffer.md` →
     `## Self-Correction State` (or create the file from
     `templates/working-buffer.md` if absent).
   - If `retry_count < 3`: dispatch a retry turn in the current session
     using the prompt template in `lib/self-correction-loop.md`. Increment
     the count. Do NOT finalize the current partial response to the user.
   - If `retry_count >= 3`: finalize honestly with the "auto-correção
     falhou após 3 tentativas" message. No more retries.

Reset `retry_count` to 0 when Binary Assertions passes, a new day starts,
or the user sends an unrelated message.
```

---

## Version

v1.0 (2026-06-17). Approach A (instruction-based). Approach B planned but
not started — blocked on reliable `before_agent_finalize` hook delivery.