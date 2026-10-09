# Getting started

This guide takes you from an empty workstation to a verified `ubuntu-2404-base` template in
your Proxmox VE. For automated builds in GitHub Actions continue with [Repository setup](setup.md).

## Requirements

| Requirement | Version | Why |
|---|---|---|
| Linux, macOS or WSL 2 | — | Scripts are written for bash |
| [Packer](https://developer.hashicorp.com/packer/install) | 1.16.1 | Builds the images |
| Python | 3.12 | Runs ansible-core and linters |
| `xorriso` | any | Packer creates the `cidata` CD image with it |
| `jq`, `curl`, `ssh` | any | Used by `tools/*.sh` |
| `pre-commit` | any recent | Runs the same checks as CI |
| Proxmox VE | 8.2 or later | Build target; API token per [Repository setup](setup.md#proxmox-ve) |
| Network access | — | Your workstation must reach the Proxmox API and the build VM address |

## 1. Clone and install tools

```bash
git clone https://github.com/sogeor/images.git
cd images
python3 -m pip install --user --require-hashes -r tools/requirements-ci.txt
python3 -m pip install --user pre-commit
pre-commit install
```

Expected result: `ansible-playbook --version` prints ansible-core 2.21.5; `pre-commit` reports
`pre-commit installed at .git/hooks/pre-commit`.

## 2. Check the templates offline

```bash
tools/packer.sh fmt
tools/packer.sh init ubuntu-2404-base
tools/packer.sh validate ubuntu-2404-base --syntax-only
```

Expected result: no output from `fmt`, `The configuration is valid.` from `validate`.

## 3. Prepare Proxmox VE

Create the `PackerBuilder` role and the `packer@pve!ci` API token as described in
[Repository setup → Proxmox VE](setup.md#proxmox-ve).

## 4. Set the connection variables

```bash
export PROXMOX_URL="https://<proxmox-host>:8006/api2/json"
export PROXMOX_USERNAME='packer@pve!ci'
export PROXMOX_TOKEN='<token-uuid>'
```

If Proxmox uses its own CA, trust it system-wide (`/etc/pve/pve-root-ca.pem`) or, for `tools/*.sh`
only, set `PROXMOX_CA_FILE`. Do not disable TLS verification.

The build VM gets a static address. Defaults are `192.168.100.250/24` with gateway `192.168.100.1`;
override them for your network in a local file (ignored by Git):

```hcl
# images/ubuntu-2404-base/local.auto.pkrvars.hcl
build_ip_cidr = "192.0.2.250/24"
build_gateway = "192.0.2.1"
```

All options: [Configuration](configuration.md).

## 5. Build the base template

```bash
PKR_VAR_build_version="$(date +%Y%m%d)-0" tools/packer.sh build ubuntu-2404-base
```

What happens (20–40 minutes):

1. Proxmox downloads the Ubuntu ISO and verifies its sha256.
2. The VM installs Ubuntu unattended from the `cidata` CD.
3. Packer connects over SSH with an ephemeral key, updates packages and applies hardening.
4. goss, OpenSCAP and Trivy run inside the VM; reports are copied to `reports/<template>/`.
5. The VM is cleaned (machine-id, host keys, logs, build user) and converted to a template.

Expected result: the last lines contain `Builds finished` and the template
`ubuntu-2404-base-v<date>-0` appears in Proxmox with tags `packer;ubuntu-2404;base;v<date>-0`.

## 6. Verify a clone

```bash
tools/verify-clone.sh "$(tools/find-template.sh ubuntu-2404 base)"
```

Expected result: `ok: <hostname> <machine-id>`; the temporary VM is destroyed automatically.

## 7. Build the Kubernetes template (optional)

```bash
PKR_VAR_build_version="$(date +%Y%m%d)-0" \
PKR_VAR_base_template="$(tools/find-template.sh ubuntu-2404 base)" \
  tools/packer.sh build ubuntu-2404-k8s
```

## Next steps

- Automate builds in CI: [Repository setup](setup.md).
- Read the reports: [Usage → Reports](usage.md#reports).
- Something failed: [Troubleshooting](troubleshooting.md).
