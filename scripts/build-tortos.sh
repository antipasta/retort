#!/bin/sh
# Build tortos.elf and tortos-update for TrimUI Brick (ARM64) via Docker
set -e
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

echo "==> Building TortOS (ARM64 Brick)..."

# Pick up ScreenScraper credentials if .screenscraper.env exists
ENV_EXPORT=""
if [ -f "$ROOT/.screenscraper.env" ]; then
    echo "    Found .screenscraper.env (ScreenScraper credentials enabled)"
    ENV_EXPORT="export \$(grep -v '^#' .screenscraper.env | xargs);"
fi

docker run --rm -v "$ROOT":/build -w /build debian:bookworm-slim sh -c "
apt-get update -qq && apt-get install -y --no-install-recommends \
  build-essential libsdl2-dev libsdl2-image-dev libsdl2-ttf-dev \
  libsqlite3-dev libasound2-dev zlib1g-dev >/dev/null 2>&1
mkdir -p build-brick
$ENV_EXPORT
make -f mk/cross.mk CC=gcc SYSROOT= BUILD=build-brick DEVICE=brick VERSION=2.2.0 creds
make -f mk/cross.mk CC=gcc SYSROOT= BUILD=build-brick DEVICE=brick VERSION=2.2.0 build-brick/tortos.elf build-brick/tortos-update
"

# Stage to output directory if present
if [ -d "$ROOT/out/brick-neogeo-update/TortOS" ]; then
    cp "$ROOT/build-brick/tortos.elf" "$ROOT/out/brick-neogeo-update/TortOS/tortos.elf"
    echo "==> Staged tortos.elf -> out/brick-neogeo-update/TortOS/tortos.elf"
fi

ls -lh "$ROOT/build-brick/tortos.elf" "$ROOT/build-brick/tortos-update"
echo "==> TortOS build complete!"
