#!/usr/bin/env bash
# tools-migration-check.sh
# Verifica referências-mortas ao migrar/deprecar uma tool.
# Ref: skill proactive-agent v3.1.0, seção "Tool Migration Checklist"
#
# Usage:
#   tools-migration-check.sh --old <old-name> [--new <new-name>] [--path <root>] [--apply]
#
# Exit codes:
#   0 = nenhuma referência a <old-name> encontrada (migração completa)
#   1 = referências restantes (mostra onde)
#   2 = erro de uso

set -euo pipefail

OLD=""
NEW=""
ROOT="${HOME}/.openclaw/workspace"
APPLY=0

usage() {
  cat <<EOF
Usage: $0 --old <old-name> [--new <new-name>] [--path <root>] [--apply]

  --old   Nome/tool/símbolo antigo a procurar (obrigatório)
  --new   Nome novo (opcional; se passado, sugere substituição)
  --path  Raiz do scan (default: \$HOME/.openclaw/workspace)
  --apply  Se --new fornecido, mostra comandos sed prontos (não executa)

Examples:
  $0 --old message --new msg
  $0 --old MemoryDenyWriteExecute
  $0 --old "my-old-tool" --path /etc/openclaw
EOF
  exit 2
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --old) OLD="$2"; shift 2 ;;
    --new) NEW="$2"; shift 2 ;;
    --path) ROOT="$2"; shift 2 ;;
    --apply) APPLY=1; shift ;;
    -h|--help) usage ;;
    *) echo "Unknown arg: $1" >&2; usage ;;
  esac
done

[[ -z "$OLD" ]] && { echo "ERROR: --old required" >&2; usage; }
[[ -d "$ROOT" ]] || { echo "ERROR: --path $ROOT not a directory" >&2; exit 2; }

echo "==> Scanning $ROOT for references to: $OLD"
echo

# Garante que OLD é tratado como literal (não regex perigoso)
HITS=$(grep -rIn --binary-files=without-match \
  --include='*.md' --include='*.sh' --include='*.json' \
  --include='*.yaml' --include='*.yml' --include='*.toml' --include='*.service' \
  -- "$OLD" "$ROOT" 2>/dev/null || true)

if [[ -z "$HITS" ]]; then
  echo "OK: zero references to '$OLD' in $ROOT"
  exit 0
fi

echo "Found $(echo "$HITS" | wc -l) reference(s):"
echo
echo "$HITS"
echo

if [[ -n "$NEW" ]]; then
  echo "==> Suggested sed replacements (--apply to print, not execute):"
  # Escapa separador / pra sed com delimiter |
  OLD_ESC=$(printf '%s' "$OLD" | sed 's/[&|]/\\&/g')
  NEW_ESC=$(printf '%s' "$NEW" | sed 's/[&|]/\\&/g')
  echo "$HITS" | awk -F: '{print $1}' | sort -u | while read -r FILE; do
    echo "  sed -i 's|$OLD_ESC|$NEW_ESC|g' $FILE"
  done
fi

exit 1
