# workflows

Workflows reutilizáveis do GitHub Actions e regras de convenção
compartilhados pelos meus projetos. Cada projeto tem só arquivos finos que
chamam estes por `@v1`, e corrigir aqui corrige o CI de todos no próximo run.

Os workflows **não guardam segredo nem código de projeto**. Eles rodam no
contexto de quem chama: com o código, o token e os secrets **do projeto**,
que só são repassados explicitamente e aparecem mascarados nos logs.

## Workflows

| Workflow | Faz |
| --- | --- |
| [`conventions.yml`](.github/workflows/conventions.yml) | Nome de branch, commits e título do PR (Conventional Commits), com as regras de [`tooling/`](tooling/) |
| [`ci-make.yml`](.github/workflows/ci-make.yml) | Qualidade, testes com cobertura, build, e2e, performance, contrato de API, imagem Docker e SonarCloud, tudo via alvos de `make` (o projeto define os comandos em `project.mk`) |
| [`codeql.yml`](.github/workflows/codeql.yml) | Análise de segurança (SAST) |
| [`github-agent.yml`](.github/workflows/github-agent.yml) | Labels em issues, GitHub Project, diagnóstico de PR, comentário de CI e cobertura, fechamento de issues |
| [`release.yml`](.github/workflows/release.yml) | Versão e CHANGELOG com release-please |

Todos pulam o que depende de stack quando o repositório que chama está
marcado como *Template repository*.

## Uso

```yaml
jobs:
  conventions:
    if: github.event_name == 'pull_request'
    uses: IgorOCosta/workflows/.github/workflows/conventions.yml@v1

  pipeline:
    uses: IgorOCosta/workflows/.github/workflows/ci-make.yml@v1
    permissions:
      contents: read
      pull-requests: read
    with:
      docker: true
    secrets:
      SONAR_TOKEN: ${{ secrets.SONAR_TOKEN }}
```

Os inputs de cada workflow estão documentados no cabeçalho do arquivo.

## Versões

- `v1` é uma tag móvel: aponta para a última release `v1.x.y`. Correções e
  melhorias compatíveis chegam a quem usa `@v1` sem mudar nada.
- Mudança incompatível (input removido, secret renomeado, comportamento que
  quebra quem chama) gera `v2`. Quem está em `@v1` não é afetado até migrar.
- Para controle total, fixe pelo SHA do commit em vez de `@v1`.

## Manutenção

```bash
sh tooling/test-conventions.sh           # regras de branch/commit (roda no CI)
sh tooling/sync-templates.sh [--check]   # copia tooling/ para os templates clonados ao lado
sh tooling/check-templates.sh            # templates x workflows deste commit (precisa de actionlint)
```

Todo PR roda actionlint e os testes das regras (`workflows-ci.yml`). Commits
em Conventional Commits; a release move a tag major (`workflows-release.yml`).
