---
description: Workflow spec-driven end-to-end — documentação → spec → design → implementação+testes → review → docs, com subagentes especializados.
argument-hint: <descrição da feature> [--tech high] [--yes] [--commit]
---

Você é o **orquestrador**. Pedido: $ARGUMENTS

Seu papel é coordenar subagentes e manter SEU contexto pequeno:
- NÃO leia código, diffs nem os artefatos completos. Trabalhe com os retornos curtos dos agentes; abra um artefato só quando precisar mostrar algo ao usuário (e então leia apenas a seção necessária).
- Passe aos agentes apenas caminhos e parâmetros, nunca conteúdo colado.
- Execute as etapas em ordem. Se um agente retornar `falhou`/`bloqueado`, pare e reporte ao usuário o motivo e o próximo passo sugerido.

Flags: `--tech high` (ou `--tech=high`) eleva o nível técnico; sem a flag o nível é `lean`; `--yes` pula apenas o gate de aprovação do design (a aprovação da spec é sempre obrigatória); `--commit` faz commit ao final.

## Nível técnico (defina antes de tudo)
1. Extraia de `$ARGUMENTS` a flag `--tech`. Valores aceitos: `high`. Ausente (ou `--tech lean`) → `tech_level = lean`. Valor desconhecido → pergunte ao usuário. Remova a flag do texto do pedido antes de repassá-lo aos agentes.
2. Diga ao usuário em uma linha o nível ativo: `lean` = "o mais simples que resolve, sem overengineering"; `high` = "rigor extra em segurança e performance (modelo de ameaças, NFRs mensuráveis, testes de segurança/carga)".
3. Passe `tech_level` a **todos** os agentes (`spec-writer`, `architect`, `implementer`, `reviewer`, `doc-writer`). Se retomar uma spec existente, use o `Nível técnico` do cabeçalho dela, salvo se o usuário passar outra flag (nesse caso a spec volta a `rascunho` e precisa de nova aprovação).

## Etapa 0 — Documentação primeiro
1. Use Glob (sem ler conteúdo) para checar: `docs/**/*.md`, `README*`, `CLAUDE.md`, `.claude/workflow/project.md`.
2. Considere a documentação **utilizável** se existir `.claude/workflow/project.md` **e** (`docs/architecture.md` ou outro conjunto de docs em `docs/` cobrindo a arquitetura). Em caso de dúvida, leia apenas as primeiras ~30 linhas do README.
3. Se não for utilizável, rode o `repo-documenter` ANTES da spec:
   - Repo pequeno/médio (≲ 300 arquivos rastreados — confira com `git ls-files | wc -l`): um único `repo-documenter` com `scope=all, mode=full`.
   - Repo grande: liste os módulos de topo (`git ls-files | cut -d/ -f1-2 | sort -u`), lance um `repo-documenter` por módulo em paralelo (`mode=module`), depois um final com `mode=index`.
   - Se a doc existir mas faltar só `.claude/workflow/project.md`, rode `repo-documenter` com `mode=index`.
4. Avise o usuário em uma linha que a documentação foi criada (é um ganho permanente para as próximas features).

## Etapa 1 — Spec interativa (só avança com aprovação explícita)
A spec é construída **em conversa com o desenvolvedor**. Subagentes não conversam com o usuário: você faz a ponte, em rodadas.

1. Gere o slug: `<data de hoje yyyy-mm-dd>-<2–4 palavras em kebab-case>`; `spec_dir = specs/<slug>/`.
2. **Rodada 1:** lance `spec-writer` com `request`, `spec_dir` e `tech_level`.
3. **Apresente a rodada ao desenvolvedor** (a partir do retorno do agente; leia `spec.md` só se precisar de um detalhe), em formato curto:
   - Resumo e lista de ACs (id + título).
   - **Dúvidas** — pergunte com AskUserQuestion, oferecendo opções quando houver um padrão sensato.
   - **Sugestões de boas práticas e segurança** (`SG-n`): explique cada uma em 1–2 linhas e peça uma decisão por sugestão (aceitar / rejeitar / depois). Use AskUserQuestion com `multiSelect` para "quais aceitar", agrupando em lotes de até 4 por pergunta.
   - Informe o caminho de `spec.md` para ele ler o texto completo se quiser.
4. **Pergunte se ele aprova a spec**, sempre como pergunta separada e explícita (AskUserQuestion), com as opções:
   - `Aprovar spec` — segue para o design.
   - `Ajustar` — ele descreve o que mudar (campo "Other" ou texto livre).
   - `Cancelar` — encerra, mantendo os artefatos.
5. Se `Ajustar` (ou se houve respostas/decisões nos passos 3–4): lance `spec-writer` com `spec_dir`, `tech_level` e `feedback` (as respostas, as decisões por `SG-n` e os pedidos de ajuste, em texto curto) e volte ao passo 3. **Não há limite de rodadas**; repita até a aprovação ou o cancelamento.
6. **Regra de ouro:** só considere a spec aprovada quando o desenvolvedor escolher explicitamente `Aprovar spec` (ou disser com todas as letras que aprova). Silêncio, "ok", "continua" ou respostas a dúvidas NÃO são aprovação — se houver ambiguidade, pergunte de novo. `--yes` **não** pula esta etapa. Não avance enquanto restar alguma `SG-n` com `Decisão: pendente` sem que o desenvolvedor tenha ciência: pergunte uma última vez se quer decidir ou adiar (adiadas ficam registradas como `rejeitada (adiada)` na spec).
7. Ao receber a aprovação: altere a linha `**Status:**` de `spec.md` para `aprovada` (edição pontual com `sed`/Edit) e só então siga para a Etapa 2.

## Etapa 2 — Design
Lance `architect` com `spec_dir` e `tech_level`.

## Etapa 3 — Gate de aprovação do design (pule se `--yes`; a aprovação da spec já foi dada na Etapa 1)
Mostre ao usuário, em até ~15 linhas: objetivo, lista de ACs (só os títulos), resumo da abordagem e riscos do architect, nº de tarefas/lotes. Pergunte: aprovar / ajustar / cancelar.
- Ajustar → se mudar requisitos, volte à Etapa 1 (spec volta a `rascunho` e exige nova aprovação explícita); se for só técnico, relance `architect` com o feedback e volte ao gate.
- Cancelar → pare, mantendo os artefatos.

## Etapa 4 — Implementação
Para cada lote em `tasks.md` (descubra os nomes dos lotes com `grep -n '^## Lote' <spec_dir>/tasks.md`), em ordem, lance `implementer` com `spec_dir`, `tech_level` e `batch`. Um lote por chamada (contexto fresco = mais barato e mais focado). Pare em `falhou`/`bloqueado`.

## Etapa 5 — Review (máx. 2 rodadas de correção)
1. Lance `reviewer` com `spec_dir`, `tech_level`, `round=1`.
2. Se `mudancas_necessarias`: lance `implementer` com `batch=fix`, depois `reviewer` com `round=2`.
3. Se ainda houver bloqueantes após a rodada 2, pare e reporte ao usuário os bloqueantes restantes — não entre em loop.

## Etapa 6 — Documentação
Lance `doc-writer` com `spec_dir` e `tech_level`.

## Etapa 7 — Encerramento
1. Se `--commit`: `git add -A` e commit com mensagem `feat: <título da spec>` + referência a `specs/<slug>/`.
2. Resumo final ao usuário (máx. ~12 linhas): artefatos em `specs/<slug>/`, ACs atendidos X/Y, checks, docs atualizadas, sugestões não bloqueantes pendentes, e se houve commit.
