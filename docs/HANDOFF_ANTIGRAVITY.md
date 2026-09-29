# HONOR MESELESI — Gelistirici El Devirme Dosyasi

> Bu dosya projeyi devralan AI asistan/gelistirici icindir.
> Degisiklik yapmaya baslamadan once tamamini oku.
> Tasarim dokumani: `docs/SENARYO.md` — once onu oku.

## Proje kimlik karti

| | |
|---|---|
| Motor / dil | Godot 4.7.2 · GDScript |
| Repo | github.com/Eruldin/Honor-Meselesi |
| Ana sahne | `res://src/ui/Title.tscn` |
| Viewport | 480x270 · window 1440x810 · stretch = viewport/integer |
| Test catisi | GUT 9.6.1 (acilista uyari cikarsa "Devam Et" — zararsiz) |
| Durum | Prolog + Bolum 1-7 + final oynanabilir · 83/83 test yesil |

## EN KRITIK KURALLAR

1. **Asla kodla gorsel cizme.** HUD, level design, dekor, dusman, efekt —
   hepsi `assets_external/` altindaki gercek asset dosyalarindan gelir.
   Uygun asset yoksa once `assets_external/` ve kaynak paketleri tara;
   gerekirse `tools/build_ch1_assets.py` ornegini takip edip atlaslardan
   crop uret → `generated/` altina yaz.

2. **Glitch/CRT sadece senaryo anlarinda.** `PostFX` baseline `master` her
   zaman 0. Cutscene'de kullan: `FX.glitch(guc, sure)`. `Settings.fx_intensity`
   puls gucluluk carpanidir — ortam efekti icin kullanma.

3. **Her degisiklikten sonra test kos** (asagidaki komutlar) — 83 test
   yesil kalmali.

4. `assets_external/` gitignore'da ve ~343MB — **asla silme/tasima**.

5. Proje adi **Honor Meselesi**. (Samsara Glitch degil.)

## Asset sistemi

- `assets_manifest.json` → mantiksal id → dosya yolu eslemesi
  (`enemy/rooster` → `generated/rooster.png` gibi)
- `AssetLoader` (autoload) PNG'yi import'suz diskten yukler
  (`Image.load_from_file`). OGG/MP3/WAV muzik de ayni.
- Animasyon konvansiyonu: `enemy/<key>/idle|walk|attack|hurt|die`
  manifest girdileri → `EnemyBase` otomatik SpriteFrames bankasi kurar.
- Yeni asset eklersen manifest'e girdi ekle; dosya adi path ile ayni olsun.

## Komutlar

```bash
G="C:/Users/PC/Desktop/Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64_console.exe"

"$G" --path . --import                    # parse/import kontrol
"$G" --path . -s addons/gut/gut_cmdln.gd -gdir=res://tests -gexit   # 83 test
"$G" --path . tools/ProbeCh1.tscn --probe=village|gate|arena        # hizli ekran gor.
```

Kayit araclari: `tools/record_ch1.gd` (uzun playtest kareleri),
`tools/probe_ch1.gd` (nokta goruntusu → %TEMP%/ch1_*.png).

## Yapi haritasi

- `src/player/samurai.gd` — durum makinesi (idle/run/jump/dash/attack/
  parry/pogo/hurt/dead/rest/transform/cutscene)
- `src/enemies/enemy_base.gd` — health/hurtbox/hitbox/anim bankasi/faz
- `src/enemies/boss_base.gd` — faz esikleri, defeated sinyali
- `src/levels/chN/chN.gd` — arazi/entity/fx/hud kurulumu
- `src/ui/hud_bars.gd` — `HudBars.make()` dokulu bar uretici
- `src/ui/pictogram.gd` — sessiz ikon balonlari (diyalog yok)
- `AudioManager.play_music(id)` — bolge bazli muzik (`ZONE_MUSIC` ornegi
  `ch1.gd`'de)
- `SaveSystem` + `GameState` flag'leri — Devam Et checkpoint'ten yukler

## Kontroller

Hareket `A/D` · Ziplama `Space` · Dash `Shift` · **Saldiri `J` veya sol
tik** · **Parry `K` veya sag tik** · Havada asagi+saldiri = pogo ·
Etkilesim `E`.

## Bilinen tuzaklar

- `Tween.from()` diye bir metod yok — baslangic degerini elle set et.
- `SpriteFrames.new()` hazir `default` animasyonla gelir — bos kontrolu
  kare sayisina gore yap.
- `AssetLoader.texture(id, size)` — `size` sadece placeholder icin;
  texture'i boyutlandirmaz.
- Atlas crop'larken koordinatlari programatik dogrula (opaklik kumeleri).
- Dekorlari `_add_deco_ground()` ile zemine oturt — hicbir sey havada
  durmasin.
- Testler sahne gecisini `auto_advance=false` ile kapatir.

## Lisans uyarsi

`CREDITS.md` guncel. **Dikkat:** `Modern tiles_Free` (prolog ic mekan) ve
`Post-apocalyptic` (Bolum 5) free surumleri **ticari satisa izin vermez**.
Oyun ucretsizse sorun yok; satilacaksa bu paketlerin ticari surumu alinmali.

## Onerilen siradaki isler

1. Bolum 1 ~1 saatlik akis: rota dallanmalari, mini-arena'lar, sirlar.
2. Bolum 2-7'ye ayni gorsel revizyon (gercek prop setleri, zemin dokusu).
3. Lord Cluck'a cok-kareli animasyon (`enemy/rooster/*` girdileri yeterli).
4. SFX zenginligi: mevcut paketlerden vurus/adim/UI sesleri.
5. Export paketleme (CI zaten artifact uretiyor).
