# SAMSARA GLITCH — Devin Geliştirme Planı

> Bu dosya Devin için yazılmış uygulama planıdır. Repo: https://github.com/Eruldin/Honor-Meselesi
> Plan, repoya `docs/DEVIN_PLAN.md` olarak eklenmeli ve Devin her oturumda önce bunu okumalıdır.

---

## 0. Devin'e ilk mesaj (kopyala-yapıştır)

```
Repo: https://github.com/Eruldin/Honor-Meselesi
Görev: "Samsara Glitch" adlı 2D aksiyon-platform oyununu Godot 4 ile geliştir.
1) docs/DEVIN_PLAN.md dosyasını baştan sona oku; tüm teknik kararlar ve kurallar orada.
2) docs/SENARYO.md ana senaryodur (kanonik kaynak). "Honor meselesi.pdf" eski bir taslaktır;
   ikisi çelişirse SENARYO.md geçerlidir.
3) Sadece M0 ve M1 kilometre taşlarını yap. Her kilometre taşı için ayrı branch + ayrı PR aç.
   PR açıklamasına kabul kriterlerinin her birini nasıl doğruladığını yaz ve oynanış GIF'i ekle.
4) Gerçek asset dosyalarını ASLA repoya commit etme (lisans nedeniyle, bkz. Bölüm 3).
   Şimdilik her şeyi placeholder (renkli kutu / basit piksel) grafiklerle yap.
5) Emin olmadığın tasarım kararlarında dur ve bana sor; oynanış sayılarını (hız, hasar vb.)
   config dosyasında tut ki sonra ayarlayabileyim.
```

Sonraki oturumlarda: `"docs/DEVIN_PLAN.md'yi oku, M2'yi yap."` şeklinde tek tek ilerletin.

---

## 1. Proje özeti

