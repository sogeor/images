# Troubleshooting

Symptom → cause → fix. Most entries come from real build failures.

## Proxmox API

| Symptom | Cause | Fix |
|---|---|---|
| `501 Not Implemented` or `403 Permission check failed` on any call | API token created with `--privsep 1` has no ACL of its own | `pveum aclmod / -token 'packer@pve!ci' -role PackerBuilder` |
| `403` on ISO download (`download-url`) | Role lacks `Sys.AccessNetwork` (Proxmox VE 8.2+) | Add it to `PackerBuilder` (`pveum role modify`) |
| `403` deleting a volume after a failed build | Role lacks `Datastore.Allocate` | Add it to `PackerBuilder` |
| `x509: certificate signed by unknown authority` | Proxmox CA is not trusted | Trust `/etc/pve/pve-root-ca.pem` (CI: `PROXMOX_CA_PEM`); do not skip TLS verification |
| `x509: certificate is valid for …, not <address>` | The API certificate lacks the address used in `PROXMOX_URL` | `pvecm updatecerts --force` or use a name from the certificate |
| `parse "\thttps://…": net/url: invalid control character` | Invisible tab or space in a GitHub variable | Re-enter the value; `export-env` and `setup-mesh` trim single-line values |
| Packer stops after ~1 minute while Proxmox task still runs | Default `task_timeout` of the Proxmox builder is 1 minute | Templates set `task_timeout = "30m"`; keep it when adding images |

## CI network

