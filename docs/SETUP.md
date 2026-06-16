# Setup Guide

**After installing Kaizen**, these are the optional crons you can register. All are `isolated agentTurn` so they run autonomously, not as system events that prompt the main session.

---

## Regra de Busca (transversal a todos os crons Kaizen)

> A REGRA ZERO do TOOLS.md da main session **não propaga automaticamente** pra sessoes `isolated` dos crons. Por isso, todo payload de cron Kaizen inclui o bloco abaixo, repetido dentro do `message` do `agentTurn` (ver Cron 1-4).

**REGRA DE BUSCA** — antes de afirmar qualquer coisa sobre ferramenta externa, doc oficial, default de sistema, versao de pacote, "best practice" ou comportamento de API/lib, USE `web_search` / `web_fetch` (Tavily ou Firecrawl, configurados em `~/.openclaw/openclaw.json`).
- Em duvida, busque. Custo de buscar: 3-5s. Custo de chutar e errar: retrabalho + perda de confianca.
- Citar a fonte (URL) na sugestao/proposta/promocao quando aplicavel.
- Nao inventar. Nao "achar que sabe".
- Knowledge cutoff: 2026-01. Tudo entre essa data e agora e candidato automatico a busca.

**Por que embedded no payload e nao em TOOLS.md?** Sessoes `isolated agentTurn` rodam com bootstrap minimo e NAO carregam TOOLS.md. Inserir a regra direto no `message` garante que o agente a veja em qualquer sessao.

---

## Cron 1: Reverse Prompting (weekly)

**Schedule:** Sunday 18:00 BRT (cron: `0 18 * * 0`)
**Purpose:** Read `notes/areas/proactive-tracker.md`, formulate 1-2 fresh reverse-prompting questions, post to main session.

```bash
# Via OpenClaw CLI
cron action=add <<EOF
{
  "name": "kaizen-reverse-prompting-weekly",
  "schedule": { "kind": "cron", "expr": "0 18 * * 0", "tz": "America/Sao_Paulo", "staggerMs": 60000 },
  "sessionTarget": "isolated",
  "payload": {
    "kind": "agentTurn",
    "message": "AUTONOMOUS reverse-prompting semanal. NAO pergunte ao humano se pode rodar. Execute e reporte ao final.\n\n==== REGRA DE BUSCA (aplicar em todas as etapas) ====\nAntes de afirmar qualquer coisa sobre ferramenta externa, doc oficial, default de sistema, versao de pacote, "best practice" ou comportamento de API/lib, USE `web_search` / `web_fetch` (Tavily ou Firecrawl, configurados em `~/.openclaw/openclaw.json`).\n- Em duvida, busque. Custo de buscar: 3-5s. Custo de chutar e errar: retrabalho + perda de confianca.\n- Citar a fonte (URL) quando aplicavel.\n- Nao inventar. Nao "achar que sabe".\n- Knowledge cutoff: 2026-01. Tudo entre essa data e agora e candidato automatico a busca.\n\n1. Leia ~/.openclaw/workspace/notes/areas/proactive-tracker.md (se não existir, crie a partir de ~/.openclaw/workspace/skills/kaizen/templates/recurring-patterns.md adaptado).\n2. Leia ~/.openclaw/workspace/memory/ (últimos 7 dias) e ~/.openclaw/workspace/MEMORY.md.\n3. Identifique itens abertos no tracker ha >7d.\n4. Formule 1-2 perguntas FRESCAS (nao repita se <7d). Padroes: 'O que mais posso fazer por voce?' / 'Que informacao me ajudaria a ser mais util?'\n5. Atualize proactive-tracker.md → 'Reverse Prompting Questions Asked'.\n6. Poste no canal main (telegram) com delivery mode announce, em portugues, tom direto, sem emoji.\n\nRestrições: sem emoji, tom direto, sem floreio."
  },
  "delivery": { "mode": "announce", "channel": "telegram", "to": "telegram:8157279145", "bestEffort": true }
}
EOF
```

## Cron 2: Pattern Detection (monthly)

**Schedule:** Day 1, 10:00 BRT (cron: `0 10 1 * *`)
**Purpose:** Read `memory/` (last 30 days), detect patterns 3+ times, propose automations.

