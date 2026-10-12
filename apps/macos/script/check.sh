#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"
case "${1:-}" in
  ""|--all) ;;
  *) echo "Usage: $0 [--all]" >&2; exit 2 ;;
esac
cd "$KAIWU_MACOS_ROOT"
./script/lint.sh
swift build --disable-sandbox
swift test --disable-sandbox
if [[ "${1:-}" == "--all" ]]; then
  xcodebuild -project Kaiwu.xcodeproj -scheme Kaiwu -configuration Debug \
    -destination 'platform=macOS' -derivedDataPath .build/xcode CODE_SIGNING_ALLOWED=NO build
fi
