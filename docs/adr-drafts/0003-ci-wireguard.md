# ADR (draft): WireGuard network VDS ↔ pve ↔ runner for CI

- Status: proposed
- Date: 2026-10-09

## Context

There is no self-hosted `ops` runner yet. Cloudflare Tunnel without Zero Trust returned `501` on POST requests to the Proxmox API and dropped SSH sessions.
A Selectel VDS `zelda` (`161.104.47.226`, future `edge-0`) was purchased.

## Decision

- WireGuard network `10.99.0.0/24`, hub on the VDS (`10.99.0.1`, `51820/udp`).
- `pve` (`10.99.0.2`) is a permanent peer routing `192.168.100.0/24` with `MASQUERADE` on `vmbr0`.
- The GitHub runner (`10.99.0.3`) is a peer for the duration of a job; its key is in Environment `images`. The VDS only forwards the runner to `192.168.100.10:8006` and `192.168.100.250:22`.
- Builds run on GitHub-hosted `ubuntu-24.04`, from `master` only, jobs sequential.
- Proxmox TLS is verified against the Proxmox CA (`PROXMOX_CA_PEM`).
- SSH to the VDS: `root`, port `1111`, keys only.

## Consequences

- Proxmox and VMs are not exposed; only `1111/tcp` and `51820/udp` on the VDS are public.
- VMs need a route to `10.99.0.0/24` via `192.168.100.10` (Ansible for cluster nodes).
- WireGuard may be blocked on the runner → Russia path; plan B is AmneziaWG.
- Next step: Headscale on this VDS instead of manual WireGuard.

## Alternatives

- Cloudflare Tunnel: `501` on POST, unstable SSH.
- SSH bastion with port forwarding: works, but only for fixed addresses; no shared network.
- Self-hosted runner on the VDS: CI code would run on the VDS.
