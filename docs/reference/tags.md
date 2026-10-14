# Names and tags

This is the contract between `images` and the repositories that consume templates.
Changing it is a breaking change and requires an ADR.

## Template names

```text
<os>-<kind>-v<build_version>
```

| Part | Values | Example |
|---|---|---|
| `os` | `ubuntu-2404`, `talos` (planned: `ubuntu-2604`, `astra-18`, `alpine`) | `ubuntu-2404` |
| `kind` | `base`, `k8s` (`talos`: `base` only) | `k8s` |
| `build_version` | CI: `<run_number>-<run_attempt>`; local: any `[0-9A-Za-z-]+` | `20-1` |

Examples: `ubuntu-2404-k8s-v20-1`, `talos-base-v20-1`.

## Proxmox tags

| Image | Tags |
|---|---|
| base | `packer;<os>;base;v<build>` |
| k8s | `packer;<os>;k8s;k8s-<major>-<minor>;v<build>` |

| Talos | `packer;talos;base;talos-<major>-<minor>-<patch>;schematic-<first 12 hex of the schematic ID>;v<build>` |

Examples: `packer;ubuntu-2404;k8s;k8s-1-37;v20-1`,
`packer;talos;base;talos-1-14-2;schematic-7d4c31cbd96d;v20-1`.

Talos templates are built once per pair of Talos version and schematic, so their build number does
not change while the pair stays the same.

## OpenStack images (planned)

| | Value |
|---|---|
| Talos name | `talos-v<version>-<first 12 hex of the schematic ID>`, for example `talos-v1.14.2-7d4c31cbd96d` |
| Talos properties | the Proxmox tag values, `sogeor_build=v<build>`, family `sogeor-talos-base` |
| Ubuntu | `<os>-<kind>-v<build>`, family `sogeor-<os>-<kind>` |

## Selection rules for consumers

1. Filter templates that have all of `packer`, `<os>`, `<kind>` (and `k8s-<major>-<minor>` when pinning Kubernetes).
2. Take the newest by version-aware sort of the name (`sort -V`).
3. Clone as a **full clone**.
4. Existing VMs are not recreated when a newer template appears; nodes are replaced on purpose.
5. Cluster API (CAPMOX `templateSelector.matchTags` with `matchPolicy: exact`) selects a Talos template
   by its full tag set, including `v<build>`.

## Template description

```text
Ubuntu 24.04 base, build <build>, git <sha>
Ubuntu 24.04 + Kubernetes <version>, base <base template>, build <build>, git <sha>
Talos v<version> nocloud, schematic <id>, build <build>, git <sha>
```

## Retention

The 3 newest templates of each `<os>`/`<kind>` are kept (for Talos: the 3 newest version/schematic pairs) ([Operations → Prune](../operations.md#prune-old-templates)).
