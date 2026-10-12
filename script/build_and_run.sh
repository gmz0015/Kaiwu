#!/usr/bin/env bash
set -euo pipefail

MODE="${1:-run}"
case "$MODE" in
  run|--debug|--logs|--telemetry|--verify|--build-only) ;;
  *) echo "Usage: $0 [--debug|--logs|--telemetry|--verify|--build-only]" >&2; exit 2 ;;
esac
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"
APP_NAME="$(app_setting PRODUCT_NAME)"
APP_DISPLAY_NAME="$(app_setting APP_DISPLAY_NAME)"
BUNDLE_ID="$(app_setting PRODUCT_BUNDLE_IDENTIFIER)"
APP_VERSION="$(app_setting MARKETING_VERSION)"
BUILD_VERSION="$(app_setting CURRENT_PROJECT_VERSION)"
MIN_SYSTEM_VERSION="$(app_setting MACOSX_DEPLOYMENT_TARGET)"
APP_BUNDLE="$KAIWU_ROOT/dist/$APP_NAME.app"
cd "$KAIWU_ROOT"

if [[ "$MODE" != "--build-only" ]]; then
  pkill -x "$APP_NAME" >/dev/null 2>&1 || true
fi
swift build --disable-sandbox --product "$APP_NAME"
BUILD_BINARY="$(swift build --disable-sandbox --show-bin-path)/$APP_NAME"
# 先签名完整的新包，再替换开发产物，避免原地改写正在运行的可执行文件。
STAGING_DIR="$(mktemp -d "$KAIWU_ROOT/.build/app-bundle.XXXXXX")"
STAGED_APP="$STAGING_DIR/$APP_NAME.app"
trap 'rm -rf "$STAGING_DIR"' EXIT
mkdir -p "$STAGED_APP/Contents/MacOS"
cp "$BUILD_BINARY" "$STAGED_APP/Contents/MacOS/$APP_NAME"
cp "$KAIWU_ROOT/Configuration/Info.plist" "$STAGED_APP/Contents/Info.plist"
/usr/libexec/PlistBuddy -c "Set :CFBundleExecutable $APP_NAME" "$STAGED_APP/Contents/Info.plist"
/usr/libexec/PlistBuddy -c "Set :CFBundleName $APP_DISPLAY_NAME" "$STAGED_APP/Contents/Info.plist"
/usr/libexec/PlistBuddy -c "Set :CFBundleDisplayName $APP_DISPLAY_NAME" "$STAGED_APP/Contents/Info.plist"
/usr/libexec/PlistBuddy -c "Set :CFBundleIdentifier $BUNDLE_ID" "$STAGED_APP/Contents/Info.plist"
/usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString $APP_VERSION" "$STAGED_APP/Contents/Info.plist"
/usr/libexec/PlistBuddy -c "Set :CFBundleVersion $BUILD_VERSION" "$STAGED_APP/Contents/Info.plist"
/usr/libexec/PlistBuddy -c "Set :LSMinimumSystemVersion $MIN_SYSTEM_VERSION" "$STAGED_APP/Contents/Info.plist"
/usr/bin/codesign --force --sign - "$STAGED_APP"
mkdir -p "$KAIWU_ROOT/dist"
if [[ -e "$APP_BUNDLE" ]]; then mv "$APP_BUNDLE" "$STAGING_DIR/previous.app"; fi
if ! mv "$STAGED_APP" "$APP_BUNDLE"; then
  if [[ -e "$STAGING_DIR/previous.app" ]]; then mv "$STAGING_DIR/previous.app" "$APP_BUNDLE"; fi
  exit 1
fi

case "$MODE" in
  --build-only) echo "Built: $APP_BUNDLE" ;;
  --debug) lldb -- "$APP_BUNDLE/Contents/MacOS/$APP_NAME" ;;
  --logs)
    /usr/bin/open -n "$APP_BUNDLE"
    /usr/bin/log stream --info --style compact --predicate "process == \"$APP_NAME\""
    ;;
  --telemetry)
    /usr/bin/open -n "$APP_BUNDLE"
    /usr/bin/log stream --info --style compact --predicate "subsystem == \"$BUNDLE_ID\""
    ;;
  --verify)
    /usr/bin/open -n "$APP_BUNDLE"
    sleep 2
    pgrep -x "$APP_NAME" >/dev/null
    echo "Launched: $APP_NAME"
    ;;
  run) /usr/bin/open -n "$APP_BUNDLE" ;;
esac
