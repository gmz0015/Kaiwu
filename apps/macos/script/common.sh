#!/usr/bin/env bash
# 公共构建环境；仅由项目脚本 source，不修改用户全局配置。
KAIWU_MACOS_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
KAIWU_ROOT="$(cd "$KAIWU_MACOS_ROOT/../.." && pwd)"
export CLANG_MODULE_CACHE_PATH="$KAIWU_MACOS_ROOT/.build/ModuleCache"
export SWIFTPM_MODULECACHE_OVERRIDE="$CLANG_MODULE_CACHE_PATH"

app_setting() {
  local key="$1"
  local value
  local pattern='^[A-Za-z0-9.-]+$'
  if [[ "$key" == "APP_DISPLAY_NAME" ]]; then pattern='^[[:alnum:] .-]+$'; fi
  value="$(awk -F ' = ' -v key="$key" '$1 == key { print $2 }' "$KAIWU_MACOS_ROOT/Configuration/App.xcconfig")"
  if [[ -z "$value" || "$value" == *$'\n'* || ! "$value" =~ $pattern ]]; then
    echo "无效或重复的 App.xcconfig 配置：$key" >&2
    return 1
  fi
  printf '%s\n' "$value"
}
