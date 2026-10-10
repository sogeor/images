# Configuration

Every option of the repository: Packer variables, environment variables of the tools, workflow
inputs and secrets.

## How values are resolved

`tools/packer.sh <cmd> <image>` copies `common/*.pkr.hcl` (with the `common-` prefix) and
`images/<image>/` into `.build/<image>/` and runs Packer there. Values come from, in order of
increasing priority:

1. `default` in the variable definition;
2. `images/<image>/<image>.pkrvars.hcl` (committed, added automatically);
3. `*.auto.pkrvars.hcl` in `images/<image>/` (local, ignored by Git);
4. `PKR_VAR_<name>` environment variables;
5. `-var name=value` arguments after the image name.

## Common variables

Defined in `common/variables.pkr.hcl`, used by every image.

| Name | Type | Default | Required | Description | Example |
|---|---|---|---|---|---|
| `repo_root` | string | — | set by `tools/packer.sh` | Absolute path of the repository | — |
| `build_version` | string | — | yes | Build identifier; letters, digits and `-` only. Becomes part of the template name and the `v<build>` tag | `20-1` (CI: `<run>-<attempt>`), `20261010-0` |
| `git_sha` | string | `local` | no | Commit written to the template description; `tools/packer.sh` sets the short SHA | `39032f3` |
| `proxmox_node` | string | `pve` | no | Proxmox node that runs the build | `pve` |
| `proxmox_insecure_skip_tls_verify` | bool | `false` | no | Skip TLS verification of the Proxmox API. Keep `false`; trust the Proxmox CA instead | `false` |
| `vm_id` | number | `0` | no | VM ID of the build VM; `0` takes the next free ID | `9000` |
| `storage_pool` | string | `local-lvm` | no | Storage for disks, EFI and cloud-init drives | `local-lvm` |
| `iso_storage_pool` | string | `local` | no | Storage for ISO images (must allow `iso` content) | `local` |
| `network_bridge` | string | `vmbr0` | no | Bridge of the build VM network adapter | `vmbr0` |
| `build_ip_cidr` | string | — | yes | Static address of the build VM; must be a valid CIDR. Use the reserved range `.250–.254` of the lab network | `192.168.100.250/24` |
| `build_gateway` | string | `192.168.100.1` | no | Default gateway of the build VM | `192.0.2.1` |
| `build_nameservers` | list(string) | `["1.1.1.1", "9.9.9.9"]` | no | DNS servers of the build VM | `["192.0.2.53"]` |
| `ssh_username` | string | `packer` | no | Temporary build user; removed before the template is created | `packer` |
| `ssh_host` | string | `""` | no | Address Packer connects to; empty means the address from `build_ip_cidr`. Set it when SSH goes through a forwarded port | `127.0.0.1` |
| `ssh_port` | number | `22` | no | SSH port for the build connection | `2222` |

## `ubuntu-2404-base`

Defined in `images/ubuntu-2404-base/variables.pkr.hcl`; committed values in `ubuntu-2404-base.pkrvars.hcl`.

| Name | Type | Default | Required | Description | Example |
|---|---|---|---|---|---|
| `iso_url` | string | — | yes (pkrvars) | URL of the Ubuntu Server live ISO | `https://releases.ubuntu.com/noble/ubuntu-24.04.5-live-server-amd64.iso` |
| `iso_checksum` | string | — | yes (pkrvars) | ISO checksum, `sha256:<64 hex>`; from `SHA256SUMS` next to the ISO | `sha256:97f3…0fd8` |
| `disk_size` | string | `10G` | no | System disk size; clones grow it | `20G` |
| `ssh_public_key` | string | — | set by `tools/packer.sh` | Public part of the ephemeral build key | — |
| `ssh_private_key_file` | string | — | set by `tools/packer.sh` | Path to the ephemeral private key | — |
| `apt_mirror` | string | `http://archive.ubuntu.com/ubuntu` | no | Primary APT mirror used during installation | `http://mirror.example.com/ubuntu` |

Fixed settings in `build.pkr.hcl`: 2 vCPU, 2 GiB RAM, q35, OVMF with pre-enrolled keys, VirtIO SCSI single,
single root partition (`layout: direct`), no swap, `task_timeout = 30m`, `ssh_timeout = 30m`.

## `ubuntu-2404-k8s`

