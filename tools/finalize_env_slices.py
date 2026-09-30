#!/usr/bin/env python3
"""v2* ham kesitlerini anlamli adlara kopyalar + assets_manifest.json'i gunceller.

Kopya hedefleri iki katmanli:
  generated/ai/<ad>.png   -> manifest 'path': 'generated/ai/<ad>.png'
  generated/<ad>.png      -> eski slicer'in urettigi yollar (ayni isimle)
"""
import json
import os
import shutil
import sys

from PIL import Image, ImageDraw

ROOT = os.path.join(os.path.dirname(__file__), "..")
AI = os.path.join(ROOT, "assets_external", "generated", "ai")
GEN = os.path.join(ROOT, "assets_external", "generated")
MANIFEST = os.path.join(ROOT, "assets_manifest.json")

# ---------------------------------------------------------------------------
# 1) DOSYA KOPYALARI: src(ai dosya adi) -> hedef (generated/ ya da generated/ai/)
# ---------------------------------------------------------------------------
AI_COPY = {
    # oyuncu — eski adlar dahil (manifest ayni yollari bekler)
    "player_idle.png": "v2pc1_0.png",
    "player_walk_1.png": "v2pc1_1.png",
    "player_walk_2.png": "v2pc1_2.png",
    "player_walk_3.png": "v2pc1_1.png",
    "player_jump.png": "v2pc1_3.png",
    "player_fall.png": "v2pc1_4.png",
    "player_atk1.png": "v2pc1_5.png",
    "player_atk2.png": "v2pc1_6.png",
    "player_hurt.png": "v2pc2_0.png",
    "player_dead.png": "v2pc2_1.png",
    "player_air.png": "v2pc2_5.png",
    "player_interact.png": "v2pc2_4.png",
    # glitch yaratik / dusmanlar
    "glitch_creature.png": "v2gl1_0.png",
    "glitch_small.png": "v2en2_4.png",
    "villager_guard.png": "v2en2_0.png",
    "villager_peasant.png": "v2en2_2.png",
    "villager_scarecrow.png": "v2en3_10.png",
    # bg
    "bg_moon.png": "v2moon.png",
    "bg_mountains.png": "v2pano_1.png",
    "bg_mid.png": "v2pano_3.png",
    "bg_cherry.png": "v2na_2.png",
    "bg_falls.png": "v2pano_5.png",
    "bg_cloud.png": "v2cl2_0.png",
    "bg_lights.png": "v2lt2_5.png",
    # prop ai yollari (manifest'in bekledigi adlar)
    "j_torii.png": "v2td_5.png",
    "j_lantern_hang_0.png": "v2lt1_0.png",
    "j_stone_lamp.png": "v2dc2_1.png",
    "j_house_main.png": "v2ha_2.png",
    "j_fence_0.png": "v2hb_10.png",
    "j_plant_0.png": "v2nb_4.png",
    "j_plant_1.png": "v2nb_9.png",
    "j_plant_2.png": "v2nb_18.png",
    "j_plant_3.png": "v2nb_21.png",
    # fx
    "fx_slash_0.png": "v2vfx1_24.png",
    "fx_slash_1.png": "v2vfx1_2.png",
    "fx_slash_2.png": "v2vfx1_19.png",
    "fx_impact.png": "v2vfx2_1.png",
    "fx_petal.png": "v2pt_4.png",
    "fx_ember.png": "v2pt_0.png",
    "fx_arc.png": "v2pc2_7.png",
    # sapka (glitch yaratik hikaye prop'u)
    "straw_hat.png": "v2hat.png",
}

