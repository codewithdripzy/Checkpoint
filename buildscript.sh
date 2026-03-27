#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
APP_DIR="$SCRIPT_DIR/app"

CLEAN_BUILD=false
SPLIT_PER_ABI=false

for arg in "$@"; do
  case "$arg" in
    --clean)
      CLEAN_BUILD=true
      ;;
    --split-per-abi)
      SPLIT_PER_ABI=true
      ;;
    -h|--help)
      cat <<'EOF'
Usage: ./buildscript.sh [options]

Options:
  --clean           Run flutter clean before building
  --split-per-abi   Build separate APKs per ABI
  -h, --help        Show this help message
EOF
      exit 0
      ;;
    *)
      echo "Unknown option: $arg"
      echo "Run ./buildscript.sh --help for usage"
      exit 1
      ;;
  esac
done

if [[ ! -d "$APP_DIR" ]]; then
  echo "Error: Flutter app directory not found at $APP_DIR"
  exit 1
fi

if ! command -v flutter >/dev/null 2>&1; then
  echo "Error: flutter is not installed or not in PATH"
  exit 1
fi

cd "$APP_DIR"

echo "Using Flutter: $(flutter --version | head -n 1)"
echo "Working directory: $APP_DIR"

if [[ "$CLEAN_BUILD" == true ]]; then
  echo "Running flutter clean..."
  flutter clean
fi

echo "Fetching dependencies..."
flutter pub get

echo "Building release APK..."
BUILD_ARGS=(apk --release)
if [[ "$SPLIT_PER_ABI" == true ]]; then
  BUILD_ARGS+=(--split-per-abi)
fi

flutter build "${BUILD_ARGS[@]}"

echo "Build complete"
if [[ "$SPLIT_PER_ABI" == true ]]; then
  echo "APK files are in app/build/app/outputs/flutter-apk/"
else
  echo "APK file is in app/build/app/outputs/flutter-apk/app-release.apk"
fi
