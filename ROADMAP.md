# Roadmap

Horizon: through Q4 2027. Order follows the sogeor platform plan.

## Planned

- `ubuntu-2404-base`, `ubuntu-2404-k8s` for Proxmox: monthly rebuilds, CIS Level 1 Server findings fixed via the `hardening` role in the `ansible` repository.
- `astra-18-base` and `astra-18-k8s` for Proxmox (preseed, ISO supplied manually).
- `ubuntu-2404-k8s` for Yandex Cloud (`hashicorp/yandex` builder, image family `sogeor-ubuntu-2404-k8s`).
- Talos Image Factory schematic with a published schematic ID and image URLs.
- Build provenance and SBOM attestations for templates (SLSA).
- Reusable build workflow from `sogeor/workflows` instead of the local `build.yml`.
- Replace the manual WireGuard network with Headscale; AmneziaWG as a fallback if WireGuard is blocked.

## Not planned

- RHEL-family images.
- Builders other than Proxmox and Yandex Cloud (other clouds may come later through the provider-neutral node model).
- Desktop or GUI images.
- Bit-for-bit reproducible OS images.
