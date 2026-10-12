#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"
cd "$KAIWU_MACOS_ROOT"
./script/format.sh --check
mkdir -p .build/checks
swift package --disable-sandbox dump-package > .build/checks/package.json
swift run --disable-sandbox repository-check "$KAIWU_ROOT" "$KAIWU_MACOS_ROOT/.build/checks/package.json"
plutil -lint Configuration/Info.plist Configuration/Kaiwu.entitlements Kaiwu.xcodeproj/project.pbxproj
for file in "$KAIWU_ROOT"/script/*.sh script/*.sh; do bash -n "$file"; done
if ! git diff --check; then exit 1; fi
echo "静态检查通过。"
