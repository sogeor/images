# Names and tags

This is the contract between `images` and the repositories that consume templates.
Changing it is a breaking change and requires an ADR.

## Template names

```text
<os>-<kind>-v<build_version>
```

| Part | Values | Example |
|---|---|---|
| `os` | `ubuntu-2404` (planned: `ubuntu-2604`, `astra-18`, `alpine`) | `ubuntu-2404` |
| `kind` | `base`, `k8s` | `k8s` |
| `build_version` | CI: `<run_number>-<run_attempt>`; local: any `[0-9A-Za-z-]+` | `20-1` |

Example: `ubuntu-2404-k8s-v20-1`.

## Proxmox tags

| Image | Tags |
|---|---|
| base | `packer;<os>;base;v<build>` |
| k8s | `packer;<os>;k8s;k8s-<major>-<minor>;v<build>` |

Example: `packer;ubuntu-2404;k8s;k8s-1-37;v20-1`.

## Selection rules for consumers

1. Filter templates that have all of `packer`, `<os>`, `<kind>` (and `k8s-<major>-<minor>` when pinning Kubernetes).
2. Take the newest by version-aware sort of the name (`sort -V`).
3. Clone as a **full clone**.
4. Existing VMs are not recreated when a newer template appears; nodes are replaced on purpose.

## Template description

```text
Ubuntu 24.04 base, build <build>, git <sha>
Ubuntu 24.04 + Kubernetes <version>, base <base template>, build <build>, git <sha>
```

## Retention

The 3 newest templates of each `<os>`/`<kind>` are kept ([Operations → Prune](../operations.md#prune-old-templates)).
