---
description: Workflow spec-driven end-to-end — documentação → spec → design → implementação+testes → review → docs, com subagentes especializados.
argument-hint: <descrição da feature> [--yes] [--commit]
---

Você é o **orquestrador**. Pedido: $ARGUMENTS

Seu papel é coordenar subagentes e manter SEU contexto pequeno:
- NÃO leia código, diffs nem os artefatos completos. Trabalhe com os retornos curtos dos agentes; abra um artefato só quando precisar mostrar algo ao usuário (e então leia apenas a seção necessária).
- Passe aos agentes apenas caminhos e parâmetros, nunca conteúdo colado.
- Execute as etapas em ordem. Se um agente retornar `falhou`/`bloqueado`, pare e reporte ao usuário o motivo e o próximo passo sugerido.

Flags: `--yes` pula o gate de aprovação; `--commit` faz commit ao final.

## Etapa 0 — Documentação primeiro
1. Use Glob (sem ler conteúdo) para checar: `docs/**/*.md`, `README*`, `CLAUDE.md`, `.claude/workflow/project.md`.
2. Considere a documentação **utilizável** se existir `.claude/workflow/project.md` **e** (`docs/architecture.md` ou outro conjunto de docs em `docs/` cobrindo a arquitetura). Em caso de dúvida, leia apenas as primeiras ~30 linhas do README.
3. Se não for utilizável, rode o `repo-documenter` ANTES da spec:
   - Repo pequeno/médio (≲ 300 arquivos rastreados — confira com `git ls-files | wc -l`): um único `repo-documenter` com `scope=all, mode=full`.
   - Repo grande: liste os módulos de topo (`git ls-files | cut -d/ -f1-2 | sort -u`), lance um `repo-documenter` por módulo em paralelo (`mode=module`), depois um final com `mode=index`.
   - Se a doc existir mas faltar só `.claude/workflow/project.md`, rode `repo-documenter` com `mode=index`.
4. Avise o usuário em uma linha que a documentação foi criada (é um ganho permanente para as próximas features).

## Etapa 1 — Spec
1. Gere o slug: `<data de hoje yyyy-mm-dd>-<2–4 palavras em kebab-case>`; `spec_dir = specs/<slug>/`.
2. Lance `spec-writer` com `request`, `spec_dir`.
3. Se `STATUS: precisa_respostas`, pergunte ao usuário as DÚVIDAS (AskUserQuestion, com opções quando der) e relance `spec-writer` passando somente `answers`. No máximo 2 rodadas.

## Etapa 2 — Design
Lance `architect` com `spec_dir`.

## Etapa 3 — Gate de aprovação (pule se `--yes`)
Mostre ao usuário, em até ~15 linhas: objetivo, lista de ACs (só os títulos), resumo da abordagem e riscos do architect, nº de tarefas/lotes. Pergunte: aprovar / ajustar / cancelar.
- Ajustar → repasse o feedback ao agente adequado (`spec-writer` com `answers` ou `architect`) e volte ao gate.
- Cancelar → pare, mantendo os artefatos.

## Etapa 4 — Implementação
Para cada lote em `tasks.md` (descubra os nomes dos lotes com `grep -n '^## Lote' <spec_dir>/tasks.md`), em ordem, lance `implementer` com `spec_dir` e `batch`. Um lote por chamada (contexto fresco = mais barato e mais focado). Pare em `falhou`/`bloqueado`.

## Etapa 5 — Review (máx. 2 rodadas de correção)
1. Lance `reviewer` com `spec_dir`, `round=1`.
2. Se `mudancas_necessarias`: lance `implementer` com `batch=fix`, depois `reviewer` com `round=2`.
3. Se ainda houver bloqueantes após a rodada 2, pare e reporte ao usuário os bloqueantes restantes — não entre em loop.

## Etapa 6 — Documentação
Lance `doc-writer` com `spec_dir`.

## Etapa 7 — Encerramento
1. Se `--commit`: `git add -A` e commit com mensagem `feat: <título da spec>` + referência a `specs/<slug>/`.
2. Resumo final ao usuário (máx. ~12 linhas): artefatos em `specs/<slug>/`, ACs atendidos X/Y, checks, docs atualizadas, sugestões não bloqueantes pendentes, e se houve commit.
