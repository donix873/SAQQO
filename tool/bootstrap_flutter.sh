#!/usr/bin/env bash
set -euo pipefail

project_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
flutter_root=${FLUTTER_ROOT:-/workspace/.flutter-sdk}
export PATH="$flutter_root/bin:$PATH"

cd "$project_root"
flutter create --platforms=android,ios --org kz.saqgo --project-name saqgo .
dart run tool/configure_platforms.dart
flutter pub get
dart run flutter_launcher_icons
dart run flutter_native_splash:create
flutter gen-l10n
flutter analyze
flutter test
