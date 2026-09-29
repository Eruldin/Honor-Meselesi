#!/usr/bin/env python3
"""Bolum 1 icin kaynak atlaslardan parca keser -> assets_external/generated/.

Calistir: python tools/build_ch1_assets.py  (proje kokunden)
"""
import os
from PIL import Image

ROOT = os.path.join(os.path.dirname(__file__), "..")
EXT = os.path.join(ROOT, "assets_external")
OUT = os.path.join(EXT, "generated")
os.makedirs(OUT, exist_ok=True)

GROUND = os.path.join(EXT, "env/darkforest/env_ground.png")
DECO = os.path.join(EXT, "env/darkforest/decorative_obj.png")
TILEMAP = os.path.join(EXT, "env/tilemap/tilemap.png")
ANIMALS = os.path.join(EXT, "sprites/rogues/32rogues/animals.png")


def cut(src, box, name):
    im = Image.open(src).convert("RGBA")
    piece = im.crop(box)
    # Alphasi tamamen sifir olan dis sütun/satirlari kirp
    bbox = piece.getbbox()
    if bbox:
        piece = piece.crop(bbox)
    piece.save(os.path.join(OUT, name))
    print(name, piece.size)


# --- Darkforest env_ground: organik zemin/platform parcalari ---
cut(GROUND, (20, 60, 165, 80), "pf_ledge.png")        # uzun ince sahcik
cut(GROUND, (178, 52, 296, 125), "pf_plateau.png")    # bacakli buyuk plato
cut(GROUND, (55, 148, 150, 178), "pf_slab.png")       # genis cimli plato
cut(GROUND, (226, 110, 292, 178), "pf_corner.png")    # L kose parcasi
cut(GROUND, (88, 93, 140, 128), "pf_block.png")       # kucuk blok
cut(GROUND, (362, 138, 470, 164), "pf_grass_wide.png")  # sag cimli serit
cut(GROUND, (158, 404, 345, 438), "pf_dirt_slab.png")  # kuru toprak serit
cut(GROUND, (128, 116, 232, 144), "pf_moss.png")       # sarkan yosun dekoru
cut(GROUND, (0, 120, 142, 175), "pf_rock_l.png")       # sol kaya blogsu
cut(GROUND, (300, 200, 480, 260), "pf_rock_r.png")     # sag kaya blogsu
cut(GROUND, (30, 240, 200, 300), "pf_dirt_l.png")      # kuru kose
cut(GROUND, (300, 300, 470, 360), "pf_dirt_r.png")     # kuru kose sag

# --- Darkforest decorative_obj: tapinak/koy objeleri ---
cut(DECO, (4, 16, 215, 195), "deco_gate.png")          # buyuk kemer kapi
cut(DECO, (296, 8, 362, 142), "deco_pillar.png")       # torii benzeri sutun
cut(DECO, (444, 6, 496, 142), "deco_pillar2.png")
cut(DECO, (516, 4, 566, 74), "deco_lantern.png")       # cicekli fener diregi
cut(DECO, (350, 176, 392, 234), "deco_pedestal.png")
cut(DECO, (408, 176, 480, 204), "deco_crate.png")
cut(DECO, (0, 198, 312, 295), "deco_bridge.png")       # buyuk kopru
cut(DECO, (438, 246, 606, 306), "deco_bridge_sm.png")  # kucuk kopru
cut(DECO, (62, 418, 240, 460), "deco_wall.png")        # duvar parcasi
cut(DECO, (326, 376, 356, 470), "deco_tower.png")      # ince kule sutunu

# --- decorative_obj duzeltmeleri: torii kapi + tas fener ---
# (eski deco_gate hexagonal cerceveydi — gercek torii cift-direk kapi)
cut(DECO, (270, 0, 380, 162), "deco_gate.png")         # torii kapi cercevesi
cut(DECO, (553, 98, 582, 162), "deco_lantern.png")     # tas fener (sade)

# --- Arena bariyer sutunu: gotik tugla duvardan 20x160 doseme ---
GWALL = os.path.join(EXT, "env/gothic_town/GothicVania-town-files/PNG/environment/layers/sliced-tileset/ground-wall.png")
if os.path.exists(GWALL):
    src = Image.open(GWALL).convert("RGBA")
    wall = Image.new("RGBA", (20, 160), (0, 0, 0, 0))
    tile = src.resize((20, 20), Image.NEAREST)
    for y in range(0, 160, 20):
        wall.paste(tile, (0, y))
    # alttan ustune hafif koyulasma — zemine oturma hissi
    px = wall.load()
    for y in range(160):
        f = 0.55 + 0.45 * (y / 160.0)
        for x in range(20):
            r, g, b, a = px[x, y]
            if a > 0:
                px[x, y] = (int(r * f), int(g * f), int(b * f), a)
    wall.save(os.path.join(OUT, "deco_barrier.png"))
    print("deco_barrier.png", wall.size)

# --- tilemap.png: magara kayasi/kristal ---
cut(TILEMAP, (0, 0, 64, 32), "cave_bricks.png")        # tugla sirasi
cut(TILEMAP, (96, 8, 160, 40), "cave_crystal.png")     # kristal kumesi
cut(TILEMAP, (0, 32, 96, 80), "cave_rock.png")         # kayalik bloklar
cut(TILEMAP, (96, 48, 192, 80), "cave_shroom.png")     # mantar/kok dekoru

# --- 32rogues animals.png: kumes hayvanlari (Lord Cluck + ambient) ---
# Satir 13 (y=416-448): buyuk kuslar — kasuari boss icin ideal
# Satir 14 (y=448-480): tavuk, horoz, ordek, kaz, hindi, kus, tavus
cut(ANIMALS, (6, 450, 23, 478), "chicken.png")         # kahverengi tavuk
cut(ANIMALS, (40, 450, 61, 478), "rooster_small.png")  # kucuk horoz
cut(ANIMALS, (70, 450, 88, 478), "duck.png")           # ordek
cut(ANIMALS, (103, 450, 123, 478), "goose.png")        # kaz
cut(ANIMALS, (134, 450, 156, 478), "turkey.png")       # hindi
cut(ANIMALS, (192, 450, 225, 478), "peacock.png")      # tavuskusu
# Lord Cluck: satir-13 kasuari (23x27, gorkemli ve iritist)
cut(ANIMALS, (64, 417, 92, 448), "rooster.png")

# --- Kesintisiz zemin kenari seritleri (sikis doseme icin ince) ---
cut(GROUND, (122, 76, 232, 92), "edge_grass.png")      # yassi cim kenari
cut(GROUND, (160, 406, 336, 420), "edge_dirt.png")     # yassi toprak kenari

# --- Modern Interiors: prolog kulubesi mobilyalari ---
INT = os.path.join(EXT, "env/interiors/Modern tiles_Free/Interiors_free/16x16/Interiors_free_16x16.png")
cut(INT, (0, 0, 48, 48), "furn_bed.png")          # yesil yatak/futon
cut(INT, (150, 258, 232, 314), "furn_rug.png")    # kirmizi hali
cut(INT, (20, 250, 74, 314), "furn_shelf.png")    # cicekli raf
cut(INT, (148, 190, 210, 226), "furn_table.png")  # alcak ahşap masa
cut(INT, (238, 112, 256, 164), "furn_lamp.png")   # ayakli lamba
cut(INT, (20, 336, 74, 380), "furn_books.png")    # kitaplik
cut(INT, (196, 336, 236, 370), "furn_stool.png")  # tabure

print("done ->", OUT)
