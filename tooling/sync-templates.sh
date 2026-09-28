#!/usr/bin/env sh
# Copia as regras centrais (tooling/) para os templates que estao clonados ao
# lado deste repositorio, ou so confere se estao em dia.
#
#   sh tooling/sync-templates.sh           # copia
#   sh tooling/sync-templates.sh --check   # so confere; sai 1 se divergir
#
# Estrutura esperada:
#   <pasta>/workflows/
#   <pasta>/template-backend/  template-frontend/  template-microservice/  template-shared/
#
# O CI dos projetos usa a versao central (workflow conventions.yml); a copia em
# scripts/ serve aos hooks locais. Manter as duas iguais evita que o hook
# aprove o que o CI reprova.
set -eu

script_dir=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)
root=$(CDPATH='' cd -- "$script_dir/../.." && pwd)

mode=copy
[ "${1:-}" = '--check' ] && mode=check

FILES='conventions.sh check-branch-name.sh check-commit-message.sh check-commit-range.sh'
TEMPLATES='template-backend template-frontend template-microservice template-shared'

drift=0
for template in $TEMPLATES; do
  target="$root/$template/scripts"
  if [ ! -d "$root/$template" ]; then
    echo "pulado: $template (nao encontrado em $root)"
    continue
  fi
  mkdir -p "$target"
  for file in $FILES; do
    if cmp -s "$script_dir/$file" "$target/$file"; then
      continue
    fi
    if [ "$mode" = check ]; then
      echo "divergente: $template/scripts/$file"
      drift=1
    else
      cp "$script_dir/$file" "$target/$file"
      echo "atualizado: $template/scripts/$file"
    fi
  done
done

if [ "$drift" -ne 0 ]; then
  echo ''
  echo 'Rode sem --check para copiar a versao central.'
  exit 1
fi

echo 'Copias em dia.'
