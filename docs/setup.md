# Repository setup

How to set up this repository (or your fork) so that checks, builds, dependency updates and
security features work. Steps are in order; each ends with a check.

!!! note "Placeholders"
    `<owner>` is your GitHub organization or user, `<proxmox-host>` is the address of Proxmox VE,
    `<hub-ip>` is the public address of the WireGuard hub. Replace them with your values.

## Repository settings

### About

**Repository → ⚙ next to About** (right column on the main page):

| Field | Value |
|---|---|
| Description | `Hardened VM images for the sogeor platform: Packer templates for Proxmox (Ubuntu 24.04 base and Kubernetes) and a Talos Image Factory schematic, scanned with goss, OpenSCAP CIS and Trivy with SBOM.` |
| Website | empty until the documentation site exists |
| Topics | `packer` `proxmox` `ubuntu` `talos` `kubernetes` `golden-image` `vm-templates` `hardening` `cis-benchmark` `openscap` `goss` `trivy` `sbom` `cloud-init` `devsecops` `supply-chain-security` `infrastructure-as-code` |
| Include in the home page | Releases — off until the first release; Deployments — on; Packages — off |

When typing topics, finish each with **Space**: Enter picks the highlighted suggestion instead.

### Pull requests

**Settings → General → Pull Requests:**

- Allow merge commits — off; Allow squash merging — on; Allow rebase merging — off.
- Automatically delete head branches — on.

### Branch ruleset

**Settings → Rules → Rulesets → New ruleset → New branch ruleset:**

| Setting | Value |
|---|---|
| Ruleset Name | `master` |
| Enforcement status | Active |
| Bypass list | **Add bypass → Repository admin**, mode **For pull requests only** |
| Target branches | **Add target → Include default branch** |
| Restrict deletions | on |
| Require signed commits | on |
| Require a pull request before merging | on, Required approvals `0` |
| Require status checks to pass | on, **Require branches to be up to date**; checks `packer fmt / validate`, `linters`, `docs` |
| Block force pushes | on |

Status checks appear in **Add checks** only after they have run at least once.

Check: a direct `git push` to `master` is rejected with `GH013: Repository rule violations`.

### Advanced Security

**Settings → Advanced Security:**

| Feature | Setting |
|---|---|
| Private vulnerability reporting | Enable; Require a CWE — off; Daily advisory limit — 10 |
| Dependency graph | On |
| Dependabot alerts | On |
| Malware alerts | On |
| Dependabot security updates, version updates | Off — Renovate updates dependencies |
| CodeQL analysis | **Set up → Default** (analyzes GitHub Actions workflows) |
| Code quality | Off — no supported languages |
| Secret Protection | Enable, then **Push protection → Enable** |

Check: the **Security** tab shows **Report a vulnerability**.

## Proxmox VE

Run on the Proxmox host as `root`:

```bash
pveum role add PackerBuilder -privs "Datastore.Allocate Datastore.AllocateSpace Datastore.AllocateTemplate Datastore.Audit Pool.Audit Sys.AccessNetwork Sys.Audit Sys.Modify SDN.Use VM.Allocate VM.Audit VM.Clone VM.Config.CDROM VM.Config.CPU VM.Config.Cloudinit VM.Config.Disk VM.Config.HWType VM.Config.Memory VM.Config.Network VM.Config.Options VM.Console VM.Monitor VM.PowerMgmt"
pveum user add packer@pve
pveum aclmod / -user packer@pve -role PackerBuilder
pveum user token add packer@pve ci --privsep 1
pveum aclmod / -token 'packer@pve!ci' -role PackerBuilder
```

| Privilege | Why |
|---|---|
| `Sys.AccessNetwork` | Proxmox downloads the ISO by URL (Proxmox VE 8.2+) |
| `Datastore.Allocate` | Deleting volumes when a build fails or a template is pruned |
| `VM.Monitor` | Reading the guest agent on Proxmox VE 8.x |

!!! warning "Token privileges"
    A token created with `--privsep 1` has **no** privileges of its own. Without the last
    `aclmod` command builds fail with `501` or `403`.

Save `full-tokenid` (`packer@pve!ci`) and `value` (shown once).

Check:

```bash
curl -fsS -H "Authorization: PVEAPIToken=packer@pve!ci=<token-uuid>" \
  https://<proxmox-host>:8006/api2/json/version
```

Expected: JSON with `version`.

