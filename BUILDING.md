# Building ReTort / TortOS

Instructions for building ReTort and Diatom for the TrimUI Brick (Plastron Linux).

---

## 1. Quick Build (Using `build.sh`)

The repository includes a master build automation script [build.sh](build.sh) that orchestrates Docker cross-compilation and SD card deployment:

```sh
# Run all native unit tests
./build.sh check

# Fetch and verify all libretro cores (stock + extended)
./build.sh cores

# Cross-compile both tortos.elf and diatom for TrimUI Brick (ARM64)
./build.sh all

# Install staged binaries and shaders to microSD card (auto-detects /Volumes/TORTOS)
./build.sh install

# Update the boot splash animation on the SD card (Plastron OS partition)
./build.sh splash
```

---

## 2. Manual Cross-Compilation via Docker

If you prefer to invoke the cross-compiler directly:

### Build the Launcher (`tortos.elf`)

Run from the root of the repository:

```sh
docker run --rm -v $(pwd):/build -w /build debian:bookworm-slim sh -c \
  "apt-get update && apt-get install -y --no-install-recommends \
   build-essential libsdl2-dev libsdl2-image-dev libsdl2-ttf-dev libsqlite3-dev \
   libasound2-dev zlib1g-dev pkg-config && \
   make -f mk/cross.mk CC=gcc SYSROOT='' BUILD=build-brick DEVICE=brick VERSION=2.2.1 build-brick/tortos.elf"
```
*Output binary: `build-brick/tortos.elf`.*

---

### Build the Emulator Engine (`diatom`)

From the companion `diatom` repository:

```sh
cd ../diatom

docker run --rm -v $(pwd):/build -w /build debian:bookworm-slim sh -c \
  "apt-get update && apt-get install -y --no-install-recommends \
   build-essential libsdl2-dev zlib1g-dev pkg-config && \
   make PORT=brick"
```
*Output binary: `build/brick/diatom`.*

---

## 3. Manual Deployment to MicroSD Card (`/Volumes/TORTOS`)

Once compiled, copy the binaries and shaders to your SD card:

```sh
# 1. Copy the updated launcher
cp build-brick/tortos.elf /Volumes/TORTOS/TortOS/tortos.elf

# 2. Copy the updated diatom engine
cp ../diatom/build/brick/diatom /Volumes/TORTOS/TortOS/diatom

# 3. Ensure the shaders directory is copied
cp -r res/shaders /Volumes/TORTOS/TortOS/
```

---

## 4. Run Native Tests Locally

To verify all launcher logic, menus, and shader parsers pass locally on your host machine:

```sh
make check
```