GEN_COPY = {
    # generated/ koku — eski slicer dosya adlari
    "edge_grass.png": "v2ta_0.png",
    "edge_dirt.png": "v2ta_1.png",
    "wall_tile.png": "v2ta_3.png",
    "ground_face.png": "v2tb_0.png",
    "pf_block.png": "v2td_0.png",
    "pf_corner.png": "v2td_1.png",
    "pf_plateau.png": "v2td_2.png",
    "pf_ledge.png": "v2td_6.png",
    "pf_slab.png": "v2tb_7.png",
    "pf_grass_wide.png": "v2ta_0.png",
    "pf_moss.png": "v2wb_5.png",
    "cave_bricks.png": "v2tb_4.png",
    "cave_rock.png": "v2wb_5.png",
    "cave_crystal.png": "v2pt_2.png",
    "cave_shroom.png": "v2nb_6.png",
    "deco_gate.png": "v2hb_15.png",
    "deco_lantern.png": "v2dc_0.png",
    "deco_barrier.png": "v2hb_10.png",
    "market_stall.png": "v2ha_5.png",
    "sign.png": "v2ob2_11.png",
    "well.png": "v2ob2_2.png",
    "wagon.png": "v2ob2_8.png",
    "barrel.png": "v2fu2_10.png",
    "crate.png": "v2fu2_0.png",
    "crate_stack.png": "v2fu2_1.png",
    "sack.png": "v2fu2_5.png",
    "bush_small.png": "v2nb_14.png",
    "deadtree_1.png": "v2na_9.png",
    "deadtree_2.png": "v2na_10.png",
    "deadtree_3.png": "v2na_11.png",
    "statue.png": "v2dc2_8.png",
    "rooster.png": "boss_cluck_move_0.png",
    "tree_green.png": "v2na_8.png",
}

# ---------------------------------------------------------------------------
# 2) MANIFEST DEGISIKLIKLERI
# ---------------------------------------------------------------------------
A = "generated/ai/"
G = "generated/"


def upsert(assets, lid, entry):
    assets[lid] = entry


