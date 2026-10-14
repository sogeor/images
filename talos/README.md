# Talos

| | |
|---|---|
| Version | `v1.14.2` |
| Extensions | `siderolabs/qemu-guest-agent`, `siderolabs/tailscale` |
| Schematic ID | `7d4c31cbd96db9f90c874990697c523482b2bae27fb4631d5583dcd9c281b1ff` |
| Pinned values | [`talos.env`](talos.env): version, schematic, sha256 of the images and `talosctl` |

```bash
curl -fsS -X POST --data-binary @talos/schematic.yaml https://factory.talos.dev/schematics
```

| | URL |
|---|---|
| ISO | `https://factory.talos.dev/image/7d4c31cbd96db9f90c874990697c523482b2bae27fb4631d5583dcd9c281b1ff/v1.14.2/nocloud-amd64.iso` |
| Disk image (Proxmox template) | `https://factory.talos.dev/image/7d4c31cbd96db9f90c874990697c523482b2bae27fb4631d5583dcd9c281b1ff/v1.14.2/nocloud-amd64.qcow2` |
| Disk image (OpenStack) | `https://factory.talos.dev/image/7d4c31cbd96db9f90c874990697c523482b2bae27fb4631d5583dcd9c281b1ff/v1.14.2/openstack-amd64.qcow2` |
| Installer | `factory.talos.dev/nocloud-installer/7d4c31cbd96db9f90c874990697c523482b2bae27fb4631d5583dcd9c281b1ff:v1.14.2` |
