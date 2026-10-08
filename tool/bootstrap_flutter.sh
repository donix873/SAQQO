#!/usr/bin/env bash
set -euo pipefail

project_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
if [ -n "${FLUTTER_ROOT:-}" ]; then
  flutter_root="$FLUTTER_ROOT"
elif command -v flutter >/dev/null 2>&1; then
  flutter_root=$(CDPATH= cd -- "$(dirname -- "$(command -v flutter)")/.." && pwd)
elif [ -x /workspace/.flutter-sdk/bin/flutter ]; then
  flutter_root=/workspace/.flutter-sdk
else
  echo "Flutter не найден. Установите Flutter stable и добавьте flutter в PATH." >&2
  exit 1
fi
export PATH="$flutter_root/bin:$PATH"
export PUB_CACHE="${PUB_CACHE:-/workspace/.pub-cache}"
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-/workspace/.cache}"
export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-/workspace/.config}"
mkdir -p "$PUB_CACHE" "$XDG_CACHE_HOME" "$XDG_CONFIG_HOME"

cd "$project_root"
flutter create --platforms=android,ios --org kz.saqgo --project-name saqgo .
flutter pub get
dart run tool/configure_platforms.dart
dart run flutter_launcher_icons
dart run flutter_native_splash:create
flutter gen-l10n
flutter analyze
flutter test
