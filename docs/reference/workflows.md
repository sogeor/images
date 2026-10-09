# Workflows

All workflows live in `.github/workflows/`. Actions are pinned by commit SHA; permissions are
`contents: read` unless stated otherwise.

## `validate`

| | |
|---|---|
| Triggers | `pull_request`, `push` to `master`, manual |
| Secrets | none |
| Required check | yes (`packer fmt / validate`, `linters`) |

| Job | Steps |
|---|---|
| `packer fmt / validate` | `tools/packer.sh fmt`; `init` and `validate -syntax-only` for every image |
| `linters` | shellcheck, yamllint `--strict`, `ansible-playbook --syntax-check`, ansible-lint, actionlint, zizmor, gitleaks (full history) |

## `docs`

| | |
|---|---|
| Triggers | `pull_request`, `push` to `master`, manual |
| Secrets | none (`github.token` for link checks) |
| Required check | yes (`docs`) |

Steps: markdownlint (`.markdownlint.yaml`), lychee link check, `mkdocs build --strict`.

## `build`

| | |
|---|---|
| Triggers | manual, schedule `0 3 1 * *` |
| Branch | `master` only (job condition + Environment) |
| Environment | `images` |
| Concurrency | `packer-build-proxmox`, never cancelled |

| Job | Depends on | Description |
|---|---|---|
| `ubuntu-2404-base` | — | Opens WireGuard, builds the base template, uploads `reports-ubuntu-2404-base` |
| `ubuntu-2404-k8s` | base (success or skipped) | Resolves the base template, builds the k8s template, uploads reports |
| `verify clone (base)`, `verify clone (k8s)` | both builds | `tools/verify-clone.sh` for each built template, one at a time |
| `prune templates` | builds and verification succeeded | Keeps 3 newest templates per image (schedule or `prune = true`) |

Inputs: [Configuration → Workflow inputs](../configuration.md#workflow-inputs).

## `scorecard`

| | |
|---|---|
| Triggers | weekly schedule (Monday 04:17 UTC), push to `master`, ruleset changes (`branch_protection_rule`) |
| Secrets | `SCORECARD_TOKEN` |
| Permissions | `security-events: write`, `id-token: write` (publishing results) |

Uploads SARIF to **Security → Code scanning** and publishes the score for the README badge.
