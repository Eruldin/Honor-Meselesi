# Honor Meselesi — Mevcut Sistem Raporu

> Yol haritası Aşama 1 çıktısı. Tarih: 2026-09-30. Kaynaklar:
> `Master_Gelistirme_Promptu`, `Devin_AI_Ultra_Master_Prompt`,
> `Epik_Senaryo_GDD`, boss/asset konsept sheet'leri (5 görsel),
> `docs/DEVIN_PLAN.md`, `docs/SENARYO.md`, kod tabanı taraması,
> GUT 84/84 + probe ekran görüntüleri.

## 1. Çalışan sistemler (korunacak)

| Sistem | Durum |
|---|---|
| Proje iskeleti (Godot 4.7.2, 480×270, viewport/integer) | Çalışıyor |
| InputSource soyutlaması (Player + AI) | Çalışıyor — final twist'i hazır |
| Samuray durum makinesi (13 durum, coyote/buffer/değişken zıplama) | Çalışıyor, testli |
| Savaş: hitbox/hurtbox, 3'lü kombo, parry penceresi, pogo | Çalışıyor, testli |
| Hit-stop / ekran sarsıntısı / PostFX (CRT, glitch, RGB) | Çalışıyor |
| Form sistemi (FormData .tres, 6 form) | Çalışıyor |
| BossBase faz sistemi + 7 bölüm boss'u | Çalışıyor, hepsi oynanabilir |
| SaveSystem + GameState + checkpoint | Çalışıyor |
| AudioManager (bölge müziği + SFX bus'ları) | Çalışıyor |
| CutscenePlayer + Pictogram (dilsiz anlatım) | Çalışıyor |
| GUT 84 test + CI (import/test/export) | Yeşil |
| AssetLoader + manifest (311 girdi) + placeholder fallback | Çalışıyor |

## 2. Kritik sorunlar / boşluklar

1. **Görsel katman asset'siz kaldığında tamamen placeholder.** Repoda
   `assets_external/` gitignore'lu; CI ve taze clone'lar renkli kutular
   görüyor. Gerçek paketler kullanıcının PC'sinde (~343 MB). Yeni AI
   konsept sheet'leri (bosses/env/scene/map) artık birincil görsel
   kaynak — `tools/slice_ai_assets.py` bu iş için var ama eski sheet
   düzenine yazılmış; yeni sheet'ler için spec'ler güncellenmeli.
2. **İsim kalıntıları:** `boot.gd` ve `ch7.gd`'de "SAMSARA" metni →
   bu PR'da temizlendi (`.tscn` uid'leri zararsız, bırakıldı).
3. **Bölüm 1 uzunluğu:** hedef ~1 saat; mevcut düz-hat ~5000px
   (köy → orman → mağara → geçit → arena). Konsept haritaya göre 6
   bölge: Kulübe → Bereketsiz Köy → Bambu Ormanı → Şelale Mağarası →
   Eski Tapınak → Unutulmuş Ahır. Rota dallanması, sır ve mini-arena
   sayısı yetersiz.
4. **Ayarlar ekranı:** tam ekran uyumu ve kontrol yeniden-atama eksik
   (master prompt listesi).
5. **Mouse ile saldırı/parry:** handoff'ta var görünüyor, doğrulanacak.
6. **Müzik:** bölge bazlı var ama giriş/keşif/savaş/boss/sakin
   katmanları ve dinamik geçiş zayıf.
7. **Boss rosterı çatallanması:** kod tabanı eski senaryoyu
   uyguluyor (Unit-0, Vlad, Tiran, Kül Muhafızı, Amalgam, Samuray
   finali). Yeni konsept sheet'i 9 boss tanımlıyor: Lord Cluck,
   Demir Kefaret, Gölge Keşiş, Yokluğun Bekçisi, Çürümüş Ağaç Rubu,
   Zamanın Sürgünü, Açlık, Yüzler, Şapkasız. Bölüm 1 (Lord Cluck)
   iki vizyonda da aynı → önce Bölüm 1, roster kararı sonra
   yansıtılacak.

## 3. Öncelik sırası (master prompt'a göre)

1. Oynanış hissi kusursuzlaştırma (tuning + hitbox + kamera).
2. Bölüm 1: konsept haritaya göre genişletme + gerçek asset'ler.
3. AI sheet'lerinden asset üretim hattı (slice v2) + manifest.
4. Atmosfer/müzik katmanları.
5. UI/UX: ana menü + tam ekran ayarlar.
6. Sonra: yeni roster'a göre bölüm revizyonları.

## 4. Yerel geliştirme notu

`assets_external/` bu makinede yok → AssetLoader placeholder'a düşer.
AI sheet'lerinden `generated/` altına dilimlenen görseller kod tarafından
manifest üzerinden bağlanır; paket asset'leri yokken placeholder kalır
(kullanıcı makinesinde gerçekleriyle açılır). Probe araçları artık
`res://.probe_out/` altına yazar (taşınabilir).
