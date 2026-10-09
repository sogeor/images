# Governance

## Model

`images` is part of the sogeor platform and follows a single-maintainer model.
The maintainer makes final decisions on scope, design and releases. Significant design
decisions are recorded as ADRs in [`docs/adr/`](docs/adr/index.md).

Anyone may propose changes through issues and pull requests. Proposals are accepted when they
fit the [roadmap](ROADMAP.md), pass all required checks and follow [CONTRIBUTING.md](CONTRIBUTING.md).

## Roles

| Role | Who | Responsibilities |
|---|---|---|
| Maintainer | [@bloogefest](https://github.com/bloogefest) | Reviews and merges pull requests; triages issues; handles vulnerability reports ([SECURITY.md](SECURITY.md)); runs and approves image builds (Environment `images`); manages secrets, branch rules and repository settings; keeps the roadmap and documentation current. |
| Contributor | Anyone | Opens issues and pull requests that follow [CONTRIBUTING.md](CONTRIBUTING.md). |
| Renovate (bot) | Mend Renovate | Opens dependency update pull requests; never merges. |

## Decisions

- Routine changes: merged by the maintainer once required checks pass.
- Architectural changes: an ADR in `docs/adr/` is added in the same pull request.
- Security fixes: handled privately per [SECURITY.md](SECURITY.md).

## Continuity

The organization `sogeor` owns the repository. If the maintainer becomes unavailable, an
organization owner can take over the maintainer role.
