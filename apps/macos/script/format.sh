#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"
cd "$KAIWU_MACOS_ROOT"
case "${1:---check}" in
  --check) xcrun swift-format lint --strict --recursive --configuration .swift-format Package.swift Sources Tests Tools ;;
  --write) xcrun swift-format format --in-place --recursive --configuration .swift-format Package.swift Sources Tests Tools ;;
  *) echo "Usage: $0 [--check|--write]" >&2; exit 2 ;;
esac
