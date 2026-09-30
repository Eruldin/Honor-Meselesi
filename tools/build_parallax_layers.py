#!/usr/bin/env python3
"""Parallax katman dokulari uretir — ParallaxBg her katmani 270px yukseklige
olcekleyip yatayda dosemedigi icin, ciktilar 270px yukseklikte, icerik alta
hizali ve ust kismi saydam/siyah uretilir.

Cikti: assets_external/generated/ai/bg_layer_*.png
"""
import os
import random
import sys

import numpy as np
from PIL import Image, ImageDraw, ImageFilter

ROOT = os.path.join(os.path.dirname(__file__), "..")
AI = os.path.join(ROOT, "assets_external", "generated", "ai")


def load(name):
    return Image.open(os.path.join(AI, name))


def darken(img, f=0.35, blue=1.15):
    a = np.asarray(img).astype(np.float32)
    a[:, :, 0] *= f
    a[:, :, 1] *= f
    a[:, :, 2] = np.clip(a[:, :, 2] * f * blue, 0, 255)
    return Image.fromarray(a.astype(np.uint8))


def paste_on(layer, img, x, y_bottom, h=None):
    if h and img.height != h:
        img = img.resize((int(img.width * h / img.height), h), Image.NEAREST)
    layer.paste(img, (x, y_bottom - img.height), img)
    return x + img.width


def strip_to_270(img):
    """Kaynak seridi 270 tavana gore alt hizali 1024x270 katmana donustur."""
    return img


def main() -> int:
    # ============ FAR: dag siluetleri (1024x270, ust %60 saydam) ============
    far = Image.new("RGBA", (1024, 270), (0, 0, 0, 0))
    d = ImageDraw.Draw(far)
    rng = random.Random(11)
    x = -40
    while x < 1100:
        w = rng.randint(220, 380)
        peak = rng.randint(80, 130)
        base = 270
        pts = [(x, base), (x + w * 0.5, base - peak), (x + w, base)]
        d.polygon(pts, fill=(14, 18, 34, 255))
        # tepe yankisi — ikinci, biraz acik siluet
        x += w // 2
    far = far.filter(ImageFilter.GaussianBlur(1.2))
    far.save(os.path.join(AI, "bg_layer_far.png"))

    # ============ MID: uzak koy/agac silueti (1024x270) ============
    mid = Image.new("RGBA", (1024, 270), (0, 0, 0, 0))
    xs = 10
    seq = ["v2ha_1.png", "v2na_6.png", "v2ha_3.png", "v2na_8.png",
           "v2ha_0.png", "v2na_2.png", "v2td_5.png", "v2na_10.png",
           "v2ha_2.png", "v2na_8.png", "v2ha_5.png", "v2na_11.png"]
    for i, name in enumerate(seq):
        t = darken(load(name), 0.30)
        h = 70 + (i % 3) * 22
        xs = paste_on(mid, t, xs, 270, h) - 14
    mid = mid.filter(ImageFilter.GaussianBlur(0.6))
    mid.save(os.path.join(AI, "bg_layer_mid.png"))

    # ============ TREES: yakin agac cizgisi (512x270) ============
    trees = Image.new("RGBA", (512, 270), (0, 0, 0, 0))
    xs = -10
    for i, name in enumerate(["v2na_8.png", "v2na_0.png", "v2na_10.png",
                              "v2na_6.png", "v2na_2.png"]):
        t = darken(load(name), 0.22)
        h = 150 + (i % 2) * 40
        xs = paste_on(trees, t, xs, 270, h) - 30
    trees.save(os.path.join(AI, "bg_layer_trees.png"))

    # ============ MIST: alcalan sis seridi (512x270, ust bos) ============
    mist = Image.new("RGBA", (512, 270), (0, 0, 0, 0))
    xs = 0
    for name in ["v2cl2_0.png", "v2cl2_1.png", "v2cl2_2.png", "v2cl2_3.png"]:
        p = os.path.join(AI, name)
        if not os.path.exists(p):
            continue
        c = load(name).convert("RGBA")
        a = np.array(c)
        a[:, :, 3] = (a[:, :, 3] * 0.55).astype(np.uint8)
        c = Image.fromarray(a)
        mist.paste(c, (xs, 262 - c.height), c)
        xs += c.width + 70
    mist = mist.filter(ImageFilter.GaussianBlur(2.0))
    mist.save(os.path.join(AI, "bg_layer_mist.png"))

    # ============ GLOW: fener isiklari katmani (512x270) ============
    glow = Image.new("RGBA", (512, 270), (0, 0, 0, 0))
    for x in [60, 190, 330, 460]:
        for dx in range(-14, 15):
            for dy in range(-8, 9):
                fall = 1.0 - (dx * dx / 196.0 + dy * dy / 64.0)
                if fall <= 0:
                    continue
                xx, yy = x + dx, 238 + dy
                if 0 <= xx < 512 and 0 <= yy < 270:
                    glow.putpixel((xx, yy),
                                  (255, 200, 120, int(70 * fall)))
    glow = glow.filter(ImageFilter.GaussianBlur(6))
    glow.save(os.path.join(AI, "bg_layer_glow.png"))

    # ============ CAVE WALL: magara arka plan dokusu (1024x270) ============
    cave = Image.new("RGBA", (1024, 270), (10, 8, 18, 255))
    xs = -20
    rng = random.Random(5)
    while xs < 1100:
        rock = darken(load("v2wb_%d.png" % rng.choice([1, 3, 5])), 0.35)
        h = rng.randint(60, 120)
        xs = paste_on(cave, rock, xs, 270, h) - 20
    cave = cave.filter(ImageFilter.GaussianBlur(1.5))
    cave.save(os.path.join(AI, "bg_layer_cave.png"))

    print("katmanlar yazildi")
    return 0


if __name__ == "__main__":
    sys.exit(main())
