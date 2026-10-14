# 0005. Talos template for Cluster API without Packer

- Status: accepted
- Date: 2026-10-15

## Context and problem statement

Cluster API creates nodes only by cloning a ready image. On Proxmox VE, CAPMOX clones a VM
template selected by an exact set of tags; on OpenStack, CAPO boots a Glance image. Talos
installation from the ISO ([ADR 0004](0004-talos-image-factory.md)) covers the management cluster
created by OpenTofu, but not CAPI. A Talos template is needed that holds no machine configuration:
the bootstrap provider (CABPT) supplies it through cloud-init (NoCloud) when a node is created.

## Decision drivers

- The image must be exactly what Image Factory produces for the schematic and version.
- The download must be checksum-verified.
- A template that a cluster pins must not disappear because of routine rebuilds.

## Considered options

1. Packer `proxmox-iso`: boot a live ISO and write the Talos disk image with `dd`.
2. Proxmox API only: put the image into a storage with content `import` (checksum-verified), then a
   VM whose disk is created with `import-from`, converted to a template.

## Decision outcome

Option 2, implemented in `tools/talos-template.sh`. Packer requires a boot ISO and cannot import a
disk image; option 1 adds a live system and a manual disk write.

- Image: `nocloud-amd64.qcow2` from Image Factory for the schematic and version in `talos/talos.env`;
  the sha256 is pinned there, checked on the runner after the download and again by Proxmox on upload. Image Factory does not
  publish checksums for custom schematics; `tools/talos-checksum.sh` computes them, and the images
  were checked to be byte-identical on repeated downloads.
- VM: `q35`, OVMF with a 4M EFI disk without pre-enrolled keys (the image is not signed for Secure
  Boot), VirtIO SCSI single, `qemu-guest-agent`, cloud-init drive, VirtIO network, serial console.
- No TPM in this version: Talos seals disk encryption keys to the TPM only when booted with Secure
  Boot. Secure Boot with TPM is a separate future decision.
- One template per pair of Talos version and schematic: the script exits without changes when a
  template with the same `talos-<version>` and `schematic-<id>` tags exists. The build number stays
  the same while the pair is the same, so consumers can pin it.
- Name `talos-base-v<build>` follows `<os>-<kind>-v<build>`; tags
  `packer;talos;base;talos-<maj>-<min>-<patch>;schematic-<12 hex>;v<build>`
  ([Names and tags](../reference/tags.md)).
- `tools/verify-talos.sh` boots a clone and checks the Talos API in maintenance mode (port 50000)
  and the guest agent. Builds run only on request (`image = talos`), never on the monthly schedule.

### Consequences

- The storage that receives the image must allow the content type **Import** (Proxmox VE 8.4+).
- A Renovate update of the Talos version needs `tools/talos-checksum.sh` on the same branch.
- Pruning keeps the 3 newest Talos templates, that is the 3 newest version/schematic pairs.
- The CI runner must reach port 50000 of the verification VM through the WireGuard hub.
- The OpenStack image (`openstack-amd64.qcow2`, checksum already pinned) is published together with
  the OpenStack images of Ubuntu.

## Update 2026-10-15

The first build used `download-url`, so the Proxmox host fetched the image itself. The task hung in
retries: the host could not keep a connection to the Image Factory CDN. The runner now downloads the
image, checks the sha256 and uploads it with `POST /nodes/{node}/storage/{storage}/upload`
(content `import`, sha256 checked by Proxmox again). The Proxmox host needs no internet access
for Talos images. The upload is sent without `Expect: 100-continue`: pveproxy answers it with
`400 Bad Request` and an empty body.
