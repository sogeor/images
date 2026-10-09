# Scripts and tools

## `tools/` — run on the workstation or CI runner

| Script | Usage | Description |
|---|---|---|
| `packer.sh` | `fmt` · `init <image>` · `validate <image> [--syntax-only]` · `build <image> [packer args]` | Assembles `.build/<image>/`, adds `<image>.pkrvars.hcl`; on `build` of a base image generates an ephemeral ed25519 key and removes it on exit. Requires `PKR_VAR_build_version` for `build` |
| `find-template.sh` | `<os> <kind>` | Prints the newest template name with tags `packer;<os>;<kind>` |
| `verify-clone.sh` | `<template> [ip/cidr] [gateway]` | Linked clone, cloud-init with a one-time key, boot, checks, destroy. Defaults `192.168.100.250/24`, `192.168.100.1`; honours `PKR_VAR_ssh_host`, `PKR_VAR_ssh_port` |
| `prune-templates.sh` | `<os> <kind> [keep=3] [--apply]` | Lists (dry run) or deletes templates beyond the newest `keep`; skips templates whose deletion fails (linked clones) with a warning |
| `pve-api.sh` | sourced | `pve_api METHOD PATH [curl args]`, `pve_wait_task UPID`, `pve_templates OS KIND`; token passed via `curl --config -`, never on the command line |
| `ci-install.sh` | — | CI: installs `xorriso` and hash-locked `tools/requirements-ci.txt` |
| `ci-wireguard.sh` | — | CI: joins the WireGuard network, trusts the Proxmox CA, waits for the API ([configuration](../configuration.md#toolsci-wireguardsh)) |

## `scripts/` — run inside the build VM as root

| Script | Images | Description |
|---|---|---|
| `debian-family/update.sh` | all | `apt-get update` and `dist-upgrade` with retries |
| `debian-family/packages.sh` | base | Base packages (chrony, nftables, auditd, openscap-scanner, …), services, removes `nullok` from PAM |
| `debian-family/kubernetes.sh` | k8s | Kernel modules and sysctl, containerd (`SystemdCgroup`), pkgs.k8s.io repository with key fingerprint check, kubeadm/kubelet/kubectl `hold`, pre-pulls control plane images |
| `debian-family/cleanup.sh` | all | Removes caches, machine-id, host keys, logs, histories; `fstrim` |
| `common/run-goss.sh` | all | Downloads goss (sha256-verified), runs `/tmp/goss.yaml`, writes JUnit |
| `common/scan-openscap.sh` | all | Downloads SCAP Security Guide (sha512-verified), CIS L1 Server with tailoring, HTML/ARF/XCCDF, remediation playbook, summary JSON |
| `common/scan-trivy.sh` | all | Downloads Trivy (sha256-verified), root filesystem scan (JSON) and CycloneDX SBOM |
| `common/cloud-init-reset.sh` | all | `cloud-init clean`, datasource list `NoCloud, ConfigDrive`, removes installer network config |
| `common/remove-build-user.sh` | all | Deletes the build user and its home; last step of every build |

## Other files

| Path | Description |
|---|---|
| `ansible/image.yml` | Image hardening: sshd settings, kernel sysctl (profile `image` only) |
| `ansible/requirements.yml` | Ansible collections (pinned) |
| `tests/goss/{base,k8s}.yaml` | Acceptance checks run during the build |
| `tests/openscap/tailoring-ubuntu2404.xml` | Disabled CIS rules with reasons in `tests/openscap/README.md` |
| `talos/schematic.yaml` | Talos Image Factory schematic |
