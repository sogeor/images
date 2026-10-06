#!/usr/bin/env bash
set -euo pipefail

: "${BUILD_USER:?}"

rm -f /etc/sudoers.d/90-cloud-init-users
userdel -f -r "$BUILD_USER" 2>/dev/null || userdel -f "$BUILD_USER"
rm -f "$0"
sync
