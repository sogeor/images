# 0002. Local build workflow until the reusable workflow exists

- Status: superseded (2026-10-11, the build uses sogeor/workflows v0.1.1)
- Date: 2026-10-07

## Context and problem statement

Builds should call a reusable workflow from `sogeor/workflows` by tag, so that every image
repository builds the same way. That repository does not exist yet.

## Considered options

1. Wait for `sogeor/workflows` before automating builds.
2. Keep `build.yml` and `validate.yml` in this repository and move them later.

## Decision outcome

Option 2. The workflow logic lives in scripts (`tools/packer.sh`, `tools/verify-clone.sh`,
`tools/prune-templates.sh`), so the workflow files stay thin and easy to move.

### Consequences

- Builds work today.
- When `sogeor/workflows` publishes `packer-build.yml`, replace `build.yml` with
  `uses: sogeor/workflows/.github/workflows/packer-build.yml@<sha> # vX.Y.Z` and mark this ADR superseded.

## Update 2026-10-11

[sogeor/workflows](https://github.com/sogeor/workflows) v0.1.1 published the reusable `packer-build.yml` and `docs.yml` and the
actions `export-env` and `setup-mesh`. `build.yml` and `docs.yml` now call them, pinned by the commit
SHA of the tag. Repository-specific parts stay here:

- `tools/ci-build.sh` — build command that resolves the base template of `*-k8s` images;
- jobs `verify clone` and `prune templates`, which use the shared actions;
- `scorecard.yml`, because `ossf/scorecard-action` publishes results only from a workflow file of the
  scanned repository.

The design of the shared workflows is recorded in the ADRs of sogeor/workflows.
