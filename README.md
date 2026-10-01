# Samsara Glitch (Honor Meselesi)

2D aksiyon-platform / meta-anlatı oyunu — **Godot 4.7 + GDScript**.
16-bit piksel sanatı, CRT glitch ve VHS bozulma efektleri,
neon-geleneksel hibrit estetik. Tamamen dilsiz anlatım.

Emekli bir samuray, CRT televizyonundan gerçekliğe sızan dijital bir
varlığa hasır şapkasını kaptırır ve boyutlar arası bir kovalamacaya
girer. Temel mekanik: yenilen boss'ların formuna bürünme
("Morfik Yankı / Soul-Shifter").

## Dokümanlar

- `docs/DEVIN_PLAN.md` — **geliştirme planı ve teknik kararlar (buradan başla)**
- `docs/SENARYO.md` — kanonik senaryo
- `docs/Honor meselesi.docx` / `.pdf` — eski taslak treatment
- `ASSETS.md` — yerel asset paketi envanteri (~8 GB, repoda değil)
- `CREDITS.md` — asset/lisans kredileri
- `assets_manifest.json` — mantıksal asset → `assets_external/` eşlemesi

## Geliştirme

- Motor: Godot 4.7.x (stable), GDScript. İç çözünürlük 480×270,
  `viewport` stretch + `integer` scale (piksel-mükemmel).
- Gerçek asset'ler `.gitignore`'lı `assets_external/` altında tutulur;
  eksik her asset için `AssetLoader` otomatik placeholder üretir.
- Test: GUT (`godot --headless -s addons/gut/gut_cmdln.gd -gdir=res://tests -gexit`)
- CI: GitHub Actions — import + GUT + Linux/Windows export.
- Kilometre taşları planın 5. bölümünde; her biri ayrı branch + PR.

## Kontroller (varsayılan)

| Eylem | Klavye | Gamepad |
|---|---|---|
| Hareket | A/D veya ok | Sol çubuk / D-pad |
| Zıpla | Space | A |
| Saldırı | J | X |
| Parry | K | RB |
| Dash | L / Shift | B |
| Odak (iyileşme) | F | Y |
| Form önceki/sonraki | Q / E | LB / Sağ çubuk → |
| Duraklat | Esc | Start |
