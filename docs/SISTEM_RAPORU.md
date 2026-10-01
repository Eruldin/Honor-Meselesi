# Honor Meselesi — Mevcut Sistem Raporu

> **Durum güncellemesi (2026-10-01, PR #16–#310):** Aşama 1'deki
> tüm boşluklar kapandı — test sayısı 84 → 636 assert, tamamı yeşil.
> - §2.1 placeholder: 19 itch.io paketi + AI sheet'leri manifest'e
>   bağlandı; sahnede placeholder sprite kalmadı.
> - §2.3 Bölüm 1: ölü bahçe gauntlet, gizli odalar, mini-boss kapısı,
>   arena rest'iyle ~1 saatlik akışa ulaştı.
> - §2.4–2.6: tam ekran ayarlar + rebind (kalıcı), mouse doğrulandı,
>   dinamik müzik (combat layer + crossfade + rest teması) işliyor.
> - §2.7 roster: iki vizyon birleştirildi — mevcut boss'lar korunup
>   meta-anlatı (Ouroboros) ile harmanlandı.
> - Kapatılan hata aileleri: sahne-sınırı global sızıntısı (paused/
>   time_scale/ambiyans), post-boss soft-lock (cleared-exit portal +
>   ch7 epilog yeniden kurulumu), anim-kilit uyuşmazlığı, mermi-duvar
>   geçişi, i-frame/temas-hasarı uçları, test-izolasyon zehirlemesi.
> - #247–#277 ek kapanışlar: parry yansima (mermi geri donmuyordu +
>   itme yonu), anim-restart donmasi (walk/attack kare 0'da
>   kisiliyordu), Vlad faz-2 gozleri (CanvasLayer z_index eziyordu),
>   ch7 zorunlu secimde uyuyan boss'a bedava hasar (menu'de
>   creature.frozen), ayarlar atomik yazim + slider-drag kopmasi,
>   parry'lenen vampir isiriginin kanamasi, olu dusman hitbox'lari.
> - #278–#294 kapanışlar: DEVIN_PLAN milestone denetimi tamamlandı —
>   M8 (gargoyle/duman büyücüsü/selam/bölüm-bazlı hasar çarpanı), M9
>   (Amalgam form kapısı, melez düşmanlar, kod parçacıkları, yorgunluk
>   pozu, beyaz patlama), M10 (perspektif kayması, zorunlu seçim,
>   Ouroboros, epilog+jenerik) spec'e göre yerinde; M11 (asset
>   entegrasyonu, rebind, zorluk, perf, Steam Deck integer-scale,
>   itch.io export) doğrulandı. Ek: ilk açılışta ışığa duyarlılık
>   uyarısı (settings'de kalıcı), z-katmanı düzeltmeleri (piktogram/
>   hava/Vlad telegraph).
> - #295–#306 kapanışlar: M9 piksel fazında Amalgam süzülmesi (çift
>   zıplama zorunlu), dinlenmenin katana-çatlağı pozu, ch5 faz-2 alevli
>   kılıç kor tanecikleri, ch7 parry→kontra (M10), probe --rest, kamera
>   180° dönüşü + intro-skip soft-lock güvenliği, M10 epilog (şapka
>   iadesi + dikey glitch kesme + jenerik, EPILOG/PROLOG flag zinciri),
>   M6 karanlık fazda stereo yön ipucu + nabızlanan gözler, M5 arka pil
>   zayıf nokta (vuruş yönü kontrolü), M11 zorluk ayarı (KOLAY +1 /
>   ZOR -1 kalp, ayarlar menüsü + settings.json), probe epilog desteği.
> - #307–#310 kapanışlar: derin audit aileleri tamamlandı — form id
>   ölü dalı (şövalye zırhlı adım sesi), sahne-yolu kontrat testi
>   (koddaki tüm res://*.tscn literal'ları var olmalı), ses-id kontrat
>   testi (70+ `&"sfx|music|amb/…"` literal'ı manifest'te olmalı) —
>   Memory Chimera'nın `sfx/whoosh` cue'su manifest'te yokmuş, hiç
>   çalmıyordu. Uçtan-uca RecordCh1 (6272 kare) + RecordCh7 (955 kare,
>   zorunlu seçim ekranına kadar) kayıtlı regresyon temiz.
> - Açık kalanlar (insan doğrulaması gerek): ses hissi (bu makinede
>   WASAPI yok), parry hissi, boss yenilme deneyimi uçtan uca
>   (Amalgam form kapısı dahil), yorgunluk pozunun 480×270'de okunurluğu,
>   epilog akış hissi, kamera-flip hissi.

> Yol haritası Aşama 1 çıktısı (orijinal, 2026-09-30). Kaynaklar:
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