```bash
cron action=add <<EOF
{
  "name": "kaizen-pattern-automation-monthly",
  "schedule": { "kind": "cron", "expr": "0 10 1 * *", "tz": "America/Sao_Paulo", "staggerMs": 120000 },
  "sessionTarget": "isolated",
  "payload": {
    "kind": "agentTurn",
    "message": "AUTONOMOUS growth-loops + proactive-surprise mensal.\n\n==== REGRA DE BUSCA (aplicar em todas as etapas) ====\nAntes de afirmar qualquer coisa sobre ferramenta externa, doc oficial, default de sistema, versao de pacote, "best practice" ou comportamento de API/lib, USE `web_search` / `web_fetch` (Tavily ou Firecrawl, configurados em `~/.openclaw/openclaw.json`).\n- Em duvida, busque. Custo de buscar: 3-5s. Custo de chutar e errar: retrabalho + perda de confianca.\n- Citar a fonte (URL) na proposta de automacao quando aplicavel.\n- Nao inventar. Nao "achar que sabe".\n- Knowledge cutoff: 2026-01. Tudo entre essa data e agora e candidato automatico a busca.\n\n1. Leia ~/.openclaw/workspace/memory/ (últimos 30 dias).\n2. Identifique padrões repetidos (3+): pedidos do humano, bugs, workflows manuais.\n3. Para cada padrão, formule proposta de automação.\n4. Se houver ≥1 padrão, poste no canal main (telegram) com delivery announce, em portugues, sem emoji:\n   - 'Padroes detectados este mes: ...'\n   - 'Propostas de automacao: ...'\n   - 'Posso rascunhar/implementar X? (Y/n)'\n5. Se não houver padrão ≥3x, NÃO poste nada (silêncio OK).\n6. Atualize ~/.openclaw/workspace/notes/areas/proactive-tracker.md → 'Surprises Delivered'.\n\nRestrições: sem emoji, tom direto, nao implemente nada sozinho."
  },
  "delivery": { "mode": "announce", "channel": "telegram", "to": "telegram:8157279145", "bestEffort": true }
}
EOF
```

## Cron 3: Learning Review (weekly)

**Schedule:** Saturday 10:00 BRT (cron: `0 10 * * 6`)
**Purpose:** Review `.learnings/` — promote recurring items, resolve fixed, link related entries.

```bash
cron action=add <<EOF
{
  "name": "kaizen-learning-review-weekly",
  "schedule": { "kind": "cron", "expr": "0 10 * * 6", "tz": "America/Sao_Paulo", "staggerMs": 90000 },
  "sessionTarget": "isolated",
  "payload": {
    "kind": "agentTurn",
    "message": "AUTONOMOUS learning review semanal. NAO pergunte.\n\n==== REGRA DE BUSCA (aplicar em todas as etapas) ====\nAntes de afirmar qualquer coisa sobre ferramenta externa, doc oficial, default de sistema, versao de pacote, "best practice" ou comportamento de API/lib, USE `web_search` / `web_fetch` (Tavily ou Firecrawl, configurados em `~/.openclaw/openclaw.json`).\n- Em duvida, busque. Custo de buscar: 3-5s. Custo de chutar e errar: retrabalho + perda de confianca.\n- Citar a fonte (URL) na promocao quando aplicavel.\n- Nao inventar. Nao "achar que sabe".\n- Knowledge cutoff: 2026-01. Tudo entre essa data e agora e candidato automatico a busca.\n\n1. Leia ~/.openclaw/workspace/.learnings/ (todos os arquivos).\n2. Conte itens pendentes: grep -h 'Status\\\\*\\\\*: pending' .learnings/*.md | wc -l\n3. Para cada item com Recurrence-Count >= 3 (recurring pattern), promova:\n   - Tech learning → ~/.openclaw/workspace/TOOLS.md\n   - Workflow improvement → ~/.openclaw/workspace/AGENTS.md\n4. Para cada item com Status=resolved, mantenha (não delete).\n5. Para itens com See Also, adicione links cruzados se faltar.\n6. Se houver ≥1 promoção, poste resumo no canal main (telegram) com delivery announce, em portugues, sem emoji.\n7. Se nada para promover, fique em silencio.\n\nRestrições: nunca promova para SOUL.md/IDENTITY.md/MEMORY.md (esses têm gate)."
  },
  "delivery": { "mode": "announce", "channel": "telegram", "to": "telegram:8157279145", "bestEffort": true }
}
EOF
```

## Cron 4: Daily Digest (daily)

**Schedule:** Daily 13:30 BRT (cron: `30 13 * * *`)
**Purpose:** Scan tracker + learnings + memory (3 days) + outcome journal for actionable signals. If any, post a digest to the main session. Stays silent if nothing actionable.

