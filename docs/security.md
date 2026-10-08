# Security

## What the images provide

- No passwords: no user has a password; SSH accepts keys only (`PasswordAuthentication no`, `PermitRootLogin no`); PAM has no `nullok`.
- No build leftovers: the build user and its ephemeral key are removed; `machine-id`, SSH host keys, logs and cloud-init state are reset, so every clone gets fresh identity.
- Baseline hardening: nftables and auditd enabled, AppArmor on (Ubuntu default); checked against CIS Ubuntu 24.04 Level 1 Server by OpenSCAP on every build (report and deviations in [`tests/openscap/`](../tests/openscap)).
- Known vulnerabilities are visible: every template has a Trivy report and a CycloneDX SBOM.
- Verified inputs: the ISO, goss, SSG and Trivy are verified by sha256; Kubernetes packages by a pinned repository key fingerprint; CI Python packages by hashes; actions by commit SHA.
- Monthly rebuilds pick up security updates.

## What the images do not provide

- Full CIS compliance: about 72% of Level 1 rules pass in the template; the rest are applied by the `hardening` role in the `ansible` repository after cloning.
- Trusted SSH access: `TrustedUserCAKeys` and user accounts are configured after cloning; a template on its own is not reachable.
- Runtime protection (EDR, file integrity monitoring), disk encryption, or Secure Boot.
- Signed templates or provenance attestations (planned, see [ROADMAP](../ROADMAP.md)).
- Protection against a compromised Proxmox host.

## Assurance case

### Threat model

| Asset | Threat | Mitigation |
|---|---|---|
| Template contents | Tampered inputs (ISO, tools, packages) | sha256 / fingerprint / hash pinning; HTTPS with certificate verification |
| Template contents | Secrets or credentials baked into the image | Ephemeral build key, build user removal, no passwords, cleanup checked by goss |
| CI | Malicious workflow change or injection | Branch ruleset, required checks, zizmor/actionlint/CodeQL, actions pinned by SHA, minimal `permissions` |
| CI credentials | Theft of the Proxmox token or WireGuard key | Secrets only in Environment `images` limited to `master`; scoped Proxmox role; runner reaches only two addresses |
| Home network | Exposure through the build path | No inbound ports at home; WireGuard hub on the VDS with forwarding limited to Proxmox API and the build VM |
| Repository | Leaked secrets in commits | gitleaks (pre-commit and CI), GitHub secret scanning with push protection |

### Trust boundaries

1. GitHub (repository, Actions runner) ↔ the WireGuard network: crossed only by jobs in Environment `images` from `master`.
2. WireGuard network ↔ home network: the VDS forwards the runner only to `192.168.100.10:8006` and `192.168.100.250:22`.
3. Build VM ↔ internet: package mirrors and tool downloads, all verified.
4. Template ↔ consumers: consumers trust templates by tag; identity is regenerated on clone.

### Secure design principles

- Least privilege: dedicated Proxmox role and token, minimal workflow permissions, narrow forwarding rules.
- Fail-safe defaults: TLS verification on, SSH keys only, builds only from protected `master`.
- Economy of mechanism: one wrapper script, one build path for all images.
- Complete mediation and defense in depth: required checks before merge, verification of every download, scans after every build.
- Open design: everything is public; no security through obscurity.

### Common weaknesses countered

| Weakness | Countermeasure |
|---|---|
| Shell injection, unquoted variables (CWE-78) | `set -euo pipefail`, shellcheck |
| GitHub Actions expression injection | Inputs passed through `env:`, zizmor, CodeQL |
| Download of code without integrity check (CWE-494) | Checksums and pinned versions everywhere |
| Hard-coded credentials (CWE-798) | No credentials in code; gitleaks, secret scanning |
| Improper input validation (CWE-20) | `validation` blocks on all restricted Packer variables; template name regex in CI |
| Use of vulnerable components (CWE-1395) | Renovate, Dependabot alerts, Trivy on every image |
