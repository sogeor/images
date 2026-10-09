# 0003. CI access to Proxmox over a WireGuard hub

- Status: accepted
- Date: 2026-10-09

## Context and problem statement

Builds run on GitHub-hosted runners, but Proxmox VE and the build VM live in a home network
behind NAT with no inbound ports. Cloudflare Tunnel without Zero Trust returned `501` on POST
requests to the Proxmox API and dropped SSH sessions. A small VPS with a public address is available.

## Decision drivers

- Do not expose Proxmox or VMs to the internet.
- No self-hosted runner that would execute CI code inside the lab.
- Verify TLS of the Proxmox API.

## Considered options

1. Cloudflare Tunnel public hostnames.
2. SSH bastion on the VPS with port forwarding.
3. WireGuard network with the VPS as hub; the runner joins for the duration of a job.
4. Self-hosted runner on the VPS or in the lab.

## Decision outcome

Option 3.

- Network `10.99.0.0/24`: hub `10.99.0.1` (`51820/udp`), Proxmox `10.99.0.2` (routes the lab network,
  masquerades into the VM bridge), runner `10.99.0.3`.
- The hub forwards the runner only to the Proxmox API (`:8006`) and SSH of the build VM (`:22`).
- The runner key is a secret of Environment `images`, available only to `master`.
- The Proxmox API certificate is verified against `PROXMOX_CA_PEM`.

### Consequences

- Only `51820/udp` and the VPS SSH port are public.
- All build and verification VMs use the same address; jobs run sequentially.
- WireGuard may be blocked on some paths; plan B is AmneziaWG.
- Replaced by a Headscale mesh when the platform `edge` is deployed.

## Pros and cons of the other options

- Cloudflare Tunnel: no inbound ports, but `501` on POST and unstable SSH.
- SSH bastion: works for fixed addresses only; no general network.
- Self-hosted runner: CI code would run with access to the lab.
