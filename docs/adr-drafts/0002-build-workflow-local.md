# ADR (draft): local build.yml until the reusable workflow exists

- Status: proposed
- Date: 2026-10-07

## Context

The build should call `workflows/.github/workflows/packer-build.yml` by tag. That repository does not exist yet.

## Decision

`build.yml` and `validate.yml` live in `images`. The logic is in `tools/packer.sh` and `tools/verify-clone.sh`.

## Consequences

Once `packer-build.yml` exists, replace `build.yml` with
`uses: sogeor/workflows/.github/workflows/packer-build.yml@<sha> # vX.Y.Z`.
