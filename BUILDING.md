Here are the build instructions for cross-compiling the binaries for your TrimUI Brick (running Plastron Linux) using Docker.

---

### 1. Build the TortOS Launcher (`tortos.elf`)

Run this from the `/Users/joe/misc/TortOS` repository:

```sh
cd /Users/joe/misc/TortOS

docker run --rm -v $(pwd):/build -w /build debian:bookworm-slim sh -c \
  "apt-get update && apt-get install -y --no-install-recommends \
   build-essential libsdl2-dev libsdl2-image-dev libsdl2-ttf-dev libsqlite3-dev \
   libasound2-dev zlib1g-dev pkg-config && \
   make -f mk/cross.mk CC=gcc SYSROOT='' BUILD=build-brick DEVICE=brick VERSION=2.2.1 build-brick/tortos.elf"
```
*Output binary will be located at: `build-brick/tortos.elf`.*

---

### 2. Build the Diatom Emulator Engine (`diatom`)

If you also need to recompile `diatom` for the TrimUI Brick:

```sh
cd /Users/joe/misc/diatom

docker run --rm -v $(pwd):/build -w /build debian:bookworm-slim sh -c \
  "apt-get update && apt-get install -y --no-install-recommends \
   build-essential libsdl2-dev zlib1g-dev pkg-config && \
   make PORT=brick"
```
*Output binary will be located at: `build/brick/diatom`.*

---

### 3. Deploy to the SD Card (`/Volumes/TORTOS`)

Once compiled, copy the binaries and shaders to your SD card:

```sh
# 1. Copy the updated launcher
cp /Users/joe/misc/TortOS/build-brick/tortos.elf /Volumes/TORTOS/TortOS/tortos.elf

# 2. Copy the updated diatom engine
cp /Users/joe/misc/diatom/build/brick/diatom /Volumes/TORTOS/TortOS/diatom

# 3. Ensure the shaders directory is copied
cp -r /Users/joe/misc/TortOS/res/shaders /Volumes/TORTOS/TortOS/
```

---

### Optional: Run Native Tests Locally

To verify all launcher logic, menus, and shader parsers pass locally before deploying:

```sh
cd /Users/joe/misc/TortOS
make check
```