| Symptom | Cause | Fix |
|---|---|---|
| **Connect mesh** fails: `MESH_CHECK_ADDRESS` not reachable | No handshake: wrong key, endpoint or blocked UDP; or wrong `WG_ALLOWED_IPS` | `wg show` on the hub; check `WG_ENDPOINT`, `WG_SERVER_PUBLIC_KEY`, `WG_ADDRESS`, `WG_ALLOWED_IPS`, the runner peer `PublicKey`; check that UDP `51820` is open |
| `PROXMOX_TOKEN: parameter null or not set` | `ENV_SECRETS` missing or without `PROXMOX_TOKEN=` | Set the Environment secret `ENV_SECRETS` ([setup](setup.md#environment-images)) |
| `invalid base template` in `ubuntu-2404-k8s` | The `base_template` input has a wrong name | Use `ubuntu-2404-base-v<build>` or leave it empty |
| Required check `docs` stays pending | The check is now named `docs / docs` | Update the status check in the ruleset ([setup](setup.md)) |
| Handshake ok, API times out | Hub does not forward, or Proxmox does not route back | Check `net.ipv4.ip_forward`, `ufw route` rules, `AllowedIPs` and `MASQUERADE` on Proxmox |
| WireGuard blocked in the network path | DPI blocks WireGuard | Plan B: AmneziaWG ([ADR 0003](adr/0003-ci-access-over-wireguard.md)) |

## Installation and SSH

| Symptom | Cause | Fix |
|---|---|---|
| Installer waits for input | GRUB menu differs from `boot_command` | Open the VM console, compare the menu with `boot_command` in `build.pkr.hcl` |
| `Waiting for SSH to become available` until timeout | Wrong `build_ip_cidr`/gateway, or the runner cannot reach the build VM | Check the VM console for the address; check routing from the build host |
| Package downloads time out | Slow or unreachable regional mirror | Use `archive.ubuntu.com` (`apt_mirror`); retries are already enabled |
| `ssh` reported disabled by goss | Ubuntu 24.04 uses socket activation | Check `ssh.socket`, not `ssh.service` |

## Provisioning and reports

| Symptom | Cause | Fix |
|---|---|---|
| `REPORT_PREFIX: parameter null or not set` | Environment variables not passed through `sudo` | Shell provisioners must use `execute_command = "sudo env {{ .Vars }} bash '{{ .Path }}'"` |
| Uploaded directory appears as a file | `source` ends with `/` in a file provisioner | Use `source = "…/dir"` without the trailing slash and `destination = "/tmp/"` |
| `Permission denied` downloading reports | Reports owned by root | Scripts `chown` reports to `SUDO_USER` |
| `oscap xccdf generate fix` fails | The tailoring file is not passed | Pass `--tailoring-file` (already in `scan-openscap.sh`) |
| Trivy times out downloading its database | Slow network to the database mirror | `--timeout 30m` is set; rerun the job |
| `kubernetes.sh`: fingerprint mismatch | pkgs.k8s.io key rotated | [Operations → key expiry](operations.md#kubernetes-repository-key-expiry) |
| Shared Packer file overwritten | A file in `images/<image>/` has the same name as one in `common/` | `tools/packer.sh` copies common files with the `common-` prefix; keep it |
| Packer rejects the version | `build_version` contains a dot | Use letters, digits and `-` only (`20-1`) |

## Clone verification

| Symptom | Cause | Fix |
|---|---|---|
| `cloud-init status` exits with 2 | Recoverable warnings during first boot | Treated as success; inspect `cloud-init status --long` in the log |
| `build user still exists` | Build user removal failed | Check the `remove-build-user.sh` step of the build |
| Template cannot be deleted by `prune` | A VM is a linked clone of it | Use full clones for VMs; delete or full-clone the dependent VM |

## Talos template

| Symptom | Cause | Fix |
|---|---|---|
| `download-url` fails with `content type 'import' not allowed` | The storage does not allow Import | Add **Import** to the storage content ([setup](setup.md#proxmox-ve)) |
| `sha256sum: WARNING: 1 computed checksum did NOT match` | `talos/talos.env` has old checksums after a version or schematic change | Run `tools/talos-checksum.sh` and commit |
| `Talos API 192.168.100.250:50000 not reachable` | The hub does not forward port 50000, or the VM does not boot (Secure Boot keys enrolled) | Allow `192.168.100.250:50000` on the hub ([setup](setup.md#ci-network-access)); the template must use `pre-enrolled-keys=0` |
| `qemu-guest-agent does not answer` | The schematic lacks the `qemu-guest-agent` extension | Check `talos/schematic.yaml` and the schematic ID |
| `already exists`, no new template | A template for the same Talos version and schematic exists | Expected; change the version or schematic to build a new one |
| A `tools/*.sh` call fails with `METHOD /path: {...}` | Proxmox rejected the request; the JSON shows the reason (`errors`, `message`) | Fix the parameter named in `errors` |

Proxmox `download-url` tasks for Image Factory may hang in retries (`Read error ... Connection timed out`)
when the Proxmox host has poor connectivity to the Image Factory CDN. `tools/talos-template.sh` waits
10 minutes, stops the task and fails; run **build** again later. A task left from an interrupted run:
**Tasks** → double-click → **Stop**.

## Scorecard

| Symptom | Cause | Fix |
|---|---|---|
| `ossf/scorecard-action` fails with `workflow verification failed` | The calling `scorecard.yml` breaks a Scorecard API check: top-level `env:` or `defaults:`, write permissions at workflow level, or `id-token: write` on another job | Restore `permissions: {}` at workflow level and grant permissions only to the `scorecard` job ([Workflows reference](reference/workflows.md#scorecard)) |
| Branch-Protection check scores 0 or is skipped | `SCORECARD_TOKEN` missing or expired | Renew the token ([setup](setup.md#repository-secret-for-scorecard)) |

## Dependencies

| Symptom | Cause | Fix |
|---|---|---|
| Dependency Dashboard shows **Config Migration Needed** for `pip-compile` | Renovate now reads lock files: `managerFilePatterns` must match the generated `requirements-*.txt`, not `*.in` | Point the `pip-compile` pattern in `renovate.json` to `requirements-*.txt`; keep the pip-compile header in lock files ([Operations](operations.md#update-locked-python-dependencies)) |
| Renovate cannot update a lock file, log mentions `--no-index` or missing header | The lock file was generated with `--no-header`, or the header contains `--no-index` | Regenerate with the header and remove `--no-index` from it ([Operations](operations.md#update-locked-python-dependencies)) |
| `pip install --require-hashes` fails with a hash mismatch | The lock file was edited by hand or generated for another Python version | Regenerate with Python 3.12 |

## Still stuck

Run the build with `debug = true` (CI) or `PACKER_LOG=1` (local) and open an
[issue](https://github.com/sogeor/images/issues/new/choose) with the log (remove secrets and private addresses).
