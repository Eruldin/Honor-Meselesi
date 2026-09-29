#!/usr/bin/env python3
"""AI uretim sprite sheet'lerinden oyun asset'i kirpar.

Kullanim: python tools/slice_ai_assets.py
Kaynaklar: assets_external/ai_sheets/*.png (koyu zemin uzerinde sprite'lar)
Cikti: assets_external/generated/ai/*.png (alfa'li PNG)

Arka plan temizleme: kenarlardan flood-fill — lum<THR olan ve kenara
bagli pikseller alfa=0 olur; sprite icindeki koyu bolgeler korunur.
"""
import os
import sys
from collections import deque

import numpy as np
from PIL import Image

ROOT = os.path.join(os.path.dirname(__file__), "..")
SRC = os.path.join(ROOT, "assets_external", "ai_sheets")
OUT = os.path.join(ROOT, "assets_external", "generated", "ai")

BG_THR = 42      # bu esigin alti + kenara bagli = arka plan


def cut_bg(img: Image.Image, thr: int = BG_THR) -> Image.Image:
    """Koyu zemini flood-fill ile temizler, alpha kanali uretir."""
    rgba = np.array(img.convert("RGBA"))
    lum = rgba[:, :, :3].max(axis=2)
    h, w = lum.shape
    dark = lum < thr
    bg = np.zeros((h, w), dtype=bool)
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
    rgba[:, :, 3] = np.where(bg, 0, 255).astype(np.uint8)
    out = Image.fromarray(rgba)
    bbox = out.getbbox()
    return out.crop(bbox) if bbox else out