TLS: the API certificate must contain the address you use in `PROXMOX_URL`
(`openssl x509 -in /etc/pve/local/pve-ssl.pem -noout -ext subjectAltName`). If it does not, run
`pvecm updatecerts --force`. Copy the CA: `cat /etc/pve/pve-root-ca.pem`.

## CI network access

GitHub-hosted runners must reach the Proxmox API and the build VM. The repository uses a
WireGuard hub on a small VPS; the runner joins it for the duration of a job
([ADR 0003](adr/0003-ci-access-over-wireguard.md)).

| Node | WireGuard address | Role |
|---|---|---|
| VPS hub | `10.99.0.1/24`, `51820/udp` | forwards only allowed flows |
| Proxmox host | `10.99.0.2/24` | routes the lab network, masquerades into the VM bridge |
| GitHub runner | `10.99.0.3/24` | peer for the duration of a job |

1. Generate the runner key pair (keep the private key out of the repository):

    ```bash
    umask 077; wg genkey | tee runner.key | wg pubkey > runner.pub
    ```

2. On the hub, add the runner peer to `/etc/wireguard/wg0.conf`:

    ```ini
    [Peer]
    PublicKey = <content of runner.pub>
    AllowedIPs = 10.99.0.3/32
    ```

3. On the hub, enable forwarding and allow only the required flows (`ufw` example):

    ```bash
    echo 'net.ipv4.ip_forward=1' > /etc/sysctl.d/90-forward.conf && sysctl --system
    ufw allow 51820/udp
    ufw route allow in on wg0 out on wg0 from 10.99.0.3 to <proxmox-host> port 8006 proto tcp
    ufw route allow in on wg0 out on wg0 from 10.99.0.3 to <build-vm-ip> port 22 proto tcp
    ufw route allow in on wg0 out on wg0 from 10.99.0.2 to 10.99.0.3
    ufw reload && systemctl restart wg-quick@wg0
    ```

4. On Proxmox, the peer must route the lab network and masquerade into the bridge
   (`AllowedIPs = 10.99.0.0/24` towards the hub, `PostUp` with `MASQUERADE -o vmbr0`).

Check: `wg show` on the hub lists the Proxmox and runner peers.

## Environment `images`

**Settings → Environments → New environment → `images`:**

- **Deployment branches and tags:** Selected branches → `master`.
- Optional: **Required reviewers** — every build then waits for approval, including the monthly one.

Variables (**Add environment variable**):

| Name | Example | Description |
|---|---|---|
| `PROXMOX_URL` | `https://<proxmox-host>:8006/api2/json` | Proxmox API, reachable through WireGuard |
| `PROXMOX_USERNAME` | `packer@pve!ci` | Token ID |
| `PROXMOX_CA_PEM` | content of `/etc/pve/pve-root-ca.pem` | CA to verify the API certificate |
| `WG_ENDPOINT` | `<hub-ip>:51820` | WireGuard hub endpoint |
| `WG_SERVER_PUBLIC_KEY` | `base64…=` | Hub public key |

Secrets (**Add environment secret**):

| Name | Description |
|---|---|
| `PROXMOX_TOKEN` | Token value (UUID) |
| `WG_RUNNER_PRIVATE_KEY` | Content of `runner.key`; delete the local file afterwards |

Values must not contain leading or trailing spaces or tabs.

Check: **Actions → build → Run workflow** with `image = base` passes the **Open WireGuard** step.

## Repository secret for Scorecard

1. **Profile → Settings → Developer settings → Personal access tokens → Fine-grained tokens → Generate new token:** owner `<owner>`, only this repository, **Administration: Read-only**, expiration 1 year.
2. **Repository → Settings → Secrets and variables → Actions → New repository secret:** `SCORECARD_TOKEN`.

Check: after the next push to `master` the **scorecard** run succeeds and the Branch-Protection check reflects the ruleset.

## Renovate

1. Install the [Renovate GitHub App](https://github.com/apps/renovate) → **Configure** → `<owner>` → **Only select repositories** → this repository.
2. The configuration is already in `renovate.json`: no automerge, grouped updates, SHA-pinned pre-commit hooks, hash-locked Python requirements.

Check: an issue **Dependency Dashboard** appears within an hour.

After merging a Renovate pull request, update the **Versions** table in `README.md`.

## OpenSSF Best Practices (optional)

Register the repository at [bestpractices.dev](https://www.bestpractices.dev), answer the criteria in
English with full URLs in "Met URL" fields, and add the badge to `README.md`.

## Local tools

See [Getting started](getting-started.md#1-clone-and-install-tools).
