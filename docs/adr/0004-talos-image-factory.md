# 0004. Talos images from Image Factory

- Status: accepted
- Date: 2026-10-10

## Context and problem statement

Talos Linux nodes need system extensions (`qemu-guest-agent`, `tailscale`). Talos is immutable:
extensions are part of the boot image, not installed later.

## Considered options

1. Build Talos images with Packer.
2. Use the official [Talos Image Factory](https://factory.talos.dev) with a schematic kept as code.

## Decision outcome

Option 2. `talos/schematic.yaml` declares the extensions; its schematic ID and image URLs are
published in `talos/README.md` and consumed by cluster configuration.

### Consequences

- No Packer build for Talos; images are reproducible from the schematic and the Talos version.
- The schematic ID changes only when `schematic.yaml` changes and must then be updated where it is used.
- Image availability depends on Image Factory; the URLs are pinned to a Talos version.
