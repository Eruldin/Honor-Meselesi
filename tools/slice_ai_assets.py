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

    # === IC MEKAN OBJELERI (interior.png 1670x942) ===
    # Panoramadaki duvar ogeleri (arka plan sahne duvari — alp kalir)
    for name, box in [
        ("j_shoji",    (55, 145, 188, 345)),    # ayli soji pencere
        ("j_scroll_a", (295, 118, 398, 340)),   # dag manzara parsomen
        ("j_scroll_b", (900, 142, 988, 338)),   # kaligrafi parsomen
        ("j_banner",   (1130, 562, 1202, 688)), # kirmizi armali bayrak (izole)
        ("j_lantern",  (1165, 148, 1258, 292)), # asili buyuk fener
        ("j_lantern2", (908, 278, 972, 352)),   # duvarda kucuk fener
        ("j_sit",      (318, 288, 432, 405)),   # oturan samuray
        ("j_rift",     (1238, 138, 1408, 398)), # mor glitch yarik + sapka
        ("j_wall",     (798, 148, 898, 292)),   # temiz tahta duvar
        ("j_floor",    (98, 390, 700, 440)),    # tahta doseme seridi
    ]:
        slice_spec("interior.png", name, box)
    # Orta bolum: koyu zeminde izole mobilyalar (INTERIOR VE SAHNE ASSETLERI)
    for name, box in [
        ("j_shelf",    (1268, 553, 1372, 657)), # kalabalik raf unitesi
        ("j_cabinet",  (1198, 558, 1272, 662)), # dama desenli dolap
        ("j_vase",     (1358, 553, 1408, 602)), # cicekli vazo
        ("j_moonwin",  (1405, 538, 1462, 665)), # ayli pencere
        ("j_katana",   (1268, 662, 1422, 682)), # stantta kilic (yatay)
        ("j_lantern3", (1448, 693, 1522, 777)), # suslu yanan fener
        ("j_chest",    (1558, 698, 1632, 777)), # sari dolap/sandik
        ("j_table",    (998, 713, 1124, 762)),  # alcak masa + minderler
    ]:
        slice_spec("interior.png", name, box)
    # Alt bolum: CRT TV + kucuk esyalar (DIGER ONEMLI VARLIKLAR)
    for name, box in [
        ("j_tv",       (1258, 698, 1332, 767)), # CRT televizyon (mavi ek)
        ("j_tv_bars",  (1070, 838, 1132, 902)), # renk barli TV (glitch!)
        ("j_kettle",   (1400, 825, 1462, 872)), # cay takimi
        ("j_candle",   (1558, 812, 1612, 880)), # yanan mum fener
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
    # buyuk iki katli japon evi — "YAPI ASSETLERI" etiketinin ALTINDAN
    slice_spec("buildings.png", "j_house_main", (325, 578, 502, 745))
    # torii kapisi (zemin tiles bolumunun altinda, iki direkli kapi)
    slice_spec("buildings.png", "j_torii",      (100, 652, 290, 720))
    # arka plan: ay, dag silsilesi, kiraz agaci, selale ucurumu
    slice_spec("buildings.png", "bg_moon",      (955, 530, 1040, 615))
    slice_spec("buildings.png", "bg_mountains", (1040, 545, 1300, 645))
    slice_spec("buildings.png", "bg_cherry",    (1380, 535, 1565, 665))
    slice_spec("buildings.png", "bg_falls",     (1575, 535, 1665, 705))
    slice_spec("buildings.png", "bg_trees",     (1140, 615, 1400, 705))
    # DEKORASYON: saksili bitkiler + cit + tas pagoda fener
    slice_spec("buildings.png", "j_plant_0",   (12, 788, 90, 845))
    slice_spec("buildings.png", "j_plant_1",   (98, 792, 160, 845))
    slice_spec("buildings.png", "j_plant_2",   (168, 795, 230, 845))
    slice_spec("buildings.png", "j_plant_3",   (12, 862, 160, 920))
    slice_spec("buildings.png", "j_fence_0",   (168, 862, 285, 905))
    slice_spec("buildings.png", "j_stone_lamp",(340, 858, 392, 925))
    slice_spec("buildings.png", "j_stone_sml", (242, 790, 292, 845))
    # IŞIK: asili kagit fenerler (parlayan) + mum/stand
    slice_spec("buildings.png", "j_lantern_hang_0", (890, 772, 925, 838))
    slice_spec("buildings.png", "j_lantern_hang_1", (930, 772, 965, 838))
    # IC MEKAN: TV (ekraninda samuray), kazan, buyuk raf, kilic rafi,
    # yesil minder, kucuk dolap — hepsi etiketsiz bolgelerden
    slice_spec("buildings.png", "j_tv_frame",  (408, 782, 482, 848))
    slice_spec("buildings.png", "j_cauldron",  (787, 870, 838, 920))
    slice_spec("buildings.png", "j_shelf_big", (678, 780, 770, 865))
    slice_spec("buildings.png", "j_sword_rack",(775, 780, 838, 862))
    slice_spec("buildings.png", "j_cushion",   (703, 873, 768, 915))
    slice_spec("buildings.png", "j_chest",     (635, 878, 692, 918))
    # HUD: samuray portresi + oni maske kalp + katana bar (panorama sol ust)
    slice_spec("buildings.png", "hud_portrait", (5, 45, 95, 110))
    slice_spec("buildings.png", "hud_heart",    (112, 32, 148, 70), thr=28)
    slice_spec("buildings.png", "hud_heart_row",(108, 30, 300, 72), thr=28)
    slice_spec("buildings.png", "hud_katana",   (95, 70, 295, 95))
    # samuray sapkasi — SAPKA SPRITELARI sirasindan tek saman sapka
    slice_spec("buildings.png", "j_hat",        (1198, 882, 1258, 918))
    slice_spec("buildings.png", "j_hat_b",      (1430, 882, 1492, 918))
    # GLITCH YARATIK (buildings) — hayalet + sapkali kacis karesi
    for i, (x0, x1) in enumerate([(1222, 1312), (1320, 1412),
                                  (1420, 1512), (1520, 1610)]):
        slice_spec("buildings.png", "glitchb_%d" % i, (x0, 784, x1, 848),
                   cell=64)
    # yanan pagoda/tapinak (sol sutun) + hedef sahne panorama seridi
    slice_spec("buildings.png", "j_shrine",     (1118, 742, 1194, 860))
    slice_spec("buildings.png", "bg_village_pan", (1100, 696, 1669, 730))

    print("bitti ->", OUT)


if __name__ == "__main__":
    sys.exit(main())