```bash
cron action=add <<EOF
{
  "name": "kaizen-daily-digest",
  "schedule": { "kind": "cron", "expr": "30 13 * * *", "tz": "America/Sao_Paulo", "staggerMs": 120000 },
  "sessionTarget": "isolated",
  "payload": {
    "kind": "agentTurn",
    "message": "AUTONOMOUS daily digest (Kaizen N2 + N3). NAO pergunte. Execute e reporte ao final.\n\n==== REGRA DE BUSCA (aplicar em todas as etapas) ====\nAntes de afirmar qualquer coisa sobre ferramenta externa, doc oficial, default de sistema, versao de pacote, "best practice" ou comportamento de API/lib, USE `web_search` / `web_fetch` (Tavily ou Firecrawl, configurados em `~/.openclaw/openclaw.json`).\n- Em duvida, busque. Custo de buscar: 3-5s. Custo de chutar e errar: retrabalho + perda de confianca.\n- Citar a fonte (URL) na sugestao quando aplicavel.\n- Nao inventar. Nao "achar que sabe".\n- Knowledge cutoff: 2026-01. Tudo entre essa data e agora e candidato automatico a busca.\n\nMISSAO: ler o que foi feito (memory + learnings + tracker + outcome journal) do dia atual + anterior, ENTENDER o contexto, LEMBRAR o usuario de pendencias que precisam de resolucao, e SUGERIR acoes/melhorias concretas.\n\n==== ETAPA 1: LEITURA ====\n1. Leia ~/.openclaw/workspace/notes/areas/proactive-tracker.md (se nao existir, crie).\n2. Leia ~/.openclaw/workspace/.learnings/ (LEARNINGS.md, ERRORS.md, FEATURE_REQUESTS.md).\n3. Leia ~/.openclaw/workspace/memory/ INTEIRO: dia atual (hoje) e dia anterior (ontem). Sem filtro de score/limite — leia o arquivo todo.\n4. Leia ~/.openclaw/workspace/notes/areas/outcome-journal.md (se existir).\n5. Leia ~/.openclaw/workspace/skills/kaizen/SKILL.md e ~/.openclaw/workspace/skills/kaizen/lib/ (pra conhecer a skill atual).\n\n==== ETAPA 2: ENTENDER ====\nContextualize tudo que leu. Para cada item relevante, identifique:\n- O QUE foi feito/instalado/configurado/discutido.\n- POR QUE foi feito (causa raiz, gatilho, objetivo).\n- STATUS: concluido, em andamento, pendente, abandonado, recorrente.\n\n==== ETAPA 3: LEMBRAR PENDENCIAS (N2) ====\nListe TODAS as pendencias abertas que precisam de acao/resposta do usuario. Para cada uma, lembre com contexto suficiente (data, fonte, acao sugerida) pra ele agir:\na) Itens no proactive-tracker.md ha >7d sem follow-up.\nb) Decisoes no outcome-journal.md com follow-up date <= hoje.\nc) Promessas inacabadas no memory/ (frases 'vou X', 'depois Y', 'amanha Z', 'preciso W' sem evidencia de conclusao).\nd) Tarefas iniciadas sem conclusao (skill sem commit, cron sem teste, config sem restart, doc incompleto).\ne) Items em .learnings/ com Status=pending ha >14d.\nf) Perguntas feitas ao usuario que ficaram sem resposta.\n\n==== ETAPA 4: SUGERIR (N3) ====\nPara CADA sinal (N1.a-e) ou pendencia (N3.a-f) detectada, gere pelo menos 1 SUGESTAO concreta:\n- ACAO: 'fechar X', 'aplicar Y', 'agendar Z', 'investigar W' — especifico e acionavel.\n- MELHORIA: promocao de learning, ajuste de skill, fix de bug, atualizacao de doc.\n- AUTOMACAO: se padrao manual apareceu 3+ vezes, propor script/cron/atalho.\n\nFormato: '- [N3] (acao|melhoria|automacao) descricao. Evidencia: [fonte]. Esforco: [pequeno|medio|grande].'\n\nCriterios para sugerir:\n- Evidencia CONCRETA em .learnings/ ou memory/ (nao chute).\n- Acao acionavel (voce sabe o que mudar e onde).\n- NAO tweak cosmetico.\n- NAO mudanca de identidade (SOUL/IDENTITY/MEMORY).\n\n==== ETAPA 5: OUTPUT ====\nSe houver QUALQUER sinal, pendencia ou sugestao, poste no canal main (telegram) com delivery announce, em portugues, tom direto, sem emoji:\n\n'Daily digest [YYYY-MM-DD]:'\n\n'Pendencias:'\n'- [N3.a-f] descricao (data, fonte, acao sugerida)'\n\n'Sinais:'\n'- [N1.a-e] descricao'\n\n'Sugestoes:'\n'- [N3] (acao|melhoria|automacao) descricao. Evidencia: X. Esforco: Y.'\n\nMax 5 itens POR SECAO. Prioridade: quebras > pendencias com follow-up vencido > padroes > items overdue > melhorias.\nSe NAO houver nada em nenhuma secao, fique em silencio (NAO poste 'tudo ok').\n\n==== RESTRICOES ====\n- Sem emoji. Tom direto.\n- NUNCA implemente nada sozinho. So leia, entenda, lembre e sugira.\n- Sugestoes devem ser PEQUENAS e REVERSIVEIS.",
    "fallbacks": ["google/gemini-3-flash-preview"],
    "lightContext": false
  },
  "delivery": { "mode": "announce", "channel": "telegram", "to": "telegram:8157279145", "bestEffort": true }
}
EOF
```

---

## Verification

After adding crons:

```bash
cron action=list
# Expect 4 Kaizen crons + existing memory-core dreaming

# Manual test
cron action=run <job-id> --runMode force
# Verify delivery to telegram
```

---

## What the Crons Do NOT Do

- ❌ Write to `MEMORY.md` (that's `memory-core` dreaming's job)
- ❌ Write to `SOUL.md` / `IDENTITY.md` (immutable without user approval)
- ❌ Publish externally (only post to your own Telegram via main session)
- ❌ Modify crons themselves (no self-modification)

---

## Removing Crons

```bash
cron action=remove --jobId <job-id>
```

Or to disable without removing:

```bash
cron action=update --jobId <job-id> --patch '{"enabled": false}'
```
