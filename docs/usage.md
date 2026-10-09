# Usage

Everyday tasks: building, verifying, finding templates and reading reports.

## Build in GitHub Actions

1. **Actions → build → Run workflow**, branch `master`.
2. Choose inputs ([Configuration → Workflow inputs](configuration.md#workflow-inputs)).
3. **Run workflow.**

Jobs run one after another: `ubuntu-2404-base` → `ubuntu-2404-k8s` → `verify clone (base)` →
`verify clone (k8s)` → `prune templates` (if enabled). Every build VM uses the same address,
so jobs never run in parallel.

Expected result: all jobs green, artifacts `reports-ubuntu-2404-base` and `reports-ubuntu-2404-k8s`
on the run page, new templates in Proxmox.

## Build locally

```bash
export PROXMOX_URL=... PROXMOX_USERNAME=... PROXMOX_TOKEN=...
PKR_VAR_build_version="$(date +%Y%m%d)-0" tools/packer.sh build ubuntu-2404-base
PKR_VAR_build_version="$(date +%Y%m%d)-0" \
PKR_VAR_base_template="$(tools/find-template.sh ubuntu-2404 base)" \
  tools/packer.sh build ubuntu-2404-k8s
```

Extra Packer arguments go after the image name, for example `-on-error=abort` to keep a failed
VM for inspection (delete it manually afterwards).

## Find a template

```bash
tools/find-template.sh ubuntu-2404 base   # newest base template name
tools/find-template.sh ubuntu-2404 k8s
```

Selection is by Proxmox tags `packer;<os>;<kind>` and version-aware sorting of names.

## Verify a template

```bash
tools/verify-clone.sh ubuntu-2404-k8s-v20-1 [ip/cidr] [gateway]
```

The script creates a temporary linked clone, injects a one-time SSH key through cloud-init,
boots it and checks:

- cloud-init finished (exit code 0 or 2);
- a new machine-id and SSH host keys were generated;
- `qemu-guest-agent` is running;
- the build user `packer` does not exist;
- on Kubernetes images: `containerd` is active and `kubeadm` works.

The clone is always destroyed, also on failure.

## Reports

Each build writes `reports/<template>/` (artifact `reports-<image>` in CI, kept 90 days):

| File | Content | How to read |
|---|---|---|
| `*-goss.xml` | goss results, JUnit | Any JUnit viewer; failures fail the build |
| `*-openscap.html` | CIS Ubuntu 24.04 Level 1 Server report | Open in a browser |
| `*-openscap-summary.json` | Counts, `score_pct`, failed rules by severity | `jq '.score_pct, .counts' *-summary.json` |
| `*-openscap-results.xml`, `*-openscap-arf.xml` | XCCDF results and ARF | Import into DefectDojo |
| `*-openscap-remediation.yml` | Ansible playbook fixing failed rules | Source for the `hardening` role |
| `*-trivy.json` | Vulnerabilities of the root filesystem | `trivy convert --format table *-trivy.json` or the jq example below |
| `*-sbom.cdx.json` | CycloneDX SBOM | Dependency-Track, `trivy sbom` |

Count vulnerabilities by severity:

```bash
jq '[.Results[].Vulnerabilities[]?] | group_by(.Severity) | map({(.[0].Severity): length}) | add' reports/*/*-trivy.json
```

The `manifest/<image>.json` file records the template name, build version and git SHA of the
last build.

OpenSCAP findings do not fail the build: deviations are documented in
[`tests/openscap/README.md`](https://github.com/sogeor/images/blob/master/tests/openscap/README.md),
fixes go to the `hardening` role.

## Use a template

- Clone **as a full clone**: linked clones block template pruning.
- Provide user, SSH key and network through cloud-init (NoCloud / ConfigDrive).
- Kubernetes images already contain `kubeadm`, `kubelet`, `kubectl` (held) and control plane images;
  run `kubeadm init` / `join` with the matching version.

## Talos images

The schematic in [`talos/schematic.yaml`](https://github.com/sogeor/images/blob/master/talos/schematic.yaml)
adds `qemu-guest-agent` and `tailscale`. Its ID and image URLs are in
[`talos/README.md`](https://github.com/sogeor/images/blob/master/talos/README.md). To get the ID
for a changed schematic:

```bash
curl -fsS -X POST --data-binary @talos/schematic.yaml https://factory.talos.dev/schematics
```
