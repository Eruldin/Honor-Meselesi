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


if __name__ == '__main__':
    urls = [u.strip() for u in sys.argv[1:] if u.strip().startswith('http')]
    for u in urls:
        try:
            download_pack(u)
        except Exception as e:
            print('FAIL', u, '->', e)
