#!/bin/sh
# Update the Plastron OS boot splash directly on the microSD card from macOS
set -e

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
FRAMES="$ROOT/res/boot/frames-brick.bin"

if [ ! -f "$FRAMES" ]; then
    echo "[-] Error: $FRAMES not found. Run python3 tools/genboot.py first." >&2
    exit 1
fi

echo "==> Looking for TrimUI Brick microSD card..."

# Find disk that contains TORTOS volume
SD_DISK=""
if [ -d "/Volumes/TORTOS" ]; then
    PARENT="$(diskutil info /Volumes/TORTOS 2>/dev/null | grep "Part of Whole" | awk '{print $4}')"
    if [ -n "$PARENT" ]; then
        SD_DISK="/dev/$PARENT"
    fi
fi

if [ -z "$SD_DISK" ]; then
    echo ""
    echo "[-] MicroSD card not detected in /Volumes/TORTOS."
    echo "    Please insert your TrimUI Brick microSD card into your laptop."
    echo ""
    echo "Available external disks:"
    diskutil list external
    echo ""
    echo "Once inserted, run: $0"
    exit 1
fi

echo "    [+] Found SD card at $SD_DISK"

# Find plastron-root partition (usually partition 2)
ROOT_PART="$(diskutil list "$SD_DISK" | grep -i "plastron-root" | awk '{print $NF}')"
if [ -z "$ROOT_PART" ]; then
    # Fallback to partition 2
    ROOT_PART="${PARENT}s2"
fi

DEV_PART="/dev/$ROOT_PART"
RDEV_PART="/dev/r$ROOT_PART"
echo "    [+] Target root partition: $DEV_PART ($RDEV_PART)"

SUDO=""
if [ "$(id -u)" -ne 0 ]; then
    SUDO="sudo"
fi

mkdir -p "$ROOT/build/splash-update"
TMP_DIR="$ROOT/build/splash-update"

echo "==> Reading rootfs partition from SD card (may prompt for sudo password)..."
diskutil unmount "$DEV_PART" 2>/dev/null || true
$SUDO dd if="$RDEV_PART" of="$TMP_DIR/rootfs.squashfs" bs=1m count=256 status=progress
$SUDO chmod 644 "$TMP_DIR/rootfs.squashfs" 2>/dev/null || true

echo "==> Updating /usr/share/splash/frames.bin inside rootfs..."
docker run --rm -v "$TMP_DIR":/work -v "$ROOT":/repo -w /work debian:bookworm-slim sh -c "
  apt-get update -qq && apt-get install -y --no-install-recommends squashfs-tools >/dev/null 2>&1
  rm -rf rootfs
  unsquashfs -d rootfs rootfs.squashfs >/dev/null
  cp /repo/res/boot/frames-brick.bin rootfs/usr/share/splash/frames.bin
  rm -f rootfs-new.squashfs
  mksquashfs rootfs rootfs-new.squashfs -comp lz4 -b 256k -noappend >/dev/null
"

if [ ! -f "$TMP_DIR/rootfs-new.squashfs" ]; then
    echo "[-] Error: Failed to generate updated rootfs." >&2
    exit 1
fi

NEW_SIZE="$(stat -f%z "$TMP_DIR/rootfs-new.squashfs")"
echo "    [+] Successfully rebuilt rootfs ($NEW_SIZE bytes)"

echo "==> Writing updated rootfs back to SD card..."
diskutil unmount "$DEV_PART" 2>/dev/null || true
$SUDO dd if="$TMP_DIR/rootfs-new.squashfs" of="$RDEV_PART" bs=1m status=progress

echo "==> Syncing..."
sync

echo ""
echo "=========================================================="
echo " [SUCCESS] Boot splash permanently updated on SD card!"
echo " Eject the SD card, insert it into your Brick, and power on."
echo "=========================================================="
