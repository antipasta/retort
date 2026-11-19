#!/usr/bin/env python3
"""Generate Option A (Dark Background) boot splash animation for ReTort.

Inverts the user's custom boot video (tortos-fly.mp4) onto the TortOS dark
background (#111310 / RGB 17, 19, 16) with retro mint/cyan phosphor lines.
Outputs:
  1. res/boot/tortos-fly.mp4  (1024x768 @ 60 fps, H.264)
  2. res/boot/frames-brick.bin (Plastron TSPZ delta-frame binary)

Usage:
  python3 tools/make_boot_splash.py [--fg R,G,B or #HEX]
"""

import argparse
import os
import struct
import subprocess
import sys
import zlib
from PIL import Image

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SRC_VIDEO = os.path.join(ROOT, "tortos-fly.mp4")
OUT_VIDEO = os.path.join(ROOT, "res", "boot", "tortos-fly.mp4")
OUT_BIN   = os.path.join(ROOT, "res", "boot", "frames-brick.bin")

# TortOS dark background (#111310)
BG = (17, 19, 16)
# Default foreground: Retro Mint Green (#80DCAA)
DEFAULT_FG = (128, 220, 170)

W, H = 1024, 768
FPS = 60


def parse_color(c_str):
    if c_str.startswith("#"):
        c_str = c_str.lstrip("#")
        return tuple(int(c_str[i:i+2], 16) for i in (0, 2, 4))
    if "," in c_str:
        return tuple(int(x.strip()) for x in c_str.split(","))
    raise ValueError(f"Unknown color format: {c_str}")


def build_lut(bg, fg):
    lut_r, lut_g, lut_b = [], [], []
    for g in range(256):
        if g >= 215:
            lut_r.append(bg[0])
            lut_g.append(bg[1])
            lut_b.append(bg[2])
        elif g <= 25:
            lut_r.append(fg[0])
            lut_g.append(fg[1])
            lut_b.append(fg[2])
        else:
            t = (g - 25.0) / (215.0 - 25.0)
            lut_r.append(int(round((1.0 - t) * fg[0] + t * bg[0])))
            lut_g.append(int(round((1.0 - t) * fg[1] + t * bg[1])))
            lut_b.append(int(round((1.0 - t) * fg[2] + t * bg[2])))
    return lut_r, lut_g, lut_b


def sub_filter(band, stride):
    """PNG Sub filter: each byte minus the same byte one pixel to the left."""
    out = bytearray(band)
    for start in range(0, len(band), stride):
        row = band[start:start + stride]
        for i in range(4, stride):
            out[start + i] = (row[i] - row[i - 4]) & 0xff
    return bytes(out)


def encode_tspz(frames_bgr, out_path, w=W, h=H, fps=FPS):
    stride = w * 4
    encoded = []
    for n, f in enumerate(frames_bgr):
        if n == 0:
            first, rows = 0, h
        else:
            prev = frames_bgr[n - 1]
            changed = [y for y in range(h)
                       if f[y * stride:(y + 1) * stride] != prev[y * stride:(y + 1) * stride]]
            first, rows = (changed[0], changed[-1] - changed[0] + 1) if changed else (0, 0)
        band = bytes(f[first * stride:(first + rows) * stride])
        data = zlib.compress(sub_filter(band, stride), 9) if rows else b""
        encoded.append(struct.pack("<HHI", first, rows, len(data)) + data)

    header = struct.pack("<4sHHHH", b"TSPZ", w, h, len(encoded), fps)
    offset = len(header) + 4 * len(encoded)
    table = bytearray()
    for e in encoded:
        table += struct.pack("<I", offset)
        offset += len(e)

    os.makedirs(os.path.dirname(out_path), exist_ok=True)
    with open(out_path, "wb") as out:
        out.write(header + table + b"".join(encoded))

    print(f"[+] Encoded {len(encoded)} TSPZ frames into {out_path} ({offset / 1024:.1f} KB)")


def main():
    parser = argparse.ArgumentParser(description="Generate Option A ReTort boot splash")
    parser.add_argument("--fg", default="#80DCAA", help="Foreground color (default: #80DCAA)")
    parser.add_argument("--src", default=SRC_VIDEO, help="Source MP4")
    args = parser.parse_args()

    fg = parse_color(args.fg)
    print(f"==> Generating Option A Boot Splash")
    print(f"    Source Video: {args.src}")
    print(f"    Target Background: #{BG[0]:02X}{BG[1]:02X}{BG[2]:02X} {BG}")
    print(f"    Target Foreground: #{fg[0]:02X}{fg[1]:02X}{fg[2]:02X} {fg}")

    if not os.path.exists(args.src):
        print(f"[-] Error: Source video {args.src} not found!", file=sys.stderr)
        sys.exit(1)

    # 1. Decode source video
    raw = subprocess.run([
        "ffmpeg", "-v", "error", "-i", args.src,
        "-f", "rawvideo", "-pix_fmt", "rgb24", "-"
    ], stdout=subprocess.PIPE, check=True).stdout

    stride_rgb = W * H * 3
    num_frames = len(raw) // stride_rgb
    print(f"    Loaded {num_frames} frames from source video")

    # 2. Invert frames using LUT
    lut_r, lut_g, lut_b = build_lut(BG, fg)
    alpha_chan = Image.new("L", (W, H), 255)

    pil_frames = []
    bgr_frames = []

    # First pass: find where motion stops
    # In user's video, motion completes at frame 29
    last_motion_frame = 29

    for i in range(num_frames):
        if i <= last_motion_frame:
            frame_rgb = Image.frombytes("RGB", (W, H), raw[i * stride_rgb : (i + 1) * stride_rgb])
            gray = frame_rgb.convert("L")
            r_chan = gray.point(lut_r)
            g_chan = gray.point(lut_g)
            b_chan = gray.point(lut_b)
            inv_im = Image.merge("RGB", (r_chan, g_chan, b_chan))
        else:
            # Hold exact static final frame to guarantee zero noise / zero delta
            inv_im = pil_frames[last_motion_frame]

        pil_frames.append(inv_im)

        # Convert to BGR0 for Plastron TSPZ
        r, g, b = inv_im.split()
        bgr0 = Image.merge("RGBA", (b, g, r, alpha_chan)).tobytes()
        bgr_frames.append(bgr0)

    # 3. Export MP4
    os.makedirs(os.path.dirname(OUT_VIDEO), exist_ok=True)
    p = subprocess.Popen([
        "ffmpeg", "-y", "-loglevel", "error",
        "-f", "image2pipe", "-vcodec", "png", "-r", str(FPS),
        "-i", "-",
        "-c:v", "libx264", "-pix_fmt", "yuv420p", "-crf", "18",
        "-movflags", "+faststart", OUT_VIDEO
    ], stdin=subprocess.PIPE)

    for f in pil_frames:
        f.save(p.stdin, "PNG")
    p.stdin.close()
    p.wait()

    print(f"[+] Exported MP4 to {OUT_VIDEO} ({os.path.getsize(OUT_VIDEO) / 1024:.1f} KB)")

    # 4. Encode TSPZ binary for TrimUI Brick
    encode_tspz(bgr_frames, OUT_BIN, W, H, FPS)

    print("==> Done! Boot splash is ready for flashing via ./build.sh splash")


if __name__ == "__main__":
    main()
