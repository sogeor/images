# Changelog

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this project adheres to [SemVer](https://semver.org/).

## [Unreleased]

### Added

- `ubuntu-2404-base`: `proxmox-iso`, autoinstall via `cidata`, static build address.
- `ubuntu-2404-k8s`: `proxmox-clone` of base, containerd 2.x, Kubernetes 1.37.1 on `hold`, pre-pulled control plane images.
- `tools/packer.sh`, `tools/find-template.sh`, `tools/verify-clone.sh`, `tools/prune-templates.sh`.
- goss, OpenSCAP CIS Ubuntu 24.04 L1 Server with tailoring, summary and Ansible remediation, Trivy + SBOM.
- Talos Image Factory schematic.
- CI: `validate.yml`, `build.yml`, `scorecard.yml`.
- `prune` job: removes templates beyond the 3 latest versions after a successful clone check.
- pre-commit, Renovate, SECURITY.md.
- OpenSSF Best Practices badge (passing).
- CONTRIBUTING, GOVERNANCE, CODE_OF_CONDUCT, ROADMAP, docs/architecture.md, docs/security.md (assurance case); vulnerability response process in SECURITY.md.
- Talos Image Factory schematic ID and image URLs in `talos/README.md`.
- Documentation to the platform standard: `docs/` (getting started, setup, configuration, usage, operations, troubleshooting, reference), MADR records in `docs/adr/`, MkDocs site, issue templates.
- `docs` workflow: markdownlint, lychee link check, `mkdocs build --strict`; markdownlint pre-commit hook.

### Changed

- Layout: `images/`, `scripts/{common,debian-family}`.
- Template tags: `packer;ubuntu-2404;<kind>;...;v<build>`.
- Proxmox TLS verification enabled; Packer and plugin versions pinned.
- CI reaches Proxmox over a WireGuard network VDS ↔ pve ↔ runner (`tools/ci-wireguard.sh`) instead of Cloudflare Tunnel.
- PAM without `nullok`; tailoring: `grub2_uefi_password`, `package_timesyncd_installed`, `service_chronyd_disabled`.
- Renovate: pre-commit hooks pinned by SHA through a regex manager; `ubuntu-*` runner updates disabled.
- CI Python dependencies installed with `--require-hashes` (`*.in` → `*.txt` via pip-compile).
- Scorecard: `repo_token` from the `SCORECARD_TOKEN` secret.
- Documentation translated to English.
- Repository renamed from `packer-images` to `images`.
- Renovate: `pip-compile` manager reads the lock files (`requirements-*.txt`) instead of `*.in`; lock files carry the pip-compile header (without `--no-index`) so Renovate can regenerate them.
- Renovate: Conventional Commit titles for pull requests (`semanticCommits`).
- Pull request template renamed to `.github/PULL_REQUEST_TEMPLATE.md`.

### Removed

- `scripts/rhel-family/`.
- systemd unit for build user removal.
