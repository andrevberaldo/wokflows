#!/usr/bin/env bash
# Instala o workflow spec-driven em um projeto alvo.
# Uso: ./install.sh <diretório-do-projeto> [--force]
set -euo pipefail

SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/.claude"
TARGET="${1:-}"
FORCE="${2:-}"

if [[ -z "$TARGET" || ! -d "$TARGET" ]]; then
  echo "Uso: $0 <diretório-do-projeto> [--force]" >&2
  exit 1
fi

copied=0; skipped=0
while IFS= read -r -d '' file; do
  rel="${file#"$SRC"/}"
  dest="$TARGET/.claude/$rel"
  if [[ -e "$dest" && "$FORCE" != "--force" ]]; then
    echo "pulado (já existe): .claude/$rel"
    skipped=$((skipped + 1))
    continue
  fi
  mkdir -p "$(dirname "$dest")"
  cp "$file" "$dest"
  echo "instalado: .claude/$rel"
  copied=$((copied + 1))
done < <(find "$SRC/agents" "$SRC/commands" "$SRC/workflow/templates" -type f -name '*.md' -print0)

echo "Pronto: $copied instalados, $skipped pulados. Use /feature <descrição> no projeto."
[[ $skipped -gt 0 ]] && echo "Use --force para sobrescrever arquivos existentes."
exit 0
