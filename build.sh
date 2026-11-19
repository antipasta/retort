#!/bin/sh
# Master build script for Retort / TortOS
set -e
ROOT="$(cd "$(dirname "$0")" && pwd)"

usage() {
    echo "Usage: $0 [target]"
    echo ""
    echo "Targets:"
    echo "  all      - Build both tortos.elf and diatom, and stage binaries (default)"
    echo "  tortos   - Build tortos.elf and tortos-update (ARM64 Brick)"
    echo "  diatom   - Build diatom (ARM64 Brick with shader support)"
    echo "  check    - Run all native host unit test suites (make check)"
    echo "  install  - Install staged binaries to SD card (auto-detects /Volumes/TORTOS)"
    echo "  splash   - Update boot splash partition on SD card from laptop"
    echo "  cores    - Fetch and verify all libretro cores (stock + extended)"
    echo ""
}

TARGET="${1:-all}"

case "$TARGET" in
    all)
        "$ROOT/scripts/build-all.sh"
        ;;
    tortos)
        "$ROOT/scripts/build-tortos.sh"
        ;;
    diatom)
        "$ROOT/scripts/build-diatom.sh"
        ;;
    check)
        make -C "$ROOT" check
        ;;
    install)
        shift || true
        "$ROOT/scripts/install-sd.sh" "$@"
        ;;
    splash)
        "$ROOT/scripts/update-boot-splash-sd.sh"
        ;;
    cores)
        "$ROOT/mk/fetch-vendor.sh"
        "$ROOT/mk/fetch-vendor-extended.sh"
        ;;
    help|-h|--help)
        usage
        ;;
    *)
        echo "Unknown target: $TARGET"
        usage
        exit 1
        ;;
esac
