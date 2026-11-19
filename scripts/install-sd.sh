#!/bin/sh
# Copy staged binaries to a mounted microSD card
set -e
ROOT="$(cd "$(dirname "$0")/.." && pwd)"

TARGET="${1:-}"
if [ -z "$TARGET" ]; then
    # Auto-detect if /Volumes/TORTOS exists
    if [ -d "/Volumes/TORTOS/TortOS" ]; then
        TARGET="/Volumes/TORTOS"
    else
        echo "Usage: $0 /Volumes/<SD_CARD_NAME>"
        echo "Mounted volumes:"
        ls -1 /Volumes/ 2>/dev/null || true
        exit 1
    fi
fi

SD_TORTOS="$TARGET/TortOS"
if [ ! -d "$SD_TORTOS" ]; then
    echo "Error: Directory '$SD_TORTOS' does not exist." >&2
    exit 1
fi

STAGE="$ROOT/out/brick-neogeo-update/TortOS"
echo "==> Installing to $SD_TORTOS..."

if [ -f "$STAGE/tortos.elf" ]; then
    cp "$STAGE/tortos.elf" "$SD_TORTOS/tortos.elf"
    echo "    [+] Installed tortos.elf"
fi

if [ -f "$STAGE/diatom" ]; then
    cp "$STAGE/diatom" "$SD_TORTOS/diatom"
    echo "    [+] Installed diatom"
fi

if [ -d "$ROOT/res/shaders" ]; then
    mkdir -p "$SD_TORTOS/shaders"
    cp -R "$ROOT/res/shaders/"* "$SD_TORTOS/shaders/"
    echo "    [+] Installed shaders"
fi

if [ -d "$STAGE/cores" ]; then
    mkdir -p "$SD_TORTOS/cores"
    cp -n "$STAGE/cores/"*.so "$SD_TORTOS/cores/" 2>/dev/null || true
    echo "    [+] Verified cores in $SD_TORTOS/cores"
fi

sync
echo "==> Done! Safely eject your SD card."
