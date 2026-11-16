#!/bin/sh
# Build both TortOS and Diatom for TrimUI Brick and stage for deployment
set -e
ROOT="$(cd "$(dirname "$0")/.." && pwd)"

echo "========================================="
echo "Building Full Retort / TortOS Stack"
echo "========================================="

"$ROOT/scripts/build-tortos.sh"
echo ""
"$ROOT/scripts/build-diatom.sh"

echo ""
echo "========================================="
echo "Build Summary:"
echo "========================================="
if [ -d "$ROOT/out/brick-neogeo-update/TortOS" ]; then
    ls -lh "$ROOT/out/brick-neogeo-update/TortOS/tortos.elf" "$ROOT/out/brick-neogeo-update/TortOS/diatom"
fi
echo "Ready for deployment to SD card."
