#!/usr/bin/env python3
"""bosses.jpg konsept sheet'inden boss animasyon kareleri kirpar.

Her boss hucresi: banner + "HAREKET ANIMASYONLARI" satiri +
"SALDIRI ANIMASYONLARI" satiri + FAZ metni (sagda, atlanir).
Kare tespiti: koyu zemin flood-fill + bagli bilesen analizi;
satirlar yogunluk kumelemesiyle bulunur.

Cikti: assets_external/generated/ai/boss_<key>_(move|attack)_N.png
Calistir: python tools/slice_boss_sheets.py
"""
import os
import sys
from collections import deque

import numpy as np
from PIL import Image

ROOT = os.path.join(os.path.dirname(__file__), "..")
SRC = os.path.join(ROOT, "assets_external", "ai_sheets", "bosses.jpg")
OUT = os.path.join(ROOT, "assets_external", "generated", "ai")

BG_THR = 42
CELL = 64          # kareler bu tuvele ayak-hizali normalize edilir
MIN_W, MAX_W = 9, 95
MIN_H, MAX_H = 9, 95
MIN_AREA = 40
MAX_ASPECT = 3.2    # bundan yassi + alcak = metin blogu

# (key, cell_x0, cell_y0, cell_x1, cell_y1) — sheet koordinatlari
BOSSES = [
    ("cluck",      0,   0, 512, 205),
    ("demir",    512,   0, 1024, 205),
    ("golge",      0, 205, 512, 400),
    ("yokluk",   512, 205, 1024, 400),
    ("agac",       0, 400, 512, 592),
    ("zaman",    512, 400, 1024, 592),
    ("aclik",      0, 592, 512, 772),
    ("yuzler",   512, 592, 1024, 772),
    ("sapkasiz",   0, 772, 560, 935),
]

# Hucresin icinde frame satirlari bu y araliginda; FAZ metni sagda.
ROW_Y_LO, ROW_Y_HI = 85, 200       # cell-relative
ROW_X_LO, ROW_X_HI = 8, 420        # cell-relative


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
    return bg  # True = arka plan


def components(fg):
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
                out.append((min(xs), min(ys), max(xs) + 1, max(ys) + 1))
    return out


def normalize(img, cell=CELL):
    if img.height > cell - 4 or img.width > cell - 4:
        s = min((cell - 4) / img.height, (cell - 4) / img.width)
        img = img.resize((max(1, int(img.width * s)),
                          max(1, int(img.height * s))), Image.NEAREST)
    canvas = Image.new("RGBA", (cell, cell), (0, 0, 0, 0))
    canvas.paste(img, ((cell - img.width) // 2, cell - img.height), img)
    return canvas


def crop_frame(img, box, bg):
    x0, y0, x1, y1 = box
    region = np.array(img.crop(box).convert("RGBA"))
    region[:, :, 3] = np.where(bg[y0:y1, x0:x1], 0, 255).astype(np.uint8)
    out = Image.fromarray(region)
    bbox = out.getbbox()
    return out.crop(bbox) if bbox else out


def main() -> int:
    os.makedirs(OUT, exist_ok=True)
    img = Image.open(SRC)
    bg = background_mask(img)
    fg = ~bg
    comps = components(fg)

    for key, cx0, cy0, cx1, cy1 in BOSSES:
        # Hucre icindeki sprite boyutlu bilesenler
        cand = []
        for (x0, y0, x1, y1) in comps:
            w_, h_ = x1 - x0, y1 - y0
            if not (MIN_W <= w_ <= MAX_W and MIN_H <= h_ <= MAX_H):
                continue
            if w_ * h_ < MIN_AREA:
                continue
            if w_ / max(h_, 1) > MAX_ASPECT and h_ < 20:
                continue
            rx, ry = x0 - cx0, y0 - cy0
            if not (ROW_X_LO <= rx < ROW_X_HI and ROW_Y_LO <= ry < ROW_Y_HI):
                continue
            cand.append((x0, y0, x1, y1))
        # Satirlara kumele (y merkezine gore, >=12px bosluk yeni satir)
        cand.sort(key=lambda c: (c[1] + c[3]) / 2)
        rows = []
        for c in cand:
            cy = (c[1] + c[3]) / 2
            if rows and cy - rows[-1][0] < 14:
                rows[-1][1].append(c)
            else:
                rows.append([cy, [c]])
        rows = [sorted(r[1], key=lambda c: c[0]) for r in rows]
        rows = [r for r in rows if len(r) >= 4]
        if len(rows) < 2:
            print("!! %s: %d satir bulundu (beklenen 2)" % (key, len(rows)))
            continue
        # en buyuk alanli iki satir sprite satirlaridir; metin/etiket satirlari elenir
        rows.sort(key=lambda r: -sum((c[2]-c[0])*(c[3]-c[1]) for c in r))
        move_row, attack_row = sorted(rows[:2], key=lambda r: r[0][1])
        for tag, row in (("move", move_row), ("attack", attack_row)):
            for i, box in enumerate(row):
                f = crop_frame(img, box, bg)
                if f.width < 4 or f.height < 4:
                    continue
                f = normalize(f)
                name = "boss_%s_%s_%d.png" % (key, tag, i)
                f.save(os.path.join(OUT, name))
            print("%-9s %s: %d kare" % (key, tag, len(row)))
    print("->", OUT)
    return 0


if __name__ == "__main__":
    sys.exit(main())
