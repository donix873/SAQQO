#!/usr/bin/env bash
set -euo pipefail

project_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
if [ -n "${FLUTTER_ROOT:-}" ]; then
  flutter_root="$FLUTTER_ROOT"
elif command -v flutter >/dev/null 2>&1; then
  flutter_root=$(CDPATH= cd -- "$(dirname -- "$(command -v flutter)")/.." && pwd)
else
  echo "Flutter не найден. Установите Flutter stable и добавьте flutter в PATH." >&2
  exit 1
fi
export PATH="$flutter_root/bin:$PATH"
cache_root="${SAQGO_TOOL_CACHE:-$project_root/.tool-cache}"
export PUB_CACHE="${PUB_CACHE:-$cache_root/pub-cache}"
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-$cache_root/cache}"
export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$cache_root/config}"
mkdir -p "$PUB_CACHE" "$XDG_CACHE_HOME" "$XDG_CONFIG_HOME"

cd "$project_root"
flutter pub get --enforce-lockfile
flutter gen-l10n
flutter analyze
flutter test
