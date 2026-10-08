# Changelog

Формат — [Keep a Changelog](https://keepachangelog.com/ru/1.1.0/), версии — [SemVer](https://semver.org/lang/ru/).

## [Unreleased]

### Added
- Job `prune`: удаление шаблонов старше 3 версий после успешной проверки клона.

- `ubuntu-2404-base`: `proxmox-iso`, autoinstall через `cidata`, статический адрес сборки.
- `ubuntu-2404-k8s`: `proxmox-clone` от base, containerd 2.x, Kubernetes 1.37.1 с `hold`, образы control plane.
- `tools/packer.sh`, `tools/find-template.sh`, `tools/verify-clone.sh`, `tools/prune-templates.sh`.
- goss, OpenSCAP CIS Ubuntu 24.04 L1 Server с tailoring, сводкой и Ansible-исправлениями, Trivy + SBOM.
- Схема Talos Image Factory.
- CI: `validate.yml`, `build.yml`, `scorecard.yml`.
- pre-commit, Renovate, SECURITY, MANUAL_STEPS.

### Changed
- Renovate: хуки pre-commit по SHA через regex-менеджер (исправлен ложный «апдейт» до v3.4.0); обновления раннеров `ubuntu-*` отключены.
- PAM без `nullok`; tailoring: `grub2_uefi_password`, `package_timesyncd_installed`, `service_chronyd_disabled`.

- Структура: `images/`, `scripts/{common,debian-family}`.
- Теги шаблонов: `packer;ubuntu-2404;<kind>;...;v<build>`.
- Проверка TLS Proxmox включена; версии Packer и плагинов закреплены.
- Доступ CI к Proxmox — WireGuard-сеть VDS ↔ pve ↔ раннер (`tools/ci-wireguard.sh`) вместо Cloudflare Tunnel.

### Removed

- `scripts/rhel-family/`.
- systemd-юнит удаления пользователя сборки.
