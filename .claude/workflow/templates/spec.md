# Spec: <título>

- **Slug:** <yyyy-mm-dd-slug>
- **Status:** rascunho | aprovada <!-- só o orquestrador muda para 'aprovada', após aprovação explícita do desenvolvedor -->
- **Rodada:** 1
- **Nível técnico:** lean | high
- **Pedido original:** <1–2 linhas>

## Problema / objetivo
<Por que isso importa e para quem. 2–4 linhas.>

## Requisitos
- R1: ...
- R2: ...

## Critérios de aceite
- **AC-1** — Dado <contexto>, quando <ação>, então <resultado verificável>.
- **AC-2** — ...

## Segurança e performance
<!-- SOMENTE quando Nível técnico = high. Em lean, remova esta seção. -->
### Modelo de ameaças
| Ativo / fronteira | Ameaça (abuso plausível) | Mitigação exigida | AC |
|---|---|---|---|
| ... | ... | ... | AC-n |

### Requisitos de segurança
- **NFR-S1:** ... (→ AC-n)

### Requisitos de performance (mensuráveis)
- **NFR-P1:** p95 < ... ms para ... itens / complexidade ... / memória ... (→ AC-n)

## Sugestões (boas práticas e segurança)
<!-- O spec-writer sugere; o desenvolvedor decide. Aceita → vira R-n e AC-n. -->
- **SG-1** [segurança|boa prática] <título> — <por que importa; custo/impacto>. **Decisão:** pendente | aceita (→ R-n, AC-n) | rejeitada (<motivo>)

## Fora de escopo
- ...

## Premissas
- ...

## Dúvidas abertas
<!-- Só decisões que mudam o comportamento. Remova a seção quando vazia. -->
1. ...

## Lacunas de documentação
<!-- O que precisou ser lido no código porque a doc não respondia. O doc-writer fecha estes itens. -->
- ...

## Referências
- docs/...
