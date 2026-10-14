# wokflows — desenvolvimento spec-driven com subagentes

Workflow para [Claude Code](https://claude.com/claude-code), agnóstico de stack, que leva um pedido de feature por **documentação → spec → design → implementação + testes → review → docs** com um único comando:

```
/feature adicionar exportação de relatórios em CSV
```

## Pipeline

| Etapa | Agente | Modelo | Saída |
|---|---|---|---|
| 0. Documentação (só se faltar) | `repo-documenter` | sonnet | `docs/`, `.claude/workflow/project.md` |
| 1. Spec | `spec-writer` | opus | `specs/<slug>/spec.md` |
| 2. Design | `architect` | opus | `design.md`, `tasks.md` |
| 3. Aprovação humana | — | — | (pule com `--yes`) |
| 4. Implementação (por lote) | `implementer` | sonnet | código + testes, tarefas marcadas |
| 5. Review (≤ 2 rodadas de correção) | `reviewer` | sonnet | `review.md` |
| 6. Documentação incremental | `doc-writer` | haiku | `docs/`, README, CHANGELOG |

O orquestrador é a sessão principal executando `.claude/commands/feature.md`.

## Por que economiza tokens sem perder qualidade

1. **Documentação primeiro, uma vez só.** Se o repo não tem docs, o `repo-documenter` lê o código e escreve a documentação completa. Daí em diante, a spec é escrita a partir da documentação — não de uma nova varredura do código. O `doc-writer` mantém a doc atualizada a cada feature e fecha as lacunas que a spec apontou.
2. **Handoff por arquivo.** Cada etapa grava um artefato em `specs/<slug>/`; o próximo agente recebe só o caminho. O orquestrador nunca carrega código ou diffs.
3. **Retornos curtos.** Todo agente devolve um resumo estruturado de até 10 linhas.
4. **Modelo certo para cada etapa.** Opus onde o raciocínio decide a qualidade (spec e design); Sonnet para executar e revisar; Haiku para docs incrementais.
5. **Contexto fresco por lote.** O `implementer` roda um lote pequeno de tarefas por vez.
6. **Cache do perfil do projeto.** Comandos de build/lint/test ficam em `.claude/workflow/project.md`.
7. **Loops limitados.** No máximo 2 rodadas de review → correção; depois o workflow para e reporta.

Qualidade vem de: critérios de aceite testáveis (`AC-n`), rastreabilidade AC → tarefa → teste, gate humano após o design e um reviewer que não pode editar código.

## Instalação

```bash
git clone <este repo> wokflows
./wokflows/install.sh /caminho/do/seu/projeto          # não sobrescreve arquivos existentes
./wokflows/install.sh /caminho/do/seu/projeto --force  # sobrescreve
```

No Windows (PowerShell):

```powershell
.\wokflows\install.ps1 -Target C:\caminho\do\seu\projeto          # não sobrescreve arquivos existentes
.\wokflows\install.ps1 -Target C:\caminho\do\seu\projeto -Force   # sobrescreve
```

Isso copia `.claude/agents/`, `.claude/commands/` e `.claude/workflow/templates/` para o projeto.

## Uso

```
/feature <descrição>            # fluxo completo com gate de aprovação
/feature <descrição> --yes      # sem gate de aprovação
/feature <descrição> --commit   # faz commit ao final
```

Artefatos gerados no projeto:

```
docs/                      # criado uma vez pelo repo-documenter, mantido pelo doc-writer
.claude/workflow/project.md
specs/<yyyy-mm-dd-slug>/
  spec.md  design.md  tasks.md  review.md
```

## Customização

- **Modelos:** altere o campo `model:` no frontmatter de cada agente em `.claude/agents/` (`opus`, `sonnet`, `haiku` ou `inherit`).
- **Templates:** edite `.claude/workflow/templates/*.md`; os agentes os seguem.
- **Comandos do projeto:** ajuste `.claude/workflow/project.md` se a detecção automática errar.
- **Rodadas de review / gate:** ajuste em `.claude/commands/feature.md`.

## Estrutura

```
.claude/
  agents/            repo-documenter, spec-writer, architect, implementer, reviewer, doc-writer
  commands/          feature.md (orquestrador)
  workflow/templates spec, design, tasks, review
install.sh / install.ps1
```
