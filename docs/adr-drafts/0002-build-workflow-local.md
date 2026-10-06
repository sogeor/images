# ADR (черновик): build.yml до появления reusable workflow

- Статус: предложено
- Дата: 2026-10-07

## Контекст

Сборка должна вызывать `actions-workflows/.github/workflows/packer-build.yml` по тегу. Репозитория ещё нет.

## Решение

`build.yml` и `validate.yml` описаны в `packer-images`. Логика — в `tools/packer.sh` и `tools/verify-clone.sh`.

## Последствия

После появления `packer-build.yml` заменить `build.yml` вызовом
`uses: sogeor/actions-workflows/.github/workflows/packer-build.yml@<sha> # vX.Y.Z`.