- **Tür:** 2D aksiyon-platform / meta-anlatı (Hollow Knight tarzı sıkı dövüş, Celeste tarzı akıcı hareket)
- **Anlatım:** Tamamen dilsiz. Diyalog kutusu, altyazı yok. Hikâye pantomim, abartılı mimik, piktogram baloncukları ve ses ile anlatılır.
- **Görsel:** 16-bit piksel sanatı, CRT tarama çizgisi, RGB kayması, VHS bozulma, neon + geleneksel Japon hibrit.
- **Temel mekanik — Morfik Yankı:** Boss'ları yenince onların formunu kazanma ve formlar arasında geçiş.
- **Yapı:** Prolog + 7 bölüm, hedef ~8–9 saat oynanış. Final: perspektif kayması (oyuncu aslında Glitch Yaratık'ı yönetiyordu) ve Ouroboros döngüsü.

### Kaynak dokümanlar ve öncelik
1. `docs/SENARYO.md` — **kanonik**. (Kullanıcının `message.txt` senaryosu; repoya bu isimle eklenecek.)
2. `Honor meselesi.pdf` — ton, dövüş felsefesi, sanat yönetimi için referans. Bölüm yapısı ve form listesi eskidir.

**Kanonik form listesi (SENARYO.md'den):**

| Form | Kaynak | Yetenek |
|---|---|---|
| Şövalye (geçici) | Bölüm 1, ilk şövalye | Ağır kılıç, kapalı kapıları kırma. Süreli. |
| Tavuk | Boss: Lord Cluck | Kanat çırparak süzülme, dar deliklerden geçme, küçük hitbox |
| Drone (bulmaca) | Bölüm 2, drone | Güvenlik terminallerine sızma, lazer bariyerini açma |
| Robot | Boss: Unit-0 | Ağır zırh, zemin kırma, knockback direnci |
| Gölge/Yarasa | Boss: Kont Vlad | Hasarsız kısa gölge dash'i (i-frame) |
| Piksel Sıçraması | Boss: Kızıl Tulumlu Tiran | Çift zıplama + blok kırma (kalıcı yetenek, form değil) |

---

## 2. Teknik kararlar

| Konu | Karar | Neden |
|---|---|---|
| Motor | **Godot 4.3+ (stable), GDScript** | Ücretsiz, 2D'de güçlü, asset envanterinde Godot sürümü olan paket var (Warped City Godot), CI'da headless çalışır |
| İç çözünürlük | **480×270** (16:9), tam sayı ölçekleme ile 1920×1080'e | Piksel-mükemmel görüntü; 4:3 daralma efekti için uygun |
| Stretch | `canvas_items` değil **`viewport`** modu, `integer` scale | Piksel bozulmasını önler |
| Fizik | 60 Hz sabit, `CharacterBody2D` | Deterministik hissiyat |
| Girdi | Klavye + gamepad, Input Map üzerinden; **InputSource soyutlaması** (bkz. 4.1) | Final bölümde samurayı yapay zekâ yönetecek |
| Test | **GUT** (Godot Unit Test) | Durum makinesi, hasar, parry penceresi testleri |
| CI | GitHub Actions: headless import + GUT testleri + Linux/Windows export | Her PR'da derleme garantisi |
| Kayıt | `user://save.json` (JSON, sürüm alanı ile) | Basit, okunabilir |

---

## 3. Asset stratejisi ve lisans — ÖNEMLİ

- Repo **herkese açık (public)**. `LICENSE.pdf`'deki JDSherbert lisansı ve çoğu itch.io paketi **ham asset dosyalarının yeniden dağıtılmasını yasaklıyor.** Bu yüzden:
  - Ham asset'ler (png, wav, ogg, tileset) **public repoya commit edilmez.**
  - Oyun kodu asset'leri `res://assets_external/` altından yükler; bu klasör `.gitignore`'da olur.
  - Asset yoksa oyun **otomatik olarak placeholder'a düşer** (renkli dikdörtgenler, basit şekiller). Böylece Devin asset'siz geliştirebilir, kullanıcı kendi bilgisayarında gerçek asset'lerle çalıştırır.
  - Alternatif: Repo private yapılırsa asset'ler Git LFS ile eklenebilir. Bu karar kullanıcıya aittir; Devin kendi başına asset eklemez.
- `assets_manifest.json`: Hangi mantıksal asset'in (ör. `player/samurai/idle`) hangi dış dosyaya karşılık geldiğini tanımlar. Kullanıcı sadece bu dosyayı düzenleyerek asset bağlar.
- `CREDITS.md`: Kullanılan her paketin yazarı ve lisansı (JDSherbert kredi zorunluluğu vb.). Jenerik ekranı bu dosyadan beslenir.
- **Parodi uyarısı:** "Kızıl Tulumlu Tiran" boss'u tanınmış bir karakterin parodisi. Tasarım özgün tutulmalı (farklı siluet, renk, isim); bilinen karakterin birebir görünümü, logosu veya müziği kullanılmaz.

---

## 4. Mimari

### Klasör yapısı
```
project.godot
docs/                  DEVIN_PLAN.md, SENARYO.md, TUNING.md
src/
  core/                GameState, SaveSystem, SceneRouter, AssetLoader, EventBus (autoload'lar)
  input/               InputSource.gd, PlayerInputSource.gd, AIInputSource.gd
  player/              Samurai.tscn, state_machine/, forms/
  combat/              Hitbox, Hurtbox, DamageInfo, ParrySystem, Health
  enemies/             EnemyBase + her düşman tipi
  bosses/              BossBase (fazlı) + her boss
  levels/              prolog/, ch1_village/, ch2_cyber/, ch3_gothic/, ch4_retro/, ch5_ashes/, ch6_glitch/, ch7_void/
  cutscene/            CutscenePlayer, Pictogram, ChoiceScreen
  fx/                  shaders (crt.gdshader, glitch.gdshader, chromatic.gdshader), ScreenShake, HitStop
  ui/                  HUD (can barı "fiziksel nesne" olarak da kullanılabilir), PauseMenu, Credits
  audio/               MusicDirector (katmanlı müzik), SFX bus'ları
config/                tuning.tres (tüm oynanış sayıları), forms/*.tres
assets_placeholder/    Devin'in ürettiği basit placeholder grafikler (commit edilebilir)
assets_external/       (gitignore) kullanıcının gerçek asset'leri
tests/                 GUT testleri
```

### 4.1 Girdi soyutlaması (kritik)
Samuray doğrudan `Input` çağırmaz; bir `InputSource` nesnesinden okur (`move_axis`, `jump_pressed`, `attack_pressed`, `parry_pressed`, `dash_pressed`, `form_next/prev`).
- `PlayerInputSource`: klavye/gamepad.
- `AIInputSource`: Bölüm 7'de samuray final boss olduğunda aynı sahne ve durum makinesi yapay zekâ ile sürülür. **Oyuncunun bütün oyun boyunca kullandığı hareket seti birebir ona karşı kullanılır** — senaryonun ana fikri bu.
- Aynı soyutlama `Tuş Karmaşası` efekti için de kullanılır (girdiyi ters çeviren dekoratör).

### 4.2 Oyuncu durum makinesi
Durumlar: `Idle, Run, Jump, Fall, WallSlide(opsiyonel), Attack(1-2-3 kombo), AirAttack, DownAttack(Pogo), Parry, Dash, Hurt, Dead, Rest(checkpoint), Transform, Cutscene`.
- Her form bir `FormData` Resource'u: hız, zıplama, hitbox boyutu, hasar, özel yetenek scripti, sprite seti. Form değişimi durumu değil veri setini değiştirir.
- Coyote time, jump buffer, değişken zıplama yüksekliği (Celeste hissi).

### 4.3 Dövüş
- `Hitbox`/`Hurtbox` Area2D + `DamageInfo` (hasar, knockback, `parryable: bool`, `pogoable: bool`, kaynak).
- **Parry:** Tuşa basıldıktan sonra kısa pencere (başlangıç ~120 ms, config'de). Başarılı parry → düşman sendeler, hit-stop, kıvılcım VFX. Kaçan parry → recovery süresi (Bölüm 5'ten itibaren ek ceza, config ile).
- **Pogo:** Havada aşağı saldırı `pogoable` bir şeye değerse yukarı sekme.
- **Kıvılcım ile görünürlük:** Bölüm 3 hayaletleri sadece parry kıvılcımı ışığında vurulabilir → `ParrySystem` bir `spark_emitted(position)` sinyali yayar.
- Hit-stop, ekran sarsıntısı, beyaz flash: `fx/` altında, tek satırla çağrılabilir.

### 4.4 Düşman ve boss
- `EnemyBase`: Health, Hurtbox, basit davranış ağacı veya durum makinesi, telegraph (saldırı öncesi işaret) zorunlu.
- **Bileşen tabanlı:** Silah, hareket ve saldırı bileşenleri ayrı düğümler. Bölüm 6'daki "bozulmuş melez düşmanlar" (siber silahlı köylü, kaplumbağa kabuğu atan kurtadam) mevcut bileşenlerin karıştırılmasıyla yapılır.
- `BossBase`: faz listesi (`PhaseData`: can eşiği, saldırı havuzu, hız çarpanı), faz geçiş sinematiği, arena kilidi, ölüm → çekirdek → form kazanma akışı.
- **Glitch Amalgam (Bölüm 6):** Önceki 4 boss'un saldırı bileşenlerini fazlara göre yeniden kullanır; kopya kod yazılmaz.

### 4.5 Sinematikler (dilsiz)
- `CutscenePlayer`: AnimationPlayer + basit bir komut listesi (`move`, `play_anim`, `pictogram`, `camera`, `wait`, `sfx`, `glitch`). Metin yok.
- `Pictogram`: Karakter başının üstünde ikon baloncuk (öfke damarı, soru işareti, kılıç, kırık kalp, glitchli soru işareti).
- Slapstick için: göz fırlama, çene düşme, kel kafa parlaması animasyonları ayrı sprite frame'leri olarak planlanır.

### 4.6 Görsel efekt ve meta sistemleri
- Post-process shader katmanı: CRT tarama çizgisi, eğrilik, RGB ayrılması, dikey kayma, bitcrush benzeri renk azaltma. Yoğunluk bölüme göre `EnvironmentProfile` ile ayarlanır.
- **MetaDirector** (Bölüm 7 için): 
  - HUD can barını söküp fırlatılabilir bir mermi nesnesine çevirme,
  - Oyun alanını 16:9'dan 4:3'e animasyonlu siyah bantlarla daraltma (gerçek pencereyi değil, SubViewport/kamera sınırlarını değiştir; gerçek pencere boyutu değiştirme opsiyonel ve ayarlardan kapatılabilir olmalı),
  - Kontrolleri ters çevirme (ekranda görsel işaretle adil hale getir),
  - Seçim ekranında "Şapkayı Samuraya Ver" butonunun glitchlenip imleci zorla diğer seçeneğe kaydırması.
- **Erişilebilirlik:** Ekran sarsıntısı, flaş ve glitch yoğunluğu için ayar kaydırıcıları; ışığa duyarlılık uyarısı açılışta.

### 4.7 Ses
- Bus'lar: Master / Music / SFX / Ambience / UI.
- `MusicDirector`: bölüm başına katmanlı müzik (sakin katman + savaş katmanı; düşman dalgasında çapraz geçiş), bant kayması/bitcrush efektleri AudioEffect ile.
- Placeholder aşamasında basit bip sesleri yeterli; gerçek müzik `assets_external`'dan.

---

## 5. Kilometre taşları

Her kilometre taşı = ayrı branch + PR. Bir sonrakine geçmeden önce PR kullanıcı tarafından onaylanır.

### M0 — Proje iskeleti
- Godot 4 projesi, klasör yapısı, autoload'lar, 480×270 piksel-mükemmel ayar.
- `.gitignore` (Godot + `assets_external/`), `CREDITS.md`, `assets_manifest.json` taslağı, `AssetLoader` (asset yoksa placeholder).
- GUT kurulumu, GitHub Actions (import + test + Linux/Windows export artifact).
- `docs/SENARYO.md` ekle.
**Kabul:** CI yeşil; boş sahne açılıyor; asset klasörü yokken hata vermiyor.

### M1 — Oyuncu hareketi ve dövüş çekirdeği (test odası)
- Samuray: koşma, zıplama (coyote, buffer, değişken yükseklik), dash, 3'lü kombo, havada saldırı, pogo, parry.
- InputSource soyutlaması; hitbox/hurtbox; Health; hit-stop; ekran sarsıntısı.
- Test odası: kukla düşman, pogo yapılabilir dikenler, parry'lenebilir mermi atan kule.
- `config/tuning.tres` içinde tüm sayılar.
**Kabul:** GUT testleri: parry penceresi içi/dışı, pogo sekmesi, kombo zinciri, hasar/ölüm. Gamepad ile oynanabilir.

### M2 — Form sistemi ve post-process
- `FormData` Resource, form geçişi (animasyonlu mavi kod ışıması), form seçimi girdisi.
- Tavuk ve Robot formlarının test sürümleri (test odasında hepsi açık "debug" modu).
- CRT/glitch/RGB shader katmanı ve ayar menüsü (efekt yoğunluğu).
**Kabul:** Tavuk dar tünelden geçer, Robot çatlak zemini kırar; efekt ayarları kaydedilir.

### M3 — Prolog (dikey dilim başlangıcı)
- Kulübe sahnesi: CRT içinde oynanan mini 8-bit oyun (basit, gerçekten oynanabilir), glitch, yaratığın çıkışı, şapka hırsızlığı, slapstick, katananın alınması, portala dalış.
- `CutscenePlayer` ve `Pictogram` sistemleri.
**Kabul:** Prolog baştan sona metinsiz oynanıyor/izleniyor; atlanabilir; Bölüm 1'e geçiyor.

### M4 — Bölüm 1: Öfkeli Köy + Lord Cluck
- Seviye (placeholder tileset), 3 düşman tipi (köylü, kalkanlı muhafız, ağır şövalye), geçici Şövalye formu, dinlenme noktası/checkpoint animasyonu, kayıt sistemi.
- Boss Lord Cluck: yer sarsma, patlayan yumurta; yumurtayı kılıçla geri yollama; ölüm → Tavuk Formu; Glitch Yaratık geçiş sahnesi.
- `BossBase` ve faz sistemi burada kurulur.
**Kabul:** Prolog → Bölüm 1 → boss → Bölüm 2 geçişi kesintisiz. Bu **dikey dilimdir**: kullanıcı burada his/tempo onayı verir, sonra seri üretime geçilir.

### M5 — Bölüm 2: Cyberpunk + Unit-0
- Siber-hırsız (sadece kombo ile savuşturulabilir), drone (pogo/tavukla aşma), arka pil zayıf noktalı dev koruma.
- Drone formu ile terminal bulmacası.
- Unit-0: elektrik dalgası, güdümlü füze, hidrolik yumruk; parry ile zırh kırma. Ödül: Robot formu.

### M6 — Bölüm 3: Gotik + Kont Vlad
- Hayaletler (kıvılcımla görünürlük), teleport eden vampirler (kanama DoT), duvar zıplayan kurtadamlar (parry'lenemez saldırı: kırmızı göz telegraph).
- Vlad 2 faz: kan kazıkları + eskrim; 2. fazda karanlık ekran, **stereo ses ile yön ipucu** (görsel alternatif ipucu da olmalı — erişilebilirlik).
- Ödül: Gölge dash (i-frame).

### M7 — Bölüm 4: Retro platform + Kızıl Tulumlu Tiran
- Bloklar, borular, kesilince ikiye bölünen mantarlar, sekme yapan kaplumbağa kabuğu, borudan çıkan ateş çiçekleri. Bozuk/tekinsiz hava: gözleri delice bakan bulutlar, devrilen dekor.
- Boss: yerçekimi yönünü değiştirme, ground pound, ekran dışından piksel yağmuru. "GAME OVER" yazısıyla düşüş.
- Ödül: Piksel Sıçraması (çift zıplama + blok kırma).

### M8 — Bölüm 5: Kül Diyarı + Kül Muhafızı
- Zorluk artışı (config'de bölüm bazlı hasar çarpanı; ağır darbe ~%70 can).
- Kül şövalyeleri (oyuncuyu taklit eden, parry yapan AI — `AIInputSource` burada ilk kez kullanılır, final için prova), gargoyle (sadece Robot ile kırılır), duman büyücüleri.
- Kül Muhafızı 2 faz (alevli kılıç, 3× hız). Saygı selamı sinematiği.

### M9 — Bölüm 6: Parçalanmış Bellek + Glitch Amalgam
- Önceki dünyaların karışık kolaj tileset'i, ayak altından dökülen kod parçacıkları, oyuncu sprite'ında titreme.
- Bileşen karıştırma ile melez düşmanlar.
- Checkpoint'te "yorgunluk" animasyonları (başını ellerine alma, kılıçtaki çatlağa bakma).
- Amalgam: fazlar sırasıyla Robot → Tavuk → Gölge → Piksel formu kullanımını zorunlu kılar. Beyaz patlamayla bitiş.

### M10 — Bölüm 7: Final, perspektif kayması, Ouroboros, jenerik
- Boşluk arenası; Glitch Yaratık boss'u + MetaDirector efektleri (can barı mızrağı, 4:3 daralma, ters kontrol, oyuncunun kombolarını karşılama).
- CRT kapanma efekti → seçim ekranı (zorunlu "Samurayı Öldür").
- Kamera 180° dönüşü: oyuncu artık Glitch Yaratık'ı yönetir (yeni hareket seti: glitch ışınlanma, dijital darbe). Samuray `AIInputSource` ile final boss.
- Genç samurayın şapkayı alması, "15 YIL SONRA...", kulübeye dönüş (Prolog sahnesi yeniden kullanılır, rolleri ters), dikey glitch kesme, jenerik (`CREDITS.md`'den).
**Kabul:** Tüm oyun baştan sona tek kayıtla bitirilebiliyor.

### M11 — Cila ve yayın
- Gerçek asset entegrasyonu (kullanıcının yerel asset'leri ile manifest doldurma), ses miksi, zorluk ayarı, kontrol yeniden atama menüsü, performans, Steam Deck/1280×800 kontrolü, itch.io build'i.

---

## 6. Başlangıç ayar değerleri (`config/tuning.tres`)

| Parametre | Başlangıç | Not |
|---|---|---|
| Koşma hızı | 110 px/s | 480×270 çözünürlükte |
| Zıplama yüksekliği | ~52 px | ~3 karo |
| Coyote time | 90 ms | |
| Jump buffer | 110 ms | |
| Dash mesafesi / süre | 64 px / 150 ms | Gölge dash'inde i-frame |
| Parry penceresi | 120 ms | Bölüm 5+ için daraltılabilir |
| Parry recovery (ıska) | 350 ms | |
| Hit-stop | 60 ms (normal), 120 ms (parry) | |
| Oyuncu canı | 5 maske | Bölüm çarpanlarıyla hasar |
| Pogo sekme hızı | zıplamanın %85'i | |

Hepsi oyun içinde test ederek ayarlanacak; Devin sabit sayı gömmez.

---

## 7. Kontroller (varsayılan)

| Eylem | Klavye | Gamepad |
|---|---|---|
| Hareket | A/D veya ok tuşları | Sol çubuk / D-pad |
| Zıpla | Space | A |
| Saldırı (aşağı + saldırı = pogo) | J | X |
| Parry | K | RB |
| Dash | L / Shift | B |
| Form değiştir | Q / E | LB / LT |
| Duraklat | Esc | Start |

---

## 8. Devin çalışma kuralları

1. Her kilometre taşı ayrı branch (`m1-player-core` gibi) ve ayrı PR. PR'da: yapılanlar, kabul kriterlerinin doğrulanması, kısa oynanış GIF'i/videosu.
2. CI yeşil olmadan PR açma.
3. Ham asset (png/wav/ogg) commit etme; sadece kendi ürettiğin basit placeholder'lar `assets_placeholder/` altında olabilir.
4. Oynanış sayıları kodda değil config'de.
5. Kopya kod yerine bileşen yeniden kullanımı (özellikle Bölüm 6 ve 7).
6. Metin/diyalog ekleme — oyun dilsiz. UI menüleri hariç (Türkçe + İngilizce, `tr.po`/`en.po`).
7. Senaryoda belirsiz ya da teknik olarak riskli bir şey görürsen (ör. gerçek pencere boyutu değiştirme) varsayım yapma; PR'da "Açık Soru" başlığıyla sor.

---

## 9. Açık sorular (kullanıcının karar vermesi gerekenler)

1. Repo public kalacak mı? Kalırsa gerçek asset'ler sadece yerelde kalır. Private olursa Git LFS ile repoya eklenebilir.
2. Hedef platform: sadece PC (Windows/Linux) mi, konsol/Steam Deck de mi?
3. Final boss'taki "gerçek oyun penceresini sallama/küçültme" fikri: sadece oyun içi taklit mi, yoksa gerçek pencere de mi? (Gerçek pencere tam ekranda ve bazı platformlarda sorun çıkarır; öneri: oyun içi taklit.)
4. Ana karakter için `FREE_Samurai 2D Pixel Art` paketi yeterli mi, yoksa özel sprite çizimi (slapstick mimikleri, form geçişleri) ısmarlanacak mı? Senaryodaki mimikler hazır paketlerde yok.
