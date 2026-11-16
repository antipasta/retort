#!/bin/sh
# Build diatom emulator engine for TrimUI Brick (ARM64) via Docker
set -e
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DIATOM_DIR="${1:-$(cd "$ROOT/../diatom" 2>/dev/null && pwd)}"

if [ -z "$DIATOM_DIR" ] || [ ! -f "$DIATOM_DIR/Makefile" ]; then
    echo "Error: diatom repository not found at '$DIATOM_DIR'. Pass path as \$1." >&2
    exit 1
fi

echo "==> Building Diatom (ARM64 Brick) from $DIATOM_DIR..."

docker run --rm -v "$DIATOM_DIR":/build -w /build debian:bookworm-slim sh -c "
apt-get update -qq && apt-get install -y --no-install-recommends \
  build-essential libsdl2-dev zlib1g-dev pkg-config >/dev/null 2>&1
make clean >/dev/null 2>&1 || true
make PORT=brick -j\$(nproc)
"

# Stage to TortOS output directory if present
if [ -d "$ROOT/out/brick-neogeo-update/TortOS" ]; then
    cp "$DIATOM_DIR/build/brick/diatom" "$ROOT/out/brick-neogeo-update/TortOS/diatom"
    echo "==> Staged diatom -> out/brick-neogeo-update/TortOS/diatom"
fi

ls -lh "$DIATOM_DIR/build/brick/diatom"
echo "==> Diatom build complete!"
