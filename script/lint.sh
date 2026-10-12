#!/usr/bin/env bash
set -euo pipefail
# 仓库入口；具体实现由 macOS 平台维护。
exec "$(cd "$(dirname "${BASH_SOURCE[0]}")/../apps/macos/script" && pwd)/lint.sh" "$@"
