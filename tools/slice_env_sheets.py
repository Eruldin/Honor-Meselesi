#!/usr/bin/env python3
"""env_a.jpg / env_b.jpg / scene.jpg konsept sheet'lerinden oyun asset'i kirpar.

Iki asamali: once satir bandi -> satisiz sirali kareler (v2raw_*), montage ile
dogrulaninca finalize_env_slices.py isimleri atar.

- ROW: koyu zeminde sprite karesi satiri — bilesen tespiti + x sirali.
- BOX: tek parca (pano, tek sprite) — alpha temizli veya ham kutu.

Cikti: assets_external/generated/ai/
"""
import os
import sys
from collections import deque

import numpy as np
from PIL import Image

ROOT = os.path.join(os.path.dirname(__file__), "..")
SHEETS = os.path.join(ROOT, "assets_external", "ai_sheets")
OUT = os.path.join(ROOT, "assets_external", "generated", "ai")

BG_THR = 42


def background_mask(img, thr=BG_THR):
    a = np.asarray(img.convert("RGB"))
    dark = a.max(axis=2) < thr
    h, w = dark.shape
    bg = np.zeros((h, w), bool)
    q = deque()
    for x in range(w):
        for y in (0, h - 1):
            if dark[y, x] and not bg[y, x]:
                bg[y, x] = True
                q.append((y, x))
    for y in range(h):
        for x in (0, w - 1):
            if dark[y, x] and not bg[y, x]:
                bg[y, x] = True
                q.append((y, x))
    while q:
        y, x = q.popleft()
        for dy, dx in ((1, 0), (-1, 0), (0, 1), (0, -1)):
            ny, nx = y + dy, x + dx
            if 0 <= ny < h and 0 <= nx < w and dark[ny, nx] and not bg[ny, nx]:
                bg[ny, nx] = True
                q.append((ny, nx))
    return bg


def comps_in(box, bg):
    x0, y0, x1, y1 = box
    fg = ~bg[y0:y1, x0:x1]
    h, w = fg.shape
    seen = np.zeros_like(fg)
    out = []
    for y in range(h):
        for x in range(w):
            if fg[y, x] and not seen[y, x]:
                st = [(y, x)]
                seen[y, x] = True
                xs, ys = [], []
                while st:
                    cy, cx = st.pop()
                    xs.append(cx)
                    ys.append(cy)
                    for dy, dx in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                        ny, nx = cy + dy, cx + dx
                        if (0 <= ny < h and 0 <= nx < w and fg[ny, nx]
                                and not seen[ny, nx]):
                            seen[ny, nx] = True
                            st.append((ny, nx))
                out.append((min(xs) + x0, min(ys) + y0,
                            max(xs) + 1 + x0, max(ys) + 1 + y0, len(xs)))
    return out


def crop_clean(img, box, bg):
    x0, y0, x1, y1 = box
    reg = np.array(img.crop(box).convert("RGBA"))
    reg[:, :, 3] = np.where(bg[y0:y1, x0:x1], 0, 255).astype(np.uint8)
    f = Image.fromarray(reg)
    bb = f.getbbox()
    return f.crop(bb) if bb else f


