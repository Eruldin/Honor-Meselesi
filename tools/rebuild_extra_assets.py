#!/usr/bin/env python3
"""DEFAULT_PACKS disinda kalan asset katmanlarini yeniden kurar.

Blueprint initialize adiminda calisir (idempotent):
  1) tools/prebaked/* seed'leri assets_external/ altina kopyalar
     (ai_sheets kaynak jpg'leri + elle uretilmis generated/ dilimleri).
  2) EXTRA_PACKS itch.io url'lerini indirir (itch_download.download_pack).
  3) EXTRACT tablosundaki zip'leri beklenen hedef dizinlere acar.
  4) slice_env_sheets.py + finalize_env_slices.py calistirir
     (ai_sheets jpg'lerinden oyuncu/env dilimleri -> generated/).

Zaten kuruluysa sentinel dosyaya bakip indirme+extraction'i atlar.
"""
import os
import shutil
import sys
import time
import zipfile

ROOT = os.path.join(os.path.dirname(__file__), '..')
os.chdir(ROOT)
sys.path.insert(0, os.path.join(ROOT, 'tools'))

EXT = os.path.join('assets_external')
PRE = os.path.join('tools', 'prebaked')

# itch.io sayfa url'i -> (zip adi icerir, hedef, sentinel)
EXTRA_PACKS = [
    ('https://ansimuz.itch.io/warped-city',
     ('warped city files', 'env/warped', 'env/warped/warped city files/Assets/ENVIRONMENT/background/skyline-a.png')),
    ('https://ansimuz.itch.io/gothicvania-town',
     ('.zip', 'env/gothic_town', 'env/gothic_town/GothicVania-town-files/PNG/environment/layers/tileset.png')),
    ('https://ansimuz.itch.io/sunnyland-winter-forest',
     ('winter forest files', 'env/sunnyland_winter', 'env/sunnyland_winter/sunnyland winter forest files/ENVIRONMENT/sky.png')),
    ('https://ansimuz.itch.io/gothicvania-cemetery',
     ('.zip', 'env/gothic_cemetery', 'env/gothic_cemetery/gothicvania-cemetery-files/Assets/Phaser Demo/assets/environment/bg-moon.png')),
    ('https://ansimuz.itch.io/sunny-land-pixel-game-art',
     ('Sunny-land-files', 'env/sunnyland', 'env/sunnyland/Sunny-land-files/Assets/Characters/Foxy/atlas.png')),
    ('https://ansimuz.itch.io/sunnyland-enemies-extended-pack',
     ('Add On Files', 'env/sunnyland', 'env/sunnyland/Sunny land Add On Files/Assets/mushroom-spring/big version/spritesheet.png')),
    ('https://ansimuz.itch.io/sunnyland-forest',
     ('forest-files', 'env/forest', 'env/forest/Sunny-land-forest-files')),
    ('https://najjar320.itch.io/vista-parallax-backgrounds',
     ('.zip', 'itch/extracted/vista-parallax-backgrounds', 'itch/extracted/vista-parallax-backgrounds/vista-ten/flue/flue_0_sky.png')),
    ('https://sethbb.itch.io/32rogues',
     ('32rogues-0.5', 'sprites/rogues', 'sprites/rogues/32rogues/rogues.png')),
    ('https://zerie.itch.io/tiny-rpg-character-asset-pack-02',
     ('.zip', 'sprites/demon', 'sprites/demon/Tiny RPG Character Asset Pack 02 -Free Demon_A&Blood Monster_A/Characters(100x100 split)/Demon_A/Demon_A/Demon_A_Idle.png')),
    ('https://xzany.itch.io/samurai-2d-pixel-art',
     ('FREE_Samurai', 'sprites/samurai', 'sprites/samurai/FREE_Samurai 2D Pixel Art v1.2/Sprites/IDLE.png')),
    ('https://kasayaa.itch.io/kasayas-inventory-and-frames',
     ('Frames', 'sprites/kasaya', 'sprites/kasaya/Bars/1/HP.png')),
    ('https://limezu.itch.io/moderninteriors',
     ('.zip', 'env/interiors', 'env/interiors/Modern tiles_Free/Interiors_free/16x16/Interiors_free_16x16.png')),
    ('https://0x72.itch.io/dungeontileset-ii',
     ('0x72_DungeonTilesetII', 'env/dungeon', 'env/dungeon/0x72_DungeonTilesetII_v1.7/0x72_DungeonTilesetII_v1.7.png')),
    ('https://penusbmic.itch.io/sci-fi-character-pack-12',
     ('Bot Wheel', 'sprites/bot', 'sprites/bot/Bot Wheel/move without FX.png')),
    ('https://xyezawr.itch.io/gif-free-pixel-effects-pack-5-blood-effects',
     ('NEw pack blood', 'vfx/blood', 'vfx/blood/NEw pack blood/1/1_0.png')),
    ('https://thelazystone.itch.io/post-apocalypse-pixel-art-asset-pack',
     ('.zip', 'env/postapoc', 'env/postapoc/Objects/Exhaust-pipe.png')),
    ('https://penzilla.itch.io/top-down-retro-interior',
     ('Top-Down_Retro_Interior', 'env/retro_interior', 'env/retro_interior/TopDownHouse_FloorsAndWalls.png')),
]


def seed_prebaked():
    n = 0
    for src_root, dst_root in ((os.path.join(PRE, 'ai_sheets'), 'assets_external/ai_sheets'),
                             (os.path.join(PRE, 'generated'), 'assets_external/generated')):
        if not os.path.isdir(src_root):
            continue
        for r, _ds, fs in os.walk(src_root):
            for f in fs:
                src = os.path.join(r, f)
                rel = os.path.relpath(src, src_root)
                dst = os.path.join(dst_root, rel)
                if not os.path.exists(dst):
                    os.makedirs(os.path.dirname(dst), exist_ok=True)
                    shutil.copy2(src, dst)
                    n += 1
    print('seed:', n, 'dosya')


def ensure_pack(url, match, dest, sentinel):
    if os.path.exists(os.path.join(EXT, sentinel)):
        print('SKIP (kurulu):', url)
        return
    from itch_download import download_pack
    slug, files = download_pack(url)
    for fn in files or []:
        base = os.path.basename(fn)
        if base.endswith('.zip') and match.lower() in base.lower():
            out = os.path.join(EXT, dest)
            os.makedirs(out, exist_ok=True)
            with zipfile.ZipFile(fn) as z:
                z.extractall(out)
            print('  extract:', base, '->', dest)
    if not os.path.exists(os.path.join(EXT, sentinel)):
        print('WARN sentinel yok:', sentinel)


def clean_appledouble():
    # macOS AppleDouble cop dosyalari (._*) — import'da WAV/PNG hatalari basar.
    n = 0
    for root, _dirs, files in os.walk(EXT):
        for f in files:
            if f.startswith('._'):
                os.remove(os.path.join(root, f))
                n += 1
    if n:
        print('appledouble temizlendi:', n)


def main():
    seed_prebaked()
    for url, (match, dest, sentinel) in EXTRA_PACKS:
        for attempt in range(3):
            try:
                ensure_pack(url, match, dest, sentinel)
                break
            except Exception as e:
                print('ERR', url, type(e).__name__, str(e)[:80])
                time.sleep(30)
    clean_appledouble()
    for script in ('tools/slice_env_sheets.py', 'tools/finalize_env_slices.py'):
        code = os.system(sys.executable + ' ' + script)
        print(script, '->', code)


if __name__ == '__main__':
    main()
