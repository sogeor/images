# Contributing

## Process

1. Open an [issue](https://github.com/sogeor/images/issues) for bugs and feature requests
   (English or Russian). Report vulnerabilities privately per [SECURITY.md](SECURITY.md).
2. Create a branch `feat/...` or `fix/...` and open a pull request to `master`.
3. Requirements for a pull request to be accepted:
   - [Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/) messages;
   - signed commits;
   - all required checks green (`packer fmt / validate`, `linters`);
   - `README.md` and `CHANGELOG.md` updated when behavior changes;
   - an ADR in [`docs/adr/`](docs/adr/index.md) (status `proposed`) for architectural changes.

By contributing you agree that your contribution is licensed under [Apache-2.0](LICENSE).

## Tests

- New image functionality must come with a check in [`tests/goss/`](tests/goss)
  (or an OpenSCAP rule in [`tests/openscap/`](tests/openscap)).
- Fixed defects should get a goss check that would have caught them.
- Every build runs goss, OpenSCAP and Trivy inside the build VM, and `verify-clone` boots a clone.

## Coding standards

| Language | Standard | Enforced by |
|---|---|---|
| Shell | [Google Shell Style Guide](https://google.github.io/styleguide/shellguide.html); `#!/usr/bin/env bash`, `set -euo pipefail` | `shellcheck` |
| HCL (Packer) | Canonical formatting; every variable has `type`, `description` and, where values are restricted, `validation` | `packer fmt -check`, `packer validate -syntax-only` |
| YAML | 2-space indent, `.yamllint` | `yamllint --strict` |
| Ansible | FQCN, `name:` on every task, idempotent tasks | `ansible-lint` |
| GitHub Actions | Actions pinned by full SHA with a version comment, minimal `permissions`, `persist-credentials: false` | `actionlint`, `zizmor` |

All documentation, comments and messages are in English.

## Local setup

```bash
git clone https://github.com/sogeor/images.git
cd images
pre-commit install
pre-commit run --all-files
tools/packer.sh init ubuntu-2404-base
tools/packer.sh validate ubuntu-2404-base --syntax-only
```

Python dependencies are hash-locked; to change one, edit the `.in` file and regenerate the lock file as
described in [Operations](docs/operations.md#update-locked-python-dependencies) (keep the pip-compile header).

Requires Packer 1.16.1, Python 3.12 and `pre-commit`. Building images needs access to a Proxmox
host (see [Repository setup](docs/setup.md) and [Configuration](docs/configuration.md)).
