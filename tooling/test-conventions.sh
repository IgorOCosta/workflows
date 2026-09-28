#!/usr/bin/env sh
# Testes das regras de conventions.sh. Roda no CI deste repositorio e localmente:
#
#   sh tooling/test-conventions.sh
#
# Cada caso que ja quebrou em algum projeto vira uma linha aqui.
set -eu

script_dir=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)
. "$script_dir/conventions.sh"

failures=0

fail() {
  echo "  FALHOU: $1"
  failures=$((failures + 1))
}

branch_ok() {
  for branch in "$@"; do
    sh "$script_dir/check-branch-name.sh" "$branch" >/dev/null 2>&1 || fail "branch deveria passar: $branch"
  done
}

branch_bad() {
  for branch in "$@"; do
    if sh "$script_dir/check-branch-name.sh" "$branch" >/dev/null 2>&1; then
      fail "branch deveria falhar: $branch"
    fi
  done
}

commit_ok() {
  for header in "$@"; do
    printf '%s\n' "$header" | sh "$script_dir/check-commit-message.sh" - >/dev/null 2>&1 \
      || fail "commit deveria passar: $header"
  done
}

commit_bad() {
  for header in "$@"; do
    if printf '%s\n' "$header" | sh "$script_dir/check-commit-message.sh" - >/dev/null 2>&1; then
      fail "commit deveria falhar: $header"
    fi
  done
}

echo 'Branches validas'
branch_ok main feature/filtro-por-data fix/timeout hotfix/erro-500 release/1.4.0 \
  chore/deps docs/readme refactor/http test/e2e-login feature/v2.api_client

echo 'Branches de automacao (isentas)'
branch_ok dependabot/npm_and_yarn/vite-6.0.1 dependabot/github_actions/actions/checkout-5 \
  renovate/major-react release-please--branches--main

echo 'Branches invalidas'
branch_bad develop master feat/x Feature/x feature/ feature/Maiuscula \
  sync/openapi-contract hotfix wip/x 'feature/$(id)'

echo 'Commits validos'
commit_ok 'feat: adiciona filtro por data' \
  'fix(api): trata timeout como erro recuperavel' \
  'feat(api)!: remove o campo legado' \
  'ci(deps): bump actions/checkout from 4 to 5' \
  'chore(deps-dev): bump vitest from 2.1.0 to 2.1.1' \
  'ci(deps): bump the actions group with 3 updates' \
  'chore(main): release 1.2.0' \
  'chore(contract): sincroniza openapi.yaml do backend' \
  'Merge branch main into feature/x' \
  'Revert "feat: adiciona filtro por data"' \
  'Initial commit'

echo 'Commits invalidos'
commit_bad 'Add stuff' 'feat: Adiciona filtro' 'feat: adiciona filtro.' 'feature: x' \
  'feat:sem espaco' 'Feat: x' 'feat(API): escopo em maiuscula' \
  "feat: $(printf '%0100d' 0)"

echo ''
if [ "$failures" -gt 0 ]; then
  echo "$failures caso(s) falharam."
  exit 1
fi
echo 'Todas as regras se comportaram como esperado.'
