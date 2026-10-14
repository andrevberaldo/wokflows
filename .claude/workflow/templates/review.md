# Review: <título>

## Rodada <n>
- **Resultado:** aprovado | mudanças necessárias
- **Nível técnico:** lean | high
- **Checks:** lint=<ok|falhou> · test=<ok|falhou>

### Critérios de aceite
| AC | Status | Evidência |
|---|---|---|
| AC-1 | ✅ | `tests/...::...` |
| AC-2 | ❌ | não há tratamento para ... |

### Segurança e performance
<!-- SOMENTE em Nível técnico = high -->
| NFR | Status | Evidência (teste/medição) |
|---|---|---|
| NFR-S1 | ✅ | ... |
| NFR-P1 | ❌ | sem medição |

### Bloqueantes
- [ ] **B1** `arquivo:linha` — <problema>. Cenário: <entrada → resultado errado>. Correção: <1–2 linhas>.

### Sugestões (não bloqueantes)
- **S1** `arquivo:linha` — ...