def norm_cell(img, cell):
    if img.height > cell - 4 or img.width > cell - 4:
        s = min((cell - 4) / img.height, (cell - 4) / img.width)
        img = img.resize((max(1, int(img.width * s)),
                          max(1, int(img.height * s))), Image.NEAREST)
    cv = Image.new("RGBA", (cell, cell), (0, 0, 0, 0))
    cv.paste(img, ((cell - img.width) // 2, cell - img.height), img)
    return cv


def keep_sprite(c):
    x0, y0, x1, y1, area = c
    w_, h_ = x1 - x0, y1 - y0
    if h_ < 9 or area < 40:
        return False
    if w_ > 130 or h_ > 130:
        return False
    if w_ / max(h_, 1) > 3.2 and h_ < 20:
        return False
    return True


_saved = []


def save(img, name, cell=0):
    if cell:
        img = norm_cell(img, cell)
    img.save(os.path.join(OUT, name + ".png"))
    _saved.append(name)


def row(img, bg, name, band, cell=64):
    """Band icindeki kareleri x sirasinda <name>_0..N kaydet."""
    cand = sorted([c for c in comps_in(band, bg) if keep_sprite(c)],
                  key=lambda c: c[0])
    n = 0
    for c in cand:
        f = crop_clean(img, c[:4], bg)
        if f.width < 4 or f.height < 4:
            continue
        save(f, "%s_%d" % (name, n), cell)
        n += 1
    print("%-14s %3d kare  %s" % (name, n, band))
    return n


def box(img, bg, name, b, clean=True, cell=0):
    f = crop_clean(img, b, bg) if clean else img.crop(b).convert("RGBA")
    save(f, name, cell)
    print("%-14s %dx%d" % (name, f.width, f.height))


def main() -> int:
    os.makedirs(OUT, exist_ok=True)
    A = Image.open(os.path.join(SHEETS, "env_a.jpg"))
    bga = background_mask(A)

    # ---- ANA KARAKTER paneli: x0-455 / y648-762 (2 satir)
    row(A, bga, "v2pc1", (5, 650, 455, 708))          # satir1: idle..savurma
    row(A, bga, "v2pc2", (5, 708, 455, 765))          # satir2: hasar..ozel

    # ---- DUSMAN paneli: x465-755 / y648-762 (2 satir)
    row(A, bga, "v2en1", (465, 650, 758, 708))
    row(A, bga, "v2en2", (465, 708, 758, 765))

    # ---- GLITCH YARATIK paneli: x760-1024 / y648-762
    row(A, bga, "v2gl1", (762, 650, 1024, 708))
    row(A, bga, "v2gl2", (762, 708, 1024, 765))

    # ---- ZEMIN TILESET: x5-300 / y195-330 (4 satir)
    row(A, bga, "v2ta", (8, 196, 300, 228))
    row(A, bga, "v2tb", (8, 228, 300, 258))
    row(A, bga, "v2tc", (8, 258, 300, 290))
    row(A, bga, "v2td", (8, 290, 300, 330))

    # ---- YAPI: x312-710 / y195-330 (2 satir)
    row(A, bga, "v2ha", (312, 196, 710, 265))
    row(A, bga, "v2hb", (312, 265, 710, 330))

    # ---- DOGA: x715-1024 / y195-330 (2 satir)
    row(A, bga, "v2na", (715, 196, 1024, 285))
    row(A, bga, "v2nb", (715, 285, 1024, 330))

    # ---- IC MEKAN: x5-405 / y398-635 (3 satir)
    row(A, bga, "v2rm", (5, 400, 405, 470))
    row(A, bga, "v2fu", (5, 470, 405, 545))
    row(A, bga, "v2fu2", (5, 545, 405, 632))

    # ---- TV: x410-622 / y400-475
    row(A, bga, "v2tv", (410, 400, 622, 472))

    # ---- DEKORASYON: x410-622 / y480-632 (2 satir)
    row(A, bga, "v2dc", (410, 480, 622, 545))
    row(A, bga, "v2dc2", (410, 545, 622, 632))

    # ---- SU: x630-830 / y398-632 (3 satir)
    row(A, bga, "v2wa", (630, 400, 832, 470))
    row(A, bga, "v2wb", (630, 470, 832, 545))
    row(A, bga, "v2wc", (630, 545, 832, 632))

    # ---- HAVA: x835-1024 / y398-632
    box(A, bga, "v2moon", (845, 398, 902, 448))
    row(A, bga, "v2cl", (835, 450, 1024, 505))
    row(A, bga, "v2fg", (835, 505, 1024, 565))
    row(A, bga, "v2cl2", (835, 565, 1024, 632))

    # ---- PANORAMA + alt panolar: y0-185
    box(A, bga, "v2pano", (0, 12, 1024, 112), clean=False)
    for i, (x0, x1) in enumerate([(15, 202), (205, 332), (335, 508),
                                  (510, 668), (670, 812), (815, 907),
                                  (910, 1024)]):
        box(A, bga, "v2pano_%d" % i, (x0, 118, x1, 182), clean=False)

    # ---- VFX: x0-435 / y775-930 (2 satir)
    row(A, bga, "v2vfx1", (8, 775, 435, 848))
    row(A, bga, "v2vfx2", (8, 848, 435, 930))

    # ---- ISIK: x440-640 / y775-930 (2 satir)
    row(A, bga, "v2lt1", (440, 775, 642, 855))
    row(A, bga, "v2lt2", (440, 855, 642, 930))

    # ---- PARCACIK: x645-782 / y775-930
    row(A, bga, "v2pt", (645, 775, 782, 930))

    # ---- KARARLI NESNELER: x785-1024 / y775-930 (2 satir)
    row(A, bga, "v2ob1", (785, 775, 1024, 855))
    row(A, bga, "v2ob2", (785, 855, 1024, 930))

    print("toplam %d dosya" % len(_saved))
    return 0


if __name__ == "__main__":
    sys.exit(main())