def normalize_cell(img: Image.Image, cell: int = 64) -> Image.Image:
    """Sprite'i sabit kareye normalize eder: ayaklar alta, yatayda orta."""
    if img.height > cell - 4 or img.width > cell - 4:
        s = min((cell - 4) / img.height, (cell - 4) / img.width)
        img = img.resize((max(1, int(img.width * s)),
                          max(1, int(img.height * s))), Image.NEAREST)
    canvas = Image.new("RGBA", (cell, cell), (0, 0, 0, 0))
    canvas.paste(img, ((cell - img.width) // 2, cell - img.height), img)
    return canvas


def slice_spec(sheet: str, name: str, box: tuple, scale: float = 1.0,
               grid: tuple = None, cell: int = 0, thr: int = BG_THR) -> list:
    """tek kare veya esit gridli seri kirpar. grid=(kolon,satir).
    cell>0 ise her kareyi cellxcell tuvele ayak-hizali normalize eder.
    thr: bg esigi (koyu sprite'lar icin dusur)."""
    im = Image.open(os.path.join(SRC, sheet))
    region = im.crop(box)
    saved = []
    if grid:
        cw = region.width // grid[0]
        ch = region.height // grid[1]
        cells = [region.crop((c * cw, r * ch, (c + 1) * cw, (r + 1) * ch))
                 for r in range(grid[1]) for c in range(grid[0])]
    else:
        cells = [region]
    for i, cel_img in enumerate(cells):
        cleaned = cut_bg(cel_img, thr)
        if cleaned.width < 3 or cleaned.height < 3:
            print("  ! bos kare atlandi:", name, i)
            continue
        if cell > 0:
            cleaned = normalize_cell(cleaned, cell)
        if scale != 1.0:
            cleaned = cleaned.resize(
                (max(1, int(cleaned.width * scale)),
                 max(1, int(cleaned.height * scale))), Image.NEAREST)
        suffix = "" if len(cells) == 1 else "_%d" % i
        path = os.path.join(OUT, name + suffix + ".png")
        cleaned.save(path)
        saved.append(path)
        print("  + %s (%dx%d)" % (os.path.basename(path),
                                  cleaned.width, cleaned.height))
    return saved


def main() -> None:
    os.makedirs(OUT, exist_ok=True)

    # === ANA KARAKTER (interior.png — 'ANA KARAKTER SPRITELARI') ===
    R1 = (515, 590)   # satir 1 sprite bandi
    ROW1 = [
        ("player_idle",    (30, R1[0], 80, R1[1])),
        ("player_walk_1",  (105, R1[0], 160, R1[1])),
        ("player_walk_2",  (185, R1[0], 240, R1[1])),
        ("player_walk_3",  (265, R1[0], 315, R1[1])),
        ("player_run",     (340, R1[0], 395, R1[1])),
        ("player_attack",  (415, R1[0], 475, R1[1])),
        ("player_jump",    (515, R1[0], 580, R1[1])),
        ("player_interact",(610, R1[0], 675, R1[1])),
    ]
    R2 = (630, 700)   # satir 2 sprite bandi
    ROW2 = [
        ("player_attack2", (30, R2[0], 105, R2[1])),   # kombo kare 1+ark
        ("player_attack3", (105, R2[0], 260, R2[1])),  # kombo kare 2+ark
        ("player_air",     (270, R2[0], 445, R2[1])),  # havada saldiri
        ("player_hurt",    (460, R2[0], 520, R2[1])),
        ("player_dead",    (700, R2[0], 760, R2[1])),  # yere dusmus
    ]
    for name, box in ROW1 + ROW2:
        slice_spec("interior.png", name, box, cell=64)

    # === GLITCH YARATIK (interior.png — serit y~780-870) ===
    GL = (782, 862)
    for i, (x0, x1) in enumerate([
            (15, 110), (115, 185), (208, 268), (300, 395),
            (420, 530), (575, 625), (665, 720), (840, 955)]):
        slice_spec("interior.png", "glitch_%d" % i, (x0, GL[0], x1, GL[1]),
                   cell=64)

    # === IC MEKAN OBJELERI (interior.png — oda sahnesi) ===
    for name, box in [
        ("j_lantern",   (105, 225, 200, 310)),   # asili fener + isilti
        ("j_scroll_a",  (515, 155, 575, 240)),   # dag manzara parsomen
        ("j_scroll_b",  (580, 155, 645, 240)),   # kaligrafi parsomen
        ("j_shelf",     (655, 140, 790, 265)),   # kavanoz raf
        ("j_banner",    (1195, 165, 1310, 335)), # kirmizi armali bayrak
        ("j_lantern2",  (1265, 225, 1340, 340)), # sag fener
        ("j_tv",        (355, 305, 500, 400)),   # TV + sehpa
        ("j_sit",       (275, 315, 350, 405)),   # oturan samuray
        ("j_katana",    (315, 225, 465, 275)),   # duvar katana rafi
        ("j_rift",      (1290, 150, 1535, 345)), # mor glitch yarik + sapka
        ("j_wall",      (230, 120, 330, 230)),   # temiz tahta duvar
        ("j_floor",     (150, 392, 420, 448)),   # tahta doseme seridi
    ]:
        slice_spec("interior.png", name, box)

    # === KOY / SAHNE (buildings.png) ===
    # zemin tilelari: satir1 cim-toprak, satir2 tas-yosun, satir3 tahta
    for i in range(5):
        slice_spec("buildings.png", "tile_grass_%d" % i,
                   (22 + i * 63, 556, 84 + i * 63, 615))
        slice_spec("buildings.png", "tile_stone_%d" % i,
                   (22 + i * 63, 617, 84 + i * 63, 662))
        slice_spec("buildings.png", "tile_wood_%d" % i,
                   (22 + i * 63, 664, 84 + i * 63, 708))
    # buyuk iki katli ev (oyuncunun evi)
    slice_spec("buildings.png", "j_house_main", (340, 527, 545, 700))
    # arka plan: ay, dag silsilesi, kiraz agaci, selale ucurumu
    slice_spec("buildings.png", "bg_moon",      (955, 530, 1040, 615))
    slice_spec("buildings.png", "bg_mountains", (1040, 545, 1300, 645))
    slice_spec("buildings.png", "bg_cherry",    (1380, 535, 1565, 665))
    slice_spec("buildings.png", "bg_falls",     (1575, 535, 1665, 705))
    slice_spec("buildings.png", "bg_trees",     (1140, 615, 1400, 705))
    # torii + fener direkleri (sahne tilesi bolumunde ahshap parcalar)
    slice_spec("buildings.png", "j_lamppost",   (280, 645, 330, 700))
    # HUD: samuray portresi + oni maske kalp + katana bar (panorama sol ust)
    slice_spec("buildings.png", "hud_portrait", (5, 45, 95, 110))
    slice_spec("buildings.png", "hud_heart",    (112, 32, 148, 70), thr=28)
    slice_spec("buildings.png", "hud_heart_row",(108, 30, 300, 72), thr=28)
    slice_spec("buildings.png", "hud_katana",   (95, 70, 295, 95))
    # samuray sapkasi (sapka bolumu — sapka sprite'lari)
    slice_spec("buildings.png", "j_hat",        (1120, 830, 1175, 885))

    print("bitti ->", OUT)


if __name__ == "__main__":
    sys.exit(main())
