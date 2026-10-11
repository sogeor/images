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
| Required check | yes (`docs / docs`) |
| Implementation | reusable `docs.yml` of [sogeor/workflows](https://github.com/sogeor/workflows) v0.1.1, pinned by commit SHA |

Steps: markdownlint (`.markdownlint.yaml`), lychee link check, `mkdocs build --strict`. Lychee checks
`github.com/<owner>/<repo>/blob/...` links through `raw.githubusercontent.com` and treats 429 and
502–504 as temporary; this repository adds exclusions for `.build` and pages that require sign-in.

## `build`

| | |
|---|---|
| Triggers | manual, schedule `0 3 1 * *` |
| Branch | `master` only (job condition + Environment) |
| Environment | `images` |
| Concurrency | `packer-build-proxmox`, never cancelled |
| Shared code | sogeor/workflows v0.1.1, pinned by commit SHA: reusable `packer-build.yml`, actions `export-env`, `setup-mesh` |

| Job | Depends on | Description |
|---|---|---|
| `ubuntu-2404-base` | — | Reusable `packer-build.yml`: exports Environment values and `ENV_SECRETS`, trusts `PROXMOX_CA_PEM`, connects WireGuard, runs `tools/ci-install.sh` and `tools/ci-build.sh ubuntu-2404-base`, reads the template name from the manifest, uploads `reports-ubuntu-2404-base` |
| `ubuntu-2404-k8s` | base (success or skipped) | Same with `base_template` = template of the same run or the `base_template` input; `tools/ci-build.sh` falls back to the newest base template |
| `verify clone (base)`, `verify clone (k8s)` | both builds | `export-env`, CA trust, `setup-mesh`, then `tools/verify-clone.sh` for each built template, one at a time |
| `prune templates` | builds and verification succeeded | `export-env`, CA trust, `setup-mesh`; keeps 3 newest templates per image (schedule or `prune = true`) |

The calls use `secrets: inherit`: the reusable workflow reads Environment secrets of the caller
(`ENV_SECRETS`, `WG_RUNNER_PRIVATE_KEY`). The zizmor finding `secrets-inherit` is suppressed in place
for that reason.

Inputs: [Configuration → Workflow inputs](../configuration.md#workflow-inputs).

## `scorecard`

| | |
|---|---|
| Triggers | weekly schedule (Monday 04:17 UTC), push to `master`, ruleset changes (`branch_protection_rule`) |
| Secrets | `SCORECARD_TOKEN` |
| Permissions | `security-events: write`, `id-token: write` (publishing results) |

Uploads SARIF to **Security → Code scanning** and publishes the score for the README badge.
Kept in this repository instead of the reusable `scorecard.yml`: `ossf/scorecard-action` publishes
results only from a workflow file of the scanned repository.
