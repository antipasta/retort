#!/bin/sh
# Populate vendor/cores with the extended libretro cores ReTort supports:
# FBNeo (Neo Geo arcade / AES) and PCSX-ReARMed (PlayStation 1).
#
# Like mk/fetch-vendor.sh, cores are hash-pinned by sha256. They are retrieved
# from plorpOS's v1.9 release archive, where both cores were built against
# the TrimUI Brick's specific glibc 2.33 / Debian Bullseye toolchain with
# required handheld flags (-DHAVE_PHYSICAL_CDROM=0, rotation patches, and
# input safety patches).
#
# If the cores already exist in vendor/cores and match their pinned sha256,
# this script exits immediately without network access.
#
# Usage: mk/fetch-vendor-extended.sh [cache-dir]
set -e
ROOT=$(cd "$(dirname "$0")/.." && pwd)
VENDOR=$ROOT/vendor/cores
STAGE=$ROOT/out/brick-neogeo-update/TortOS/cores
DL=${1:-/tmp/tortos-vendor-extended}
ZIP_URL="https://github.com/thwonp/plorpOS/releases/download/plorpos-v1.9/plorpOS-v1.9-brick.zip"
ZIP_FILE="$DL/plorpOS-v1.9-brick.zip"

command -v curl   > /dev/null || { echo "need curl" >&2; exit 1; }
command -v shasum > /dev/null || { echo "need shasum" >&2; exit 1; }
command -v unzip  > /dev/null || { echo "need unzip" >&2; exit 1; }

mkdir -p "$DL" "$VENDOR"

# Pinned SHA-256 checksums
SHA_FBNEO="082059ba970ff2c2d0bc263ae807d1539d06fed25ff7e4e0b6efba5c3eb4f4c9"
SHA_PCSX="ab7b64874432fc771d7a6c61b5a8e29e22814f05e85b1854c8d30ec2f6aa6671"

needs_download() {
	f=${1}_libretro.so
	sha=$2
	if [ -f "$VENDOR/$f" ] &&
	   [ "$(shasum -a 256 "$VENDOR/$f" | cut -d' ' -f1)" = "$sha" ]; then
		return 1
	fi
	return 0
}

# 1. Check if both cores already exist and match hashes
if ! needs_download fbneo "$SHA_FBNEO" && ! needs_download pcsx_rearmed "$SHA_PCSX"; then
	echo "  ok      fbneo"
	echo "  ok      pcsx_rearmed"
	# Also ensure staging directory has them if staging exists
	if [ -d "$STAGE" ]; then
		cp -n "$VENDOR/fbneo_libretro.so" "$STAGE/" 2>/dev/null || true
		cp -n "$VENDOR/pcsx_rearmed_libretro.so" "$STAGE/" 2>/dev/null || true
	fi
	exit 0
fi

# 2. Download release zip if needed
if [ ! -f "$ZIP_FILE" ]; then
	echo "==> Downloading extended cores package (plorpOS v1.9)..."
	curl -sSfL -o "$ZIP_FILE" "$ZIP_URL"
fi

extract_core() { # name sha256 zip_path
	name=$1
	f=${name}_libretro.so
	want_sha=$2
	zip_path=$3

	if ! needs_download "$name" "$want_sha"; then
		echo "  ok      $name"
		return
	fi

	echo "==> Extracting $f from $zip_path..."
	unzip -p "$ZIP_FILE" "$zip_path" > "$DL/$f"
	got_sha=$(shasum -a 256 "$DL/$f" | cut -d' ' -f1)

	if [ "$got_sha" != "$want_sha" ]; then
		rm -f "$DL/$f"
		echo "  MISMATCH $name" >&2
		echo "    want $want_sha" >&2
		echo "    got  $got_sha" >&2
		echo "  Extended core binary does not match pinned checksum!" >&2
		exit 1
	fi

	mv "$DL/$f" "$VENDOR/$f"
	if [ -d "$STAGE" ]; then
		cp "$VENDOR/$f" "$STAGE/$f"
	fi
	echo "  fetched $name"
}

extract_core fbneo "$SHA_FBNEO" "TortOS/cores/fbneo_libretro.so"
extract_core pcsx_rearmed "$SHA_PCSX" "TortOS/cores/pcsx_rearmed_libretro.so"

echo "vendor/cores extended ready:"
ls -lh "$VENDOR/fbneo_libretro.so" "$VENDOR/pcsx_rearmed_libretro.so"
