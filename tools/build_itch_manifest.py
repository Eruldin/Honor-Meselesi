#!/usr/bin/env python3
"""itch.io paketlerinden assets_manifest.json girdileri uretir.

Calistir: python tools/build_itch_manifest.py
- Sheet'ler icin {"path","frame":[w,h],"fps"} girdisi yeterli (AssetLoader
  satir x sutun dilimler).
- Kare-basina dosya klasorleri icin {"files":[...]} listesi kurulur.
- GIF paketleri (beast-man) PNG'ye, buyuk VFX kareleri 96px'e donusturulup
  assets_external/generated/itch/ altina yazilir.
Idempotent: ayni anahtarlari tekrar yazar, baska girdilere dokunmaz.
"""
import io, json, os, re
from PIL import Image

ROOT = os.path.join(os.path.dirname(__file__), '..')
EXT = 'itch/extracted'
GEN = 'generated/itch'
MANIFEST = os.path.join(ROOT, 'assets_manifest.json')

ITCH = os.path.join(ROOT, 'assets_external', EXT)
GEN_ABS = os.path.join(ROOT, 'assets_external', GEN)


def seq_files(pack_dir, pattern, start=1):
    """Klasordeki <ad>_<N>.png karelerini sirali goreli yol listesi yap."""
    items = []
    for f in sorted(os.listdir(os.path.join(ITCH, pack_dir))):
        m = re.match(pattern, f)
        if m:
            items.append((int(m.group(1)), f))
    items.sort()
    return [f'{EXT}/{pack_dir}/{f}' for _, f in items]


def files_entry(pack_dir, pattern):
    fs = seq_files(pack_dir, pattern)
    return {'files': fs, 'fps': 9, 'pack': 'itch'} if fs else None


def strip(path, w, h, fps=8):
    return {'path': f'{EXT}/{path}', 'frame': [w, h], 'fps': fps, 'pack': 'itch'}


def gif_to_files(src_gif, out_prefix, box=64):
    """GIF karelerini PNG'ye acip files listesi dondurur."""
    im = Image.open(os.path.join(ITCH, src_gif))
    out = []
    os.makedirs(os.path.join(GEN_ABS, os.path.dirname(out_prefix)), exist_ok=True)
    i = 0
    try:
        while True:
            fr = im.convert('RGBA')
            p = f'{out_prefix}_{i}.png'
            fr.save(os.path.join(GEN_ABS, p))
            out.append(f'{GEN}/{p}')
            i += 1
            im.seek(i)
    except EOFError:
        pass
    return {'files': out, 'fps': 8, 'pack': 'itch'} if out else None


def downscale_frames(src_dir, pattern, out_prefix, size=96, fps=12):
    """Buyuk kare dizisini kucultup files listesi yap."""
    files = seq_files(src_dir, pattern)
    out = []
    os.makedirs(os.path.join(GEN_ABS, os.path.dirname(out_prefix)), exist_ok=True)
    for i, rel in enumerate(files):
        im = Image.open(os.path.join(ROOT, 'assets_external', rel)).convert('RGBA')
        im.thumbnail((size, size), Image.LANCZOS)
        p = f'{out_prefix}_{i}.png'
        im.save(os.path.join(GEN_ABS, p))
        out.append(f'{GEN}/{p}')
    return {'files': out, 'fps': fps, 'pack': 'itch'} if out else None