def main() -> int:
    n = 0
    for dst, src in AI_COPY.items():
        s = os.path.join(AI, src)
        if not os.path.exists(s):
            print("EKSIK:", src)
            continue
        shutil.copyfile(s, os.path.join(AI, dst))
        n += 1
    for dst, src in GEN_COPY.items():
        s = os.path.join(AI, src)
        if not os.path.exists(s):
            print("EKSIK:", src)
            continue
        shutil.copyfile(s, os.path.join(GEN, dst))
        n += 1

    # tavuk turevleri — kumes hayvanlari kucuk cluck kareleri
    for dst, src in {"chicken.png": "boss_cluck_move_0.png",
                     "goose.png": "boss_cluck_move_1.png",
                     "duck.png": "boss_cluck_move_2.png",
                     "peacock.png": "boss_cluck_move_3.png"}.items():
        s = os.path.join(AI, src)
        if os.path.exists(s):
            shutil.copyfile(s, os.path.join(GEN, dst))
            n += 1
    # glitchb animlari
    for i, src in enumerate(["v2en2_4.png", "v2en2_5.png",
                             "v2en3_8.png", "v2en3_9.png"]):
        s = os.path.join(AI, src)
        if os.path.exists(s):
            shutil.copyfile(s, os.path.join(AI, "glitchb_%d.png" % i))
            n += 1

    # --- uretilmis kompozit katmanlar ---
    os.makedirs(AI, exist_ok=True)
    # gece gokyuzu gradyan + yildiz + tek ay (1440 genislikte tekerrur basina bir ay)
    import random
    random.seed(7)
    sky = Image.new("RGBA", (1440, 270), (0, 0, 0, 0))
    d = ImageDraw.Draw(sky)
    for y in range(270):
        t = y / 270.0
        d.line([0, y, 1439, y],
               fill=(int(14 + 10 * t), int(18 + 8 * t), int(38 + 22 * t), 255))
    for _ in range(140):
        x, y = random.randrange(1440), random.randrange(190)
        r = random.choice([1, 1, 1, 2])
        b = random.randint(140, 230)
        d.rectangle([x, y, x + r - 1, y + r - 1], fill=(b, b, min(255, b + 20), 255))
    c = (400, 80)
    for r in range(40, 28, -2):
        d.ellipse([c[0] - r, c[1] - r, c[0] + r, c[1] + r], fill=(60, 70, 90, 22))
    d.ellipse([c[0] - 24, c[1] - 24, c[0] + 24, c[1] + 24], fill=(238, 222, 190, 255))
    d.ellipse([c[0] - 22, c[1] - 22, c[0] + 24, c[1] + 24], fill=(247, 233, 199, 255))
    for (x, y, r) in [(c[0] - 8, c[1] - 4, 5), (c[0] + 9, c[1] + 7, 4), (c[0] + 2, c[1] - 12, 3)]:
        d.ellipse([x - r, y - r, x + r, y + r], fill=(216, 199, 168, 255))
    d.ellipse([c[0] + 6, c[1] - 28, c[0] + 34, c[1]], fill=(18, 24, 44, 255))
    sky.save(os.path.join(AI, "bg_sky.png"))

    # magara tugla duvari (1050x270, ParallaxBg degil duz sprite olarak dose)
    w = Image.new("RGBA", (1050, 270), (0, 0, 0, 0))
    dw = ImageDraw.Draw(w)
    dw.rectangle([0, 0, 1049, 269], fill=(18, 15, 28, 255))
    for row in range(16):
        off = 20 if row % 2 else 0
        for col in range(-1, 28):
            x0 = col * 40 + off
            y0 = row * 18
            if x0 > 1049 or y0 > 269:
                break
            dw.rectangle([x0, y0, min(x0 + 38, 1049), y0 + 16], fill=(52, 44, 72, 255))
            dw.line([x0, y0, min(x0 + 38, 1049), y0], fill=(78, 68, 102, 255))
            if (row * 3 + col) % 7 == 0:
                dw.rectangle([x0 + 8, y0 + 7, x0 + 18, y0 + 9], fill=(95, 85, 125, 255))
    w.save(os.path.join(AI, "bg_cavewall.png"))

    # agac siluet seridi (parallax orta katman)
    strip = Image.new("RGBA", (512, 110), (0, 0, 0, 0))
    xs = 0
    for name in ["v2na_8.png", "v2na_6.png", "v2na_2.png", "v2na_0.png",
                 "v2na_8.png", "v2na_10.png"]:
        t = Image.open(os.path.join(AI, name))
        if t.height > 100:
            t = t.resize((int(t.width * 100 / t.height), 100), Image.NEAREST)
        strip.paste(t, (xs, 110 - t.height), t)
        xs += t.width - 8
        if xs > 480:
            break
    strip.save(os.path.join(AI, "bg_treeline.png"))

    # sis seridi — bulut parcalarini saydam zemine diz
    fog = Image.new("RGBA", (512, 64), (0, 0, 0, 0))
    xs = 0
    for name in ["v2cl2_0.png", "v2cl2_1.png", "v2cl2_2.png", "v2cl2_3.png"]:
        p = os.path.join(AI, name)
        if not os.path.exists(p):
            continue
        c = Image.open(p)
        fog.paste(c, (xs, 40 - c.height), c)
        xs += c.width + 60
    fog.save(os.path.join(AI, "bg_fogstrip.png"))

    # --- manifest ---
    man = json.load(open(MANIFEST, encoding="utf-8"))
    assets = man["assets"]

    # oyuncu yeni animlar
    upsert(assets, "player/samurai/attack",
           {"files": [A + "player_atk1.png", A + "player_atk2.png"],
            "pack": "AI Sheet", "fps": 12})
    upsert(assets, "player/samurai/dead",
           {"files": [A + "player_dead.png"], "pack": "AI Sheet"})
    upsert(assets, "player/samurai/air_attack",
           {"files": [A + "player_air.png"], "pack": "AI Sheet"})
    upsert(assets, "player/samurai/interact",
           {"files": [A + "player_interact.png"], "pack": "AI Sheet"})
    upsert(assets, "player/samurai/fall",
           {"files": [A + "player_fall.png"], "pack": "AI Sheet"})

    # rooster animasyon bankasi
    upsert(assets, "enemy/rooster/idle",
           {"files": [A + "boss_cluck_move_0.png"], "pack": "AI Sheet"})
    upsert(assets, "enemy/rooster/walk",
           {"files": [A + "boss_cluck_move_%d.png" % i for i in range(1, 5)],
            "pack": "AI Sheet", "fps": 10})
    upsert(assets, "enemy/rooster/attack",
           {"files": [A + "boss_cluck_attack_%d.png" % i for i in range(4)],
            "pack": "AI Sheet", "fps": 12})
    upsert(assets, "enemy/rooster/hurt",
           {"files": [A + "boss_cluck_move_2.png"], "pack": "AI Sheet"})
    upsert(assets, "enemy/rooster/die",
           {"files": [A + "boss_cluck_attack_%d.png" % i
                      for i in range(8, 12)],
            "pack": "AI Sheet", "fps": 8})

    # glitch + koylu
    upsert(assets, "enemy/glitch_creature",
           {"path": A + "glitch_creature.png", "pack": "AI Sheet"})
    upsert(assets, "enemy/glitch_small",
           {"path": A + "glitch_small.png", "pack": "AI Sheet"})
    upsert(assets, "npc/villager",
           {"path": A + "villager_peasant.png", "pack": "AI Sheet"})

    # repoint'ler — sheet art pack yollarinin yerine
    repoint = {
        "terrain/wall_tile": G + "wall_tile.png",
        "bg/cave_back": A + "bg_cavewall.png",
        "bg/dusk_sky": A + "bg_sky.png",
        "bg/j_mountains": A + "bg_layer_far.png",
        "bg/dusk_far": A + "bg_layer_far.png",
        "bg/dusk_mid": A + "bg_layer_mid.png",
        "bg/dusk_trees": A + "bg_layer_trees.png",
        "bg/j_trees": A + "bg_layer_trees.png",
        "bg/forest_far": A + "bg_layer_far.png",
        "bg/forest_mid": A + "bg_layer_mid.png",
        "bg/forest_near": A + "bg_layer_trees.png",
        "bg/forest_lights": A + "bg_layer_glow.png",
        "bg/cemetery_far": A + "bg_layer_far.png",
        "bg/cemetery_near": A + "bg_layer_cave.png",
        "terrain/ground_face": G + "ground_face.png",
        "prop/market_stall": G + "market_stall.png",
        "prop/sign": G + "sign.png",
        "prop/well": G + "well.png",
        "prop/wagon": G + "wagon.png",
        "prop/barrel": G + "barrel.png",
        "prop/crate": G + "crate.png",
        "prop/crate_stack": G + "crate_stack.png",
        "prop/sack": G + "sack.png",
        "prop/bush_small": G + "bush_small.png",
        "prop/deadtree_1": G + "deadtree_1.png",
        "prop/deadtree_2": G + "deadtree_2.png",
        "prop/deadtree_3": G + "deadtree_3.png",
        "prop/statue": G + "statue.png",
        "bg/dusk_sky": A + "bg_sky.png",
        "bg/dusk_far": A + "bg_mountains.png",
        "bg/dusk_mid": A + "bg_mid.png",
        "bg/dusk_trees": A + "bg_treeline.png",
        "bg/forest_sky": A + "bg_sky.png",
        "bg/forest_far": A + "bg_mountains.png",
        "bg/forest_mid": A + "bg_mid.png",
        "bg/forest_near": A + "bg_treeline.png",
        "bg/forest_lights": A + "bg_lights.png",
        "bg/cemetery_sky": A + "bg_sky.png",
        "bg/cemetery_far": A + "bg_mountains.png",
        "bg/cemetery_near": G + "cave_rock.png",
    }
    for lid, path in repoint.items():
        if lid in assets:
            assets[lid] = {"path": path, "pack": "AI Sheet"}

    # fx bankalari (frame-sheet yerine dosya listesi)
    upsert(assets, "fx/slash",
           {"files": [A + "fx_slash_0.png", A + "fx_slash_1.png",
                      A + "fx_slash_2.png"], "pack": "AI Sheet", "fps": 24})
    upsert(assets, "fx/slash_heavy",
           {"files": [A + "fx_slash_0.png", A + "fx_slash_1.png",
                      A + "fx_slash_2.png"], "pack": "AI Sheet", "fps": 24})
    upsert(assets, "fx/impact",
           {"files": [A + "fx_impact.png"], "pack": "AI Sheet"})
    upsert(assets, "fx/petal",
           {"files": [A + "fx_petal.png"], "pack": "AI Sheet"})
    upsert(assets, "fx/ember",
           {"files": [A + "fx_ember.png"], "pack": "AI Sheet"})
    upsert(assets, "prop/straw_hat",
           {"path": A + "straw_hat.png", "pack": "AI Sheet"})

    # ---- parallax katmanlari (build_parallax_layers.py ciktilari) ----
    for lid, path in {
        "bg/j_mountains": A + "bg_layer_far.png",
        "bg/dusk_far": A + "bg_layer_far.png",
        "bg/dusk_mid": A + "bg_layer_mid.png",
        "bg/dusk_trees": A + "bg_layer_trees.png",
        "bg/j_trees": A + "bg_layer_trees.png",
        "bg/forest_far": A + "bg_layer_far.png",
        "bg/forest_mid": A + "bg_layer_mid.png",
        "bg/forest_near": A + "bg_layer_trees.png",
        "bg/forest_lights": A + "bg_layer_glow.png",
        "bg/cemetery_far": A + "bg_layer_far.png",
        "bg/cemetery_near": A + "bg_layer_cave.png",
    }.items():
        assets[lid] = {"path": path, "pack": "AI Sheet"}

    # ---- NPC'ler (32rogues yerine sheet kesitleri) ----
    for lid, path in {
        "npc/peasant1": A + "villager_peasant.png",
        "npc/peasant2": A + "v2en3_1.png",
        "npc/peasant3": A + "villager_guard.png",
        "npc/monk": A + "v2en3_6.png",
        "npc/mage": A + "v2en3_10.png",
        "npc/farmer": A + "v2en2_2.png",
        "npc/prolog_hero": A + "player_idle.png",
        "npc/chicken": G + "chicken.png",
        "npc/goose": G + "goose.png",
        "npc/duck": G + "duck.png",
        "npc/peacock": G + "peacock.png",
    }.items():
        assets[lid] = {"path": path, "pack": "AI Sheet"}

    # ---- ch1 dusmanlari ----
    for lid, path in {
        "enemy/dummy": A + "villager_scarecrow.png",
        "enemy/villager": A + "villager_peasant.png",
        "enemy/villager_b": A + "v2en3_1.png",
        "enemy/villager_c": A + "v2en2_0.png",
        "enemy/guard": A + "v2en3_6.png",
        "enemy/mushroom": A + "v2dc2_12.png",
        "enemy/mushroom_mini": A + "v2nb_6.png",
        "enemy/slug": A + "glitch_small.png",
        "enemy/turtle": A + "glitch_small.png",
        "enemy/split_mushroom": A + "v2dc2_12.png",
        "enemy/ghost": A + "v2en3_8.png",
        "enemy/hellcat": A + "v2en2_5.png",
        "enemy/skeleton": A + "v2en3_10.png",
        "enemy/heavy_knight": A + "villager_guard.png",
        "prop/grave_1": A + "v2dc2_7.png",
        "prop/grave_2": A + "v2dc2_9.png",
        "prop/grave_3": A + "v2wb_4.png",
        "hazard/spike": A + "hazard_spike.png",
        "terrain/chain": A + "chain.png",
        "terrain/block": G + "pf_block.png",
        "prop/rest_point": A + "j_stone_lamp.png",
        "enemy/egg": A + "v2pt_6.png",
        "enemy/blood_spike": A + "hazard_spike.png",
        "enemy/battery": A + "v2pt_2.png",
        "enemy/missile": A + "v2vfx1_9.png",
        "enemy/projectile": A + "v2pt_2.png",
        "fx/pixel": A + "v2pt_2.png",
        "fx/shockwave": A + "fx_arc.png",
        "fx/spark": A + "v2lt2_6.png",
        "fx/bolt": A + "v2vfx1_19.png",
        "terrain/ch2_ground": G + "ground_face.png",
        "terrain/ch3_ground": G + "ground_face.png",
        "terrain/ch4_ground": G + "ground_face.png",
        "terrain/ch5_ground": G + "ground_face.png",
        "terrain/pipe": G + "cave_rock.png",
        "terrain/cracked": G + "edge_dirt.png",
        "terrain/flicker": G + "pf_slab.png",
        "terrain/ground": G + "ground_face.png",
        "prop/katana": A + "hud_katana.png",
        "ui/bar_frame": A + "bar_frame.png",
    }.items():
        assets[lid] = {"path": path, "pack": "AI Sheet"}

    json.dump(man, open(MANIFEST, "w", encoding="utf-8"),
              ensure_ascii=False, indent=2)
    print("%d kopya + manifest guncellendi" % n)
    return 0


if __name__ == "__main__":
    sys.exit(main())
