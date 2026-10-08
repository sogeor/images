# OpenSCAP

Profile: CIS Ubuntu 24.04 Level 1 Server, SCAP Security Guide 0.1.82, with tailoring
[`tailoring-ubuntu2404.xml`](tailoring-ubuntu2404.xml).

| Disabled | Reason |
|---|---|
| `partition_for_tmp`, `mount_option_{tmp,home,var,var_tmp,var_log,var_log_audit}_*` | Single root partition (`layout: direct`); disks are grown by clones |
| `*ufw*`, `*iptables*`, `service_nftables_disabled` | Firewall is nftables |
| `grub2_password`, `grub2_uefi_password` | VM console is reachable only through Proxmox |
| `package_timesyncd_installed`, `service_chronyd_disabled` | Time sync is chrony (CIS allows either) |

Reports in `reports/<template>/`:

| File | Content |
|---|---|
| `*-openscap.html` | Human-readable report |
| `*-openscap-arf.xml` | ARF for DefectDojo |
| `*-openscap-results.xml` | XCCDF results |
| `*-openscap-summary.json` | Counts, compliance score, failed rules by severity |
| `*-openscap-remediation.yml` | Ansible remediation playbook for failed rules |

Findings do not fail the build. Remediations go to the `hardening` role in the `ansible` repository.
