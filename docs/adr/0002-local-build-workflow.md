# 0002. Local build workflow until the reusable workflow exists

- Status: accepted
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
