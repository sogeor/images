# OpenSCAP

Профиль: CIS Ubuntu 24.04 Level 1 Server, SCAP Security Guide 0.1.82, с tailoring
[`tailoring-ubuntu2404.xml`](tailoring-ubuntu2404.xml).

| Отключено | Причина |
|---|---|
| `partition_for_tmp`, `mount_option_{tmp,home,var,var_tmp,var_log,var_log_audit}_*` | Один корневой раздел (`layout: direct`), диск расширяется клонами |
| `*ufw*`, `*iptables*`, `service_nftables_disabled` | Межсетевой экран — nftables |
| `grub2_password`, `grub2_uefi_password` | Консоль ВМ доступна только через Proxmox |
| `package_timesyncd_installed`, `service_chronyd_disabled` | Синхронизация времени — chrony (CIS допускает один из вариантов) |

Отчёты в `reports/<template>/`:

| Файл | Содержимое |
|---|---|
| `*-openscap.html` | Отчёт для чтения |
| `*-openscap-arf.xml` | ARF для DefectDojo |
| `*-openscap-results.xml` | XCCDF results |
| `*-openscap-summary.json` | Счётчики, процент соответствия, проваленные правила по severity |
| `*-openscap-remediation.yml` | Ansible-плейбук исправлений для проваленных правил |

Несоответствия не прерывают сборку. Исправления переносятся в роль `hardening` репозитория `ansible`.