def build():
    m = json.load(io.open(MANIFEST, encoding='utf-8'))
    A = m['assets']
    up = {}

    PC = 'plague-crow/Crow Animations'
    up['enemy/crow/idle']   = strip(f'{PC}/crow_idle.png', 64, 64)
    up['enemy/crow/walk']   = strip(f'{PC}/crow_walk.png', 64, 64)
    up['enemy/crow/attack'] = strip(f'{PC}/crow_attack.png', 64, 64)
    up['enemy/crow/hurt']   = strip(f'{PC}/crow_damage.png', 64, 64)
    up['enemy/crow/die']    = strip(f'{PC}/crow_death1.png', 64, 64)
    up['enemy/crow/jump']   = strip(f'{PC}/crow_jump.png', 64, 64)

    DR = 'duskborne-enemy-2/DuskBorne-Druid/SpriteSheet'
    up['enemy/druid/idle']   = strip(f'{DR}/DruidIdle001-Sheet.png', 128, 128)
    up['enemy/druid/walk']   = strip(f'{DR}/DruidWalk001-Sheet.png', 128, 128)
    up['enemy/druid/attack'] = strip(f'{DR}/DruidBasicAtk1-Sheet.png', 128, 128)
    up['enemy/druid/hurt']   = strip(f'{DR}/DruidHurt001-Sheet.png', 128, 128)
    up['enemy/druid/die']    = strip(f'{DR}/DruidDeath001-Sheet.png', 128, 128)
    up['fx/druid_earth']     = strip(f'{DR}/DruidEarthVFX001-Sheet.png', 128, 128, 10)

    IA = 'imp-axe-demon-pixel-art-character/imp_axe_demon/demon_axe_red'
    for anim, pat in [('idle', r'ready_(\d+)\.png'), ('walk', r'walk_(\d+)\.png'),
                      ('attack', r'attack1_(\d+)\.png'), ('hurt', r'hit_(\d+)\.png'),
                      ('die', r'dead_(\d+)\.png'), ('jump', r'jump_(\d+)\.png')]:
        e = files_entry(IA, pat)
        if e: up[f'enemy/demon_axe/{anim}'] = e
    IR = 'imp-axe-demon-pixel-art-character/imp_axe_demon/imp_red'
    for anim, pat in [('idle', r'ready_(\d+)\.png'), ('walk', r'walk_(\d+)\.png'),
                      ('attack', r'attack1_(\d+)\.png'), ('hurt', r'hit_(\d+)\.png'),
                      ('die', r'fall_back_(\d+)\.png'), ('jump', r'jump_(\d+)\.png')]:
        e = files_entry(IR, pat)
        if e: up[f'enemy/imp_red/{anim}'] = e

    EX = 'undead-executioner/Undead executioner puppet/png'
    up['enemy/executioner/idle']   = strip(f'{EX}/idle.png', 100, 100, 6)
    up['enemy/executioner/walk']   = strip(f'{EX}/idle2.png', 200, 200, 4)
    up['enemy/executioner/attack'] = strip(f'{EX}/attacking.png', 100, 100, 10)
    up['enemy/executioner/die']    = strip(f'{EX}/death.png', 100, 200, 8)
    up['enemy/executioner/hurt']   = strip(f'{EX}/idle2.png', 200, 200, 4)
    up['enemy/executioner/summon'] = strip(f'{EX}/summon.png', 200, 200, 6)
    up['enemy/summonling/idle']    = strip(f'{EX}/summonIdle.png', 50, 50, 6)
    up['enemy/summonling/die']     = strip(f'{EX}/summonDeath.png', 50, 50, 8)
    up['enemy/summonling/appear']  = strip(f'{EX}/summonAppear.png', 50, 50, 8)

    BT = 'dark-fantasy-enemies-asset-pack/DarkFantasyEnemies_FREE/Bat/Bat without VFX'
    up['enemy/bat/idle']   = strip(f'{BT}/Bat-IdleFly.png', 64, 64, 9)
    up['enemy/bat/walk']   = strip(f'{BT}/Bat-Run.png', 64, 64, 9)
    up['enemy/bat/attack'] = strip(f'{BT}/Bat-Attack1.png', 64, 64, 10)
    up['enemy/bat/hurt']   = strip(f'{BT}/Bat-Hurt.png', 64, 64, 8)
    up['enemy/bat/die']    = strip(f'{BT}/Bat-Die.png', 64, 64, 8)
    up['enemy/bat/sleep']  = strip(f'{BT}/Bat-Sleep.png', 64, 64, 3)
    up['enemy/bat/wake']   = strip(f'{BT}/Bat-WakeUp.png', 64, 64, 10)

    DC = 'dark-character-2/dark_character_2'
    up['enemy/dark_character/walk']  = strip(f'{DC}/walk/walk.png', 128, 128, 8)
    up['enemy/dark_character/idle']  = strip(f'{DC}/walk/walk.png', 1152, 128, 1)
    up['enemy/dark_character/attack']= files_entry(f'{DC}/attack', r'attack(\d+)\.png')
    up['enemy/dark_character/hurt']  = files_entry(f'{DC}/backstep', r'backstep(\d+)\.png')
    up['enemy/dark_character/die']   = files_entry(f'{DC}/death', r'death(\d+)\.png')

    AW = 'axe-warrior/Blond'
    for anim, d in [('idle', 'Idle'), ('walk', 'Run'), ('attack', 'Attack'),
                    ('hurt', 'Hurt'), ('die', 'Death'), ('jump', 'Jump')]:
        e = files_entry(f'{AW}/{d}', r'[A-Za-z]+(\d+)\.png')
        if e: up[f'enemy/axe_warrior/{anim}'] = e
    up['enemy/axe_warrior/portrait'] = {'path': f'{EXT}/{AW}/Portrait.png', 'pack': 'itch'}

    OR = 'orius/Orius Asset Pack/Enemies/Red Soldier'
    for i in (1, 2, 3, 4):
        S = f'{OR}/Soldier {i}'
        up[f'enemy/soldier{i}/idle']  = strip(f'{S}/Soldier {i} Walking-Sheet.png', 288, 32, 1)
        up[f'enemy/soldier{i}/walk']  = strip(f'{S}/Soldier {i} Walking-Sheet.png', 32, 32, 8)
        up[f'enemy/soldier{i}/run']   = strip(f'{S}/Soldier {i} Running-Sheet.png', 32, 32, 10)
        up[f'enemy/soldier{i}/attack']= strip(f'{S}/Soldier {i} Shoot-Sheet.png', 32, 32, 10)
        up[f'enemy/soldier{i}/die']   = strip(f'{S}/Soldier {i} Death-Sheet.png', 32, 32, 10)

    BM = 'beast-man'
    for anim, gif in [('idle', 'BeastManSmall_Idle'), ('walk', 'BeastManSmall_Run'),
                      ('run', 'BeastManSmall_Run'), ('jump', 'BeastManSmall_JumpStart'),
                      ('fall', 'BeastManSmall_JumpForLoop'), ('hurt', 'BeastManSmall_JumpVerUp'),
                      ('die', 'BeastManSmall_Sit'), ('roll', 'BeastManSmall_RollFront'),
                      ('slide', 'BeastManSmall_WallSlideLoop'), ('cling', 'BeastManSmall_WallCling'),
                      ('stop', 'BeastManSmall_StopFront'), ('turn', 'BeastManSmall_Turn')]:
        e = gif_to_files(f'{BM}/{gif}.gif', f'beast_man/{anim}')
        if e: up[f'enemy/beast_man/{anim}'] = e

    LS = 'legacy-vania-long-sword'
    up['enemy/long_sword/walk']   = strip(f'{LS}/long-sword-walk_strip4.png', 64, 48, 8)
    up['enemy/long_sword/idle']   = strip(f'{LS}/long-sword-walk_strip4.png', 64, 48, 4)
    up['enemy/long_sword/attack'] = strip(f'{LS}/long-sword-attack_strip3.png', 64, 48, 10)
    up['enemy/long_sword/hurt']   = strip(f'{LS}/long-sword-walk_strip4.png', 64, 48, 6)
    up['enemy/long_sword/die']    = strip(f'{LS}/long-sword-attack_strip3.png', 64, 48, 6)

    AC = 'parallax-backgrounds-caves'
    for i in range(8):
        up[f'bg/cave_px_{i}'] = {'path': f'{EXT}/{AC}/{i}.png', 'pack': 'itch'}

    TG = 'taiga-asset-pack/Taiga-Asset-Pack_v2_vnitti/PNG'
    up['bg/taiga_sky']     = {'path': f'{EXT}/{TG}/Background.png', 'pack': 'itch'}
    up['bg/taiga_mid']     = {'path': f'{EXT}/{TG}/Middleground.png', 'pack': 'itch'}
    up['bg/taiga_ext_blue']= {'path': f'{EXT}/{TG}/Extension_blue.png', 'pack': 'itch'}
    up['bg/taiga_ext_green']={'path': f'{EXT}/{TG}/Extension_green.png', 'pack': 'itch'}
    up['prop/taiga_props'] = {'path': f'{EXT}/{TG}/Props.png', 'pack': 'itch'}
    up['terrain/taiga_tiles']={'path': f'{EXT}/{TG}/Tileset.png', 'pack': 'itch'}

    BC = '2d-browncave-assets/Assets 1024 Cave'
    up['prop/cave_rocks_big']   = {'path': f'{EXT}/{BC}/Cave - BigRocks1.png', 'pack': 'itch'}
    up['prop/cave_floor']       = {'path': f'{EXT}/{BC}/Cave - Floor.png', 'pack': 'itch'}
    up['prop/cave_platforms']   = {'path': f'{EXT}/{BC}/Cave - Platforms.png', 'pack': 'itch'}
    up['prop/cave_rocks_comb']  = {'path': f'{EXT}/{BC}/Cave - RockCombinations1.png', 'pack': 'itch'}
    up['prop/cave_rocks_small'] = {'path': f'{EXT}/{BC}/Cave - SmallRocks.png', 'pack': 'itch'}

    GV = 'metroidvania-demo-godot/Metroidvania/Sprites/Gothicvania/Background'
    up['bg/gothic_castle']       = {'path': f'{EXT}/{GV}/CastleParralax/gothic-castle-background.png', 'pack': 'itch'}
    up['bg/cemetery_sky']        = {'path': f'{EXT}/{GV}/Cemetery/background.png', 'pack': 'itch'}
    up['bg/cemetery_yard']       = {'path': f'{EXT}/{GV}/Cemetery/graveyard.png', 'pack': 'itch'}
    up['bg/cemetery_mountains']  = {'path': f'{EXT}/{GV}/Cemetery/mountains.png', 'pack': 'itch'}
    up['bg/church']              = {'path': f'{EXT}/{GV}/ChurchStage/churchbackgrounds.png', 'pack': 'itch'}

    PP = 'pixel-portal-fx-pack-free-2d-animated-portal-asset/Animated Portal'
    up['fx/portal']       = strip(f'{PP}/Portal-Spinning.png', 64, 64, 12)
    up['fx/portal_dark']  = strip(f'{PP}/Dark Portal-Spinning.png', 64, 64, 12)
    up['fx/portal_grey']  = strip(f'{PP}/Greyscale Portal-Spinning.png', 64, 64, 12)

    HI = 'top-down-retro-interior'
    up['prop/house_doors']   = {'path': f'{EXT}/{HI}/TopDownHouse_DoorsAndWindows.png', 'pack': 'itch'}
    up['prop/house_floors']  = {'path': f'{EXT}/{HI}/TopDownHouse_FloorsAndWalls.png', 'pack': 'itch'}
    up['prop/house_floors_o']= {'path': f'{EXT}/{HI}/TopDownHouse_FloorsAndWalls_OpenDoors.png', 'pack': 'itch'}
    up['prop/house_furn1']   = {'path': f'{EXT}/{HI}/TopDownHouse_FurnitureState1.png', 'pack': 'itch'}
    up['prop/house_furn2']   = {'path': f'{EXT}/{HI}/TopDownHouse_FurnitureState2.png', 'pack': 'itch'}
    up['prop/house_items']   = {'path': f'{EXT}/{HI}/TopDownHouse_SmallItems.png', 'pack': 'itch'}

    VF = 'vfx-free-pack'
    up['fx/bighit']     = downscale_frames(f'{VF}/Effect_BigHit/30fps/Frames/Effect_BigHit_1',
                                         r'Effect_BigHit_1_(\d+)\.png', 'vfx/bighit', 96, 14)
    up['fx/smallhit']   = downscale_frames(f'{VF}/Effect_SmallHit/30fps/Frames/Effect_SmallHit_1',
                                         r'Effect_SmallHit_1_(\d+)\.png', 'vfx/smallhit', 96, 14)
    up['fx/eldenring']  = downscale_frames(f'{VF}/Effect_EldenRing/30fps/Frames/Effect_EldenRing_1',
                                           r'Effect_EldenRing_1_(\d+)\.png', 'vfx/eldenring', 96, 12)
    up['fx/puff']       = downscale_frames(f'{VF}/Effect_PuffAndStars/30fps/Frames/Effect_PuffAndStars_1',
                                           r'Effect_PuffAndStars_1_(\d+)\.png', 'vfx/puff', 64, 16)
    up['fx/explosion']  = downscale_frames(f'{VF}/Effect_Explosion/30fps/Frames/Effect_Explosion_1',
                                           r'Effect_Explosion_1_(\d+)\.png', 'vfx/explosion', 96, 14)

    missing = []
    for k, v in up.items():
        if v is None:
            missing.append(k)
            continue
        A[k] = v
    print(f'{len(up)} girdi islendi, {len(missing)} eksik: {missing}')

    io.open(MANIFEST, 'w', encoding='utf-8').write(
        json.dumps(m, ensure_ascii=False, indent=1))


if __name__ == '__main__':
    build()
