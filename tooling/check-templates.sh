#!/usr/bin/env sh
# Valida os templates contra os workflows centrais DESTE commit (IgorOCosta/workflows).
#
#   sh tooling/check-templates.sh
#
# O actionlint sozinho nao enxerga workflow remoto (`...@v1`), entao nao
# confere se o `with:`/`secrets:`/`permissions:` que um template passa bate
# com o que o workflow central aceita. Este script monta, para cada template,
# um repositorio temporario em que as chamadas `@v1` viram chamadas locais aos
# workflows daqui — e ai o actionlint valida os dois lados juntos.
#
# Rode antes de publicar uma release deste repositorio que mude inputs, secrets
# ou permissoes de um workflow reutilizavel.
#
# Requisitos: actionlint no PATH (go install github.com/rhysd/actionlint/cmd/actionlint@latest)
# e os templates clonados ao lado deste repositorio (ver sync-templates.sh).
set -eu

script_dir=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)
base=$(CDPATH='' cd -- "$script_dir/.." && pwd)
root=$(CDPATH='' cd -- "$base/.." && pwd)

command -v actionlint >/dev/null 2>&1 || {
  echo 'check-templates: actionlint nao encontrado no PATH.' >&2
  exit 2
}

TEMPLATES='template-backend template-frontend template-microservice template-shared'
REUSABLE='conventions ci-make codeql github-agent release'

work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT

failures=0
for template in $TEMPLATES; do
  src="$root/$template/.github/workflows"
  if [ ! -d "$src" ]; then
    echo "pulado: $template (nao encontrado em $root)"
    continue
  fi

  dir="$work/$template"
  mkdir -p "$dir/.github/workflows"
  for name in $REUSABLE; do
    cp "$base/.github/workflows/$name.yml" "$dir/.github/workflows/reusable-$name.yml"
  done
  for file in "$src"/*.yml; do
    sed -E 's#IgorOCosta/workflows/\.github/workflows/([a-z-]+)\.yml@v1#./.github/workflows/reusable-\1.yml#' \
      "$file" > "$dir/.github/workflows/$(basename "$file")"
  done

  if (cd "$dir" && git init -q && actionlint); then
    echo "ok     $template"
  else
    echo "FALHA  $template"
    failures=$((failures + 1))
  fi
done

[ "$failures" -eq 0 ] || { echo "$failures template(s) com erro."; exit 1; }
echo 'Todos os templates batem com os workflows centrais.'
