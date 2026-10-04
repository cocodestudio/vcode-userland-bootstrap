#!/usr/bin/env bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

ARCH="$1"
if [ -z "$ARCH" ]; then
    echo "Usage: $0 <aarch64|arm|x86_64|i686>"
    exit 1
fi

echo "=========================================================="
echo " Building Real VCode Bootstrap Archive"
echo " Architecture: $ARCH"
echo " Package ID:    com.cocode.vcode.ide"
echo "=========================================================="

OUTPUT_DIR="$REPO_ROOT/output"
mkdir -p "$OUTPUT_DIR"

cd "$REPO_ROOT"
chmod +x "$SCRIPT_DIR"/generate-bootstraps.sh

# Run generate-bootstraps.sh for target arch
"$SCRIPT_DIR"/generate-bootstraps.sh --architectures "$ARCH"

# Move archives to output
if [ -f "bootstrap-${ARCH}.tar.gz" ]; then
    mv -f "bootstrap-${ARCH}.tar.gz" "$OUTPUT_DIR/"
    mv -f "bootstrap-${ARCH}.tar.gz.sha256" "$OUTPUT_DIR/"
fi
if [ -f "bootstrap-${ARCH}.zip" ]; then
    mv -f "bootstrap-${ARCH}.zip" "$OUTPUT_DIR/"
fi

echo "=========================================================="
echo " Bootstrap build completed for $ARCH"
ls -lh "$OUTPUT_DIR"
echo "=========================================================="
