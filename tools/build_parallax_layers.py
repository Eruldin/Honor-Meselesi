#!/usr/bin/env python3
"""Parallax katman dokulari uretir — ParallaxBg her katmani 270px yukseklige
olcekleyip yatayda dosemedigi icin, ciktilar 270px yukseklikte, icerik alta
hizali ve ust kismi saydam uretilir.

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


def darken(img, f=0.5, tint=(1.0, 1.0, 1.0)):
    """RGB'yi f ile koyultup tint kanal carpanlari uygular; alpha korunur."""
    a = np.asarray(img).astype(np.float32)
    a[:, :, 0] = np.clip(a[:, :, 0] * f * tint[0], 0, 255)
    a[:, :, 1] = np.clip(a[:, :, 1] * f * tint[1], 0, 255)
    a[:, :, 2] = np.clip(a[:, :, 2] * f * tint[2], 0, 255)
    return Image.fromarray(a.astype(np.uint8))


def paste_on(layer, img, x, y_bottom, h=None):
    if h and img.height != h:
        img = img.resize((int(img.width * h / img.height), h), Image.NEAREST)
    layer.paste(img, (x, y_bottom - img.height), img)
    return x + img.width


def ground_band(img, y0=228, col=(10, 9, 16, 255)):
    """Katmanin altina kapali zemin seridi — siluetler havada durmasin."""
    d = ImageDraw.Draw(img)
    d.rectangle([0, y0, img.width, 269], fill=col)


def main() -> int:
    # ============ FAR: dag siluetleri (1024x270) ============
    far = Image.new("RGBA", (1024, 270), (0, 0, 0, 0))
    d = ImageDraw.Draw(far)
    rng = random.Random(11)
    # arka sirt (uzak, daha acik/mavi)
    x = -60
    while x < 1100:
        w = rng.randint(260, 420)
        peak = rng.randint(70, 110)
        pts = [(x, 270), (x + w * 0.5, 270 - peak - 30), (x + w, 270)]
        d.polygon(pts, fill=(26, 32, 56, 255))
        x += w * 2 // 3
    # on sirt (yakin, biraz daha koyu)
    x = -40
    rng = random.Random(23)
    while x < 1100:
        w = rng.randint(220, 380)
        peak = rng.randint(60, 100)
        pts = [(x, 270), (x + w * 0.5, 270 - peak), (x + w, 270)]
        d.polygon(pts, fill=(20, 25, 44, 255))
        x += w // 2
    far = far.filter(ImageFilter.GaussianBlur(1.2))
    far.save(os.path.join(AI, "bg_layer_far.png"))

    # ============ MID: uzak koy/agac silueti (1024x270) ============
    mid = Image.new("RGBA", (1024, 270), (0, 0, 0, 0))
    ground_band(mid, 244)
    xs = 10
    seq = ["v2ha_1.png", "v2na_6.png", "v2ha_3.png", "v2na_8.png",
           "v2ha_0.png", "v2na_2.png", "v2td_5.png", "v2na_10.png",
           "v2ha_2.png", "v2na_8.png", "v2ha_5.png", "v2na_11.png"]
    for i, name in enumerate(seq):
        p = os.path.join(AI, name)
        if not os.path.exists(p):
            continue
        t = darken(load(name), 0.9, (0.85, 0.9, 1.05))
        h = 90 + (i % 3) * 30
        xs = paste_on(mid, t, xs, 250, h) - 16
    mid = mid.filter(ImageFilter.GaussianBlur(0.6))
    mid.save(os.path.join(AI, "bg_layer_mid.png"))

    # ============ TREES: yakin agac cizgisi (512x270) ============
    trees = Image.new("RGBA", (512, 270), (0, 0, 0, 0))
    ground_band(trees, 246)
    xs = -16
    seq = ["v2na_8.png", "v2na_0.png", "v2na_10.png", "v2na_6.png",
           "v2na_2.png", "v2na_11.png", "v2na_8.png", "v2na_0.png"]
    for i, name in enumerate(seq):
        p = os.path.join(AI, name)
        if not os.path.exists(p):
            continue
        t = darken(load(name), 1.0, (0.9, 0.95, 0.9))  # koyu ama gorunur
        h = 190 + (i % 2) * 50
        xs = paste_on(trees, t, xs, 254, h) - 34
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
        rock = darken(load("v2wb_%d.png" % rng.choice([1, 3, 5])), 0.5,
                      (0.8, 0.85, 1.1))
        h = rng.randint(60, 120)
        xs = paste_on(cave, rock, xs, 270, h) - 20
    cave = cave.filter(ImageFilter.GaussianBlur(1.5))
    cave.save(os.path.join(AI, "bg_layer_cave.png"))

    print("katmanlar yazildi")
    return 0


if __name__ == "__main__":
    sys.exit(main())
