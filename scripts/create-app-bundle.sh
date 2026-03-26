#!/bin/bash
set -euo pipefail

BINARY_PATH="$1"
VERSION="${2:-0.0.0}"
APP_NAME="StatusChecker"
BUNDLE_DIR="${APP_NAME}.app"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

# Clean any existing bundle
rm -rf "$BUNDLE_DIR"

# Create bundle structure
mkdir -p "$BUNDLE_DIR/Contents/MacOS"
mkdir -p "$BUNDLE_DIR/Contents/Resources"

# Copy binary
cp "$BINARY_PATH" "$BUNDLE_DIR/Contents/MacOS/$APP_NAME"
chmod +x "$BUNDLE_DIR/Contents/MacOS/$APP_NAME"

# Copy and patch Info.plist with version
sed "s/0\\.0\\.0/$VERSION/g" "$PROJECT_DIR/Resources/Info.plist" > "$BUNDLE_DIR/Contents/Info.plist"

# Ad-hoc codesign
codesign --force --deep -s - "$BUNDLE_DIR"

echo "Created $BUNDLE_DIR (version $VERSION)"