| Name | Type | Default | Required | Description | Example |
|---|---|---|---|---|---|
| `base_template` | string | — | yes | Name of the base template to clone | `ubuntu-2404-base-v20-1` |
| `k8s_version` | string | `1.37.1` | no | Kubernetes version `X.Y.Z`; selects the pkgs.k8s.io repository `vX.Y` and the template tag `k8s-X-Y`. Updated by Renovate | `1.37.1` |
| `k8s_package_revision` | string | `1.1` | no | Debian package revision on pkgs.k8s.io (`<version>-<revision>`) | `1.1` |

Fixed settings: full clone, 2 vCPU, 4 GiB RAM, static address via cloud-init `ipconfig`, `ssh_timeout = 15m`.

## Environment variables

### Proxmox access (`tools/*.sh`, Packer)

| Name | Required | Description |
|---|---|---|
| `PROXMOX_URL` | yes | API URL, `https://<host>:8006/api2/json` |
| `PROXMOX_USERNAME` | yes | Token ID, `packer@pve!ci` |
| `PROXMOX_TOKEN` | yes | Token value |
| `PROXMOX_NODE` | no | Node name for `tools/*.sh` (default `pve`) |
| `PROXMOX_CA_FILE` | no | CA file for `curl` in `tools/*.sh` when the CA is not trusted system-wide |

### `tools/ci-wireguard.sh`

| Name | Required | Default | Description |
|---|---|---|---|
| `WG_PRIVATE_KEY` | yes | — | Runner private key |
| `WG_SERVER_PUBLIC_KEY` | yes | — | Hub public key |
| `WG_ENDPOINT` | yes | — | Hub `host:port` |
| `PROXMOX_URL` | yes | — | Used to wait until the API answers; whitespace is trimmed and the value is exported to `GITHUB_ENV` |
| `PROXMOX_CA_PEM` | yes | — | CA certificate, installed into the system trust store |
| `WG_ADDRESS` | no | `10.99.0.3/24` | Runner address in the WireGuard network |
| `WG_ALLOWED_IPS` | no | `10.99.0.0/24, 192.168.100.0/24` | Networks routed through the tunnel |

### Build scripts (set by the templates)

| Name | Script | Description |
|---|---|---|
| `REPORT_PREFIX` | `run-goss.sh`, `scan-openscap.sh`, `scan-trivy.sh` | Template name; prefix of report files |
| `BUILD_USER` | `remove-build-user.sh` | User to delete |
| `K8S_VERSION`, `K8S_PACKAGE_REVISION` | `kubernetes.sh` | Kubernetes packages to install and hold |
| `GOSS_VARS_K8S_VERSION` | `run-goss.sh` (k8s) | Expected Kubernetes version in goss checks |

## Workflow inputs

### `build`

**Actions → build → Run workflow:**

| Input | Type | Default | Description |
|---|---|---|---|
| `image` | choice `all` / `base` / `k8s` | `all` | What to build. `k8s` alone clones `base_template` or the newest base template |
| `base_template` | string | empty | Base template for `k8s`; empty means the template built in the same run or the newest by tags |
| `debug` | boolean | `false` | Sets `PACKER_LOG=1` |
| `prune` | boolean | `false` | Delete all but the 3 newest templates of each image after a successful clone check. Always on for the monthly schedule |

The schedule runs at 03:00 UTC on the 1st of every month with `image = all`.

## Secrets and variables summary

| Name | Kind | Scope | Used by |
|---|---|---|---|
| `PROXMOX_URL`, `PROXMOX_USERNAME`, `PROXMOX_CA_PEM` | variable | Environment `images` | `build` |
| `WG_ENDPOINT`, `WG_SERVER_PUBLIC_KEY` | variable | Environment `images` | `build` |
| `PROXMOX_TOKEN`, `WG_RUNNER_PRIVATE_KEY` | secret | Environment `images` | `build` |
| `SCORECARD_TOKEN` | secret | repository | `scorecard` |

How to create them: [Repository setup](setup.md).

## Tool versions

Python tools are locked with hashes in `tools/requirements-ci.txt`, `.github/requirements-lint.txt`
and `.github/requirements-docs.txt`; how to regenerate them:
[Operations → Update locked Python dependencies](operations.md#update-locked-python-dependencies).

Pinned versions are listed in [README → Versions](https://github.com/sogeor/images#versions)
and updated by Renovate. Download checksums live next to the versions in the scripts
(`GOSS_SHA256`, `SSG_SHA512`, `TRIVY_SHA256`, `ACTIONLINT_SHA256`, `GITLEAKS_SHA256`).
