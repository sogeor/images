# Architecture

## Purpose

`images` produces VM templates for the nodes of the sogeor platform. Downstream
repositories (`modules`, `management`) find templates by Proxmox tags and clone them; they never
depend on how a template was built.

## Components

| Component | Role |
|---|---|
| `images/<image>/` | Packer template per image: builder, provisioners, variables |
| `common/` | Plugin pins and variables shared by all images |
| `scripts/` | Provisioning scripts run inside the build VM |
| `ansible/image.yml` | Image-level configuration (SSH, cloud-init) |
| `tests/goss/`, `tests/openscap/` | Acceptance checks and the CIS tailoring |
| `tools/packer.sh` | Assembles `common/` and an image into `.build/<image>/` and runs Packer |
| `tools/verify-clone.sh` | Boots a clone of a template and checks it |
| `tools/prune-templates.sh` | Keeps the N latest templates of an image |
| `talos/`, `tools/talos-*.sh`, `tools/verify-talos.sh` | Talos schematic, pinned version and checksums; Talos template for Cluster API and its check ([ADR 0005](adr/0005-talos-proxmox-template.md)) |
| `.github/workflows/` | `validate` (every push/PR), `build` (monthly/manual), `scorecard` |

## Build pipeline

```mermaid
flowchart LR
  subgraph GH[GitHub-hosted runner]
    W[build.yml] --> P[tools/packer.sh]
  end
  P -->|WireGuard| API[Proxmox API]
  API --> VM[build VM 192.168.100.250]
  VM -->|provision| S[scripts + ansible]
  S --> T[goss · OpenSCAP · Trivy]
  T -->|reports| A[(workflow artifacts)]
  T --> C[cleanup] --> TPL[[template with tags]]
  TPL --> V[verify-clone] --> PR[prune]
```

1. `ubuntu-2404-base` is installed from the Ubuntu ISO (sha256-verified) with autoinstall from a `cidata` CD.
2. `ubuntu-2404-k8s` is a full clone of the newest base template plus containerd and Kubernetes.
3. Each build runs goss, OpenSCAP and Trivy, uploads reports, cleans identity data and converts the VM to a template.
4. `verify-clone` boots a clone and checks cloud-init, SSH and goss; `prune` keeps the 3 latest templates.
5. On request (`image = talos`), `talos-template.sh` downloads the Talos `nocloud` image on the runner,
   checks its sha256, uploads it to Proxmox (verified again), creates a VM from it and converts it to a template; `verify-talos.sh` checks
   the Talos API in maintenance mode.

## Network

The runner joins a WireGuard network (`10.99.0.0/24`) through the VDS hub and reaches only the
Proxmox API (`192.168.100.10:8006`) and the build VM (`192.168.100.250`: SSH `22`, Talos API `50000`). Nothing in the
home network is exposed to the internet. See [ADR 0003](adr/0003-ci-access-over-wireguard.md).

## Interface (contract)

| Output | Format |
|---|---|
| Template name | `ubuntu-2404-<kind>-v<run>-<attempt>`, `talos-base-v<run>-<attempt>` |
| Proxmox tags | `packer;ubuntu-2404;base;v<build>`, `packer;ubuntu-2404;k8s;k8s-<maj>-<min>;v<build>`, `packer;talos;base;talos-<maj>-<min>-<patch>;schematic-<12 hex>;v<build>` |
| Description | build version and git SHA |
| Reports | `reports-<image>` workflow artifact |

Consumers select the newest template by tags; existing VMs are not recreated when a new template appears.

## Template lifecycle

```mermaid
stateDiagram-v2
  [*] --> Building: build workflow / tools/packer.sh build
  Building --> Failed: any step fails
  Failed --> [*]: VM destroyed, previous templates untouched
  Building --> Template: cleanup and conversion
  Template --> Verified: verify-clone passes
  Verified --> Current: newest by tags
  Current --> Previous: a newer template is built
  Previous --> Pruned: beyond the 3 newest
  Pruned --> [*]
```

## Decisions

| ADR | Decision |
|---|---|
| [0002](adr/0002-local-build-workflow.md) | Workflows live in this repository until the shared reusable workflow exists |
| [0003](adr/0003-ci-access-over-wireguard.md) | GitHub-hosted runners reach Proxmox through a WireGuard hub |
| [0004](adr/0004-talos-image-factory.md) | Talos images come from Image Factory, not Packer |
