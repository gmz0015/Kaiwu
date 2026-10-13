#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

SOURCE_DIR="$KAIWU_MACOS_ROOT/Resources/IconSources"
ASSET_DIR="$KAIWU_MACOS_ROOT/Sources/KaiwuApp/Resources/Assets.xcassets"
ICON_DIR="$ASSET_DIR/$(app_setting ASSETCATALOG_COMPILER_APPICON_NAME).appiconset"
MENU_DIR="$ASSET_DIR/MenuBarIcon.imageset"
mkdir -p "$ICON_DIR" "$MENU_DIR" "$KAIWU_MACOS_ROOT/.build"
TEMP_DIR="$(mktemp -d "$KAIWU_MACOS_ROOT/.build/icons.XXXXXX")"
trap 'rm -rf "$TEMP_DIR"' EXIT

# 原图四周含透明留白；中心裁剪保留完整图形，使底板约占画布的 80%。
sips --cropToHeightWidth 1536 1536 "$SOURCE_DIR/AppIcon.png" --out "$TEMP_DIR/AppIcon.png" >/dev/null
printf '{"info":{"author":"xcode","version":1}}\n' > "$ASSET_DIR/Contents.json"
{
  printf '{"images":[\n'
  SEPARATOR=""
  for SIZE in 16 32 128 256 512; do
    for SCALE in 1 2; do
      PIXELS=$((SIZE * SCALE))
      FILE="icon_${SIZE}x${SIZE}@${SCALE}x.png"
      sips --resampleHeightWidth "$PIXELS" "$PIXELS" "$TEMP_DIR/AppIcon.png" --out "$ICON_DIR/$FILE" >/dev/null
      printf '%s{"filename":"%s","idiom":"mac","size":"%sx%s","scale":"%sx"}' "$SEPARATOR" "$FILE" "$SIZE" "$SIZE" "$SCALE"
      SEPARATOR=$',\n'
    done
  done
  printf '\n],"info":{"author":"xcode","version":1}}\n'
} > "$ICON_DIR/Contents.json"

{
  printf '{"images":[\n'
  SEPARATOR=""
  for APPEARANCE in Light Dark; do
    for SCALE in 1 2; do
      FILE="menu_${APPEARANCE}@${SCALE}x.png"
      sips --resampleHeightWidth "$((18 * SCALE))" "$((19 * SCALE))" "$SOURCE_DIR/MenuBar$APPEARANCE.png" --out "$MENU_DIR/$FILE" >/dev/null
      printf '%s{"filename":"%s","idiom":"mac","scale":"%sx"' "$SEPARATOR" "$FILE" "$SCALE"
      if [[ "$APPEARANCE" == "Dark" ]]; then
        printf ',"appearances":[{"appearance":"luminosity","value":"dark"}]'
      fi
      printf '}'
      SEPARATOR=$',\n'
    done
  done
  printf '\n],"info":{"author":"xcode","version":1},"properties":{"template-rendering-intent":"template"}}\n'
} > "$MENU_DIR/Contents.json"
echo "图标资源已生成。"
