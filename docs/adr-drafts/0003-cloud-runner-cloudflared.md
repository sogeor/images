# ADR (черновик): сборка образов на облачном раннере через Cloudflare Tunnel

- Статус: предложено
- Дата: 2026-10-07

## Контекст

Cloudflare Zero Trust (Access, WARP, service tokens) недоступен. Self-hosted раннера `ops` нет.
Packer нужны API Proxmox и SSH к ВМ сборки в `192.168.100.0/24`.

## Решение

- Сборка — `ubuntu-24.04` (GitHub-hosted), Environment `images`, только из `master`.
- API — `pve.bloogefest.com` (Tunnel → `192.168.100.10:8006`), авторизация API-токеном `packer@pve!ci`.
- SSH — `packer-ssh.bloogefest.com` (Tunnel → `ssh://192.168.100.250:22`), на раннере `cloudflared access tcp`.
- Все ВМ сборки и проверки используют `192.168.100.250`; job-ы последовательны (`concurrency`, `max-parallel: 1`).

## Последствия

- Из интернета доступен только API Proxmox по токену (правила Tunnel по пути); `access/ticket` и веб-интерфейс закрыты.
- WAF и rate limiting Cloudflare недоступны (нет карты): защита — минимальные роли токена и закрытый вход по паролю.
- SSH-порт `.250` достижим из интернета, пока работает ВМ сборки; вход только по одноразовому ключу.
- Параллельная сборка образов невозможна.
- После появления Headscale (`edge`) — перевести доступ на Tailscale и закрыть public hostnames.

## Альтернативы

- Self-hosted раннер на `ops` (исходный план): нет публикации, но нужна постоянная ВМ.
- WARP + private network: требует Zero Trust.
