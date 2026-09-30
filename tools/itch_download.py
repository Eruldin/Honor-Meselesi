#!/usr/bin/env python3
"""itch.io ucretsiz asset paketi indirici.
Kullanim: python tools/itch_download.py <itch_url> [cikti_adi]
Her paketin tum upload'lari assets_external/itch/<slug>/ altina iner.
"""
import sys, os, re, json, urllib.request, urllib.parse, http.cookiejar

UA = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'
OUT_ROOT = 'assets_external/itch'


def _opener():
    cj = http.cookiejar.CookieJar()
    op = urllib.request.build_opener(urllib.request.HTTPCookieProcessor(cj))
    op.addheaders = [('User-Agent', UA)]
    return op


def _csrf(html):
    m = re.search(r'name="csrf_token" value="([^"]+)"', html)
    return m.group(1) if m else None


def download_pack(url, out_name=None):
    """Bir itch sayfasindaki tum upload dosyalarini indirir. (slug, [dosya yollari]) dondurur."""
    m = re.match(r'https?://([\w.-]+)\.itch\.io/([\w-]+)', url)
    if not m:
        print('SKIP (url parse):', url)
        return None, []
    host, slug = m.group(1), m.group(2)
    base = f'https://{host}.itch.io/{slug}'
    op = _opener()
    page = op.open(base).read().decode('utf-8', 'replace')
    csrf = _csrf(page)
    # dosya listesi sayfasi icin imzali url
    req = urllib.request.Request(
        base + '/download_url',
        data=urllib.parse.urlencode({'csrf_token': csrf}).encode(),
        headers={'X-Requested-With': 'XMLHttpRequest', 'Referer': base})
    dl_page = json.loads(op.open(req).read().decode())['url']
    h2 = op.open(dl_page).read().decode('utf-8', 'replace')
    csrf2 = _csrf(h2)
    uploads = re.findall(r'data-upload_id="(\d+)"', h2)
    if not uploads:
        print('SKIP (upload yok):', slug)
        return slug, []
    outdir = os.path.join(OUT_ROOT, out_name or slug)
    os.makedirs(outdir, exist_ok=True)
    saved = []
    for uid in dict.fromkeys(uploads):
        req = urllib.request.Request(
            f'{base}/file/{uid}',
            data=urllib.parse.urlencode({'csrf_token': csrf2, 'source': 'download'}).encode(),
            headers={'X-Requested-With': 'XMLHttpRequest', 'Referer': dl_page})
        signed = json.loads(op.open(req).read().decode())['url']
        fname = re.search(r'filename\*?=(?:UTF-8\'\')?"?([^";]+)"?', '')  # fallback asagida
        data = urllib.request.urlopen(urllib.request.Request(signed, headers={'User-Agent': UA}))
        cd = data.headers.get('content-disposition', '')
        fn = re.search(r'filename\*?=(?:UTF-8\'\')?"?([^";]+)"?', cd)
        fname = urllib.parse.unquote(fn.group(1)) if fn else f'{slug}_{uid}.zip'
        path = os.path.join(outdir, fname)
        with open(path, 'wb') as f:
            f.write(data.read())
        saved.append(path)
        print(f'  {slug}: {fname} ({os.path.getsize(path)//1024} KB)')
    return slug, saved


DEFAULT_PACKS = [
    'https://darkpixel-kronovi.itch.io/undead-executioner',
    'https://pedrovmvictor.itch.io/metroidvania-demo-godot',
    'https://maaot.itch.io/2d-browncave-assets',
    'https://monopixelart.itch.io/dark-fantasy-enemies-asset-pack',
    'https://vnitti.itch.io/taiga-asset-pack',
    'https://admurin.itch.io/parallax-backgrounds-caves',
    'https://gabry-corti.itch.io/plague-crow',
    'https://sanctumpixel.itch.io/imp-axe-demon-pixel-art-character',
    'https://didigameboy.itch.io/legacy-vania-long-sword',
    'https://kiyoz.itch.io/duskborne-enemy-2',
    'https://synapse-forge.itch.io/pixel-portal-fx-pack-free-2d-animated-portal-asset',
    'https://jik-a-4.itch.io/orius',
    'https://helianthus-games.itch.io/axe-warrior',
    'https://hoshin.itch.io/dark-character-2',
    'https://dead-pixelsz.itch.io/cap-guy-free',
    'https://dead-pixelsz.itch.io/machine-guy-free',
    'https://jasontomlee.itch.io/beast-man',
    'https://penzilla.itch.io/top-down-retro-interior',
    'https://codemanu.itch.io/vfx-free-pack',
    # Ses paketleri — muzik/ambiyans/sfx manifest girdileri bunlara isaret eder
    'https://xdeviruchi.itch.io/16-bit-fantasy-adventure-music-pack',
    'https://jdsherbert.itch.io/ambiences-music-pack',
    'https://ci.itch.io/400-sounds-pack',
    'https://nebula-audio.itch.io/character-footsteps-rock-grass-pack-1',
    'https://dillonbecker.itch.io/sdap',
]


def extract_all():
    """assets_external/itch/<slug>/ altindaki zip/rar'lari
    assets_external/itch/extracted/<slug>/ altina cikarir (bsdtar)."""
    import subprocess, shutil
    ext_root = os.path.join(OUT_ROOT, 'extracted')
    os.makedirs(ext_root, exist_ok=True)
    for slug_dir in sorted(os.listdir(OUT_ROOT)):
        src = os.path.join(OUT_ROOT, slug_dir)
        if not os.path.isdir(src) or slug_dir == 'extracted':
            continue
        out = os.path.join(ext_root, slug_dir)
        os.makedirs(out, exist_ok=True)
        for fn in os.listdir(src):
            p = os.path.join(src, fn)
            if fn.lower().endswith('.zip'):
                with __import__('zipfile').ZipFile(p) as z:
                    z.extractall(out)
            elif fn.lower().endswith(('.rar', '.7z')) and shutil.which('tar'):
                subprocess.run(['tar', '-xf', p, '-C', out], check=False)
        print('extracted', slug_dir)


if __name__ == '__main__':
    urls = [u.strip() for u in sys.argv[1:] if u.strip().startswith('http')]
    if not urls:
        urls = DEFAULT_PACKS
    for u in urls:
        try:
            download_pack(u)
        except Exception as e:
            print('FAIL', u, '->', e)
    extract_all()
