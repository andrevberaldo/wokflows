# wokflows — desenvolvimento spec-driven com subagentes

Workflow para [Claude Code](https://claude.com/claude-code), agnóstico de stack, que leva um pedido de feature por **documentação → spec → design → implementação + testes → review → docs** com um único comando:

```
/feature adicionar exportação de relatórios em CSV
```

## Pipeline

| Etapa | Agente | Modelo | Saída |
|---|---|---|---|
| 0. Documentação (só se faltar) | `repo-documenter` | sonnet | `docs/`, `.claude/workflow/project.md` |
| 1. Spec interativa (loop até você aprovar) | `spec-writer` + orquestrador | opus | `specs/<slug>/spec.md` |
| 2. Design | `architect` | opus | `design.md`, `tasks.md` |
| 3. Aprovação do design | — | — | (pule com `--yes`) |
| 4. Implementação (por lote) | `implementer` | sonnet | código + testes, tarefas marcadas |
| 5. Review (≤ 2 rodadas de correção) | `reviewer` | sonnet | `review.md` |
| 6. Documentação incremental | `doc-writer` | haiku | `docs/`, README, CHANGELOG |

O orquestrador é a sessão principal executando `.claude/commands/feature.md`.

### Nível técnico: `--tech high`
| | `lean` (padrão, sem flag) | `--tech high` |
|---|---|---|
| Filosofia | O mais simples que resolve, sem overengineering (YAGNI) | Simples onde der, rigoroso em segurança e performance |
| Spec | Requisitos mínimos; até ~3 sugestões, só riscos reais e óbvios | + modelo de ameaças, requisitos de segurança e **NFRs de performance mensuráveis** (viram ACs); até ~8 sugestões |
| Design | Reuso, mínimo de arquivos, sem novas abstrações/dependências | + controles concretos por ameaça, análise de complexidade/dados (N+1, índices, paginação, timeouts), tarefas de teste de segurança e carga |
| Implementação | Só o pedido | + controles do design e testes de segurança/performance |
| Review | Correção e ACs; aponta overengineering como sugestão | + passada de segurança (OWASP) e performance; falhas comprovadas são bloqueantes |

```
/feature adicionar upload de avatar              # lean
/feature adicionar upload de avatar --tech high  # rigor em segurança e performance
```
O nível fica registrado no cabeçalho da spec e é repassado a todos os agentes.

### Spec interativa
A spec é construída em rodadas com você. A cada rodada o `spec-writer` devolve um resumo, dúvidas e **sugestões de boas práticas e segurança** (`SG-n`: validação de entrada, autorização, dados sensíveis, injeção, rate limiting, observabilidade, idempotência etc., sempre específicas ao seu pedido). Você decide uma a uma; as aceitas viram requisitos e critérios de aceite testáveis. O fluxo **só avança para o design quando você escolhe explicitamente "Aprovar spec"** — não há limite de rodadas e `--yes` não pula essa etapa.

## Por que economiza tokens sem perder qualidade

1. **Documentação primeiro, uma vez só.** Se o repo não tem docs, o `repo-documenter` lê o código e escreve a documentação completa. Daí em diante, a spec é escrita a partir da documentação — não de uma nova varredura do código. O `doc-writer` mantém a doc atualizada a cada feature e fecha as lacunas que a spec apontou.
2. **Handoff por arquivo.** Cada etapa grava um artefato em `specs/<slug>/`; o próximo agente recebe só o caminho. O orquestrador nunca carrega código ou diffs.
3. **Retornos curtos.** Todo agente devolve um resumo estruturado de até 10 linhas.
4. **Modelo certo para cada etapa.** Opus onde o raciocínio decide a qualidade (spec e design); Sonnet para executar e revisar; Haiku para docs incrementais.
5. **Contexto fresco por lote.** O `implementer` roda um lote pequeno de tarefas por vez.
6. **Cache do perfil do projeto.** Comandos de build/lint/test ficam em `.claude/workflow/project.md`.
7. **Loops limitados.** No máximo 2 rodadas de review → correção; depois o workflow para e reporta.

### Documentação sempre persistida no repositório
Nada do que o fluxo documenta fica só na memória dos agentes. Cada agente grava seu resultado em arquivo (e retorna `falhou` se não conseguir), o orquestrador confere que os arquivos existem e faz **commits automáticos só com a documentação** em checkpoints — independentemente de `--commit`, que continua controlando apenas o commit do código:

| Checkpoint | Caminhos | Commit |
|---|---|---|
| Docs iniciais (Etapa 0) | `docs/`, `.claude/workflow/project.md` | `docs: documentação inicial do repositório` |
| Spec aprovada | `specs/<slug>/` | `docs(spec): <título>` |
| Design aprovado | `specs/<slug>/` | `docs(design): <título>` |
| Docs incrementais (Etapa 6) | `specs/<slug>/`, `docs/`, README, CHANGELOG | `docs: atualiza documentação de <título>` |

Se o fluxo for cancelado ou parar no meio, os artefatos produzidos até ali também são commitados. Os commits usam `git commit -- <caminhos>`, então código em andamento nunca entra neles. O push fica com você.

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
/feature <descrição> --tech high  # eleva rigor de segurança e performance (padrão: lean)
/feature <descrição> --yes      # pula só a aprovação do design (a da spec é sempre exigida)
/feature <descrição> --commit   # faz commit do código ao final (a documentação é sempre commitada)
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
