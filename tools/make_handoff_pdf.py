# -*- coding: utf-8 -*-
"""Honor Meselesi — Antigravity el devirme dokumani PDF'i uretir."""
import os
from reportlab.lib.pagesizes import A4
from reportlab.lib.units import mm
from reportlab.lib.colors import HexColor, white
from reportlab.lib.styles import ParagraphStyle
from reportlab.lib.enums import TA_LEFT, TA_CENTER
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont
from reportlab.platypus import (BaseDocTemplate, Frame, PageTemplate,
                                Paragraph, Spacer, Table, TableStyle,
                                PageBreak)

OUT = os.path.expanduser(r"~\Desktop\Honor_Meselesi_Antigravity_Handoff.pdf")

FONT_DIR = r"C:\Windows\Fonts"
pdfmetrics.registerFont(TTFont("Arial", os.path.join(FONT_DIR, "arial.ttf")))
pdfmetrics.registerFont(TTFont("ArialB", os.path.join(FONT_DIR, "arialbd.ttf")))
pdfmetrics.registerFont(TTFont("ArialI", os.path.join(FONT_DIR, "ariali.ttf")))
pdfmetrics.registerFont(TTFont("Consolas", os.path.join(FONT_DIR, "consola.ttf")))

ACCENT = HexColor("#8e3b46")
INK = HexColor("#1c1a1e")
MUTED = HexColor("#5a5560")
CODE_BG = HexColor("#f2eef0")

S_TITLE = ParagraphStyle("t", fontName="ArialB", fontSize=20, textColor=ACCENT,
                         spaceAfter=2 * mm)
S_SUB = ParagraphStyle("s", fontName="Arial", fontSize=9.5, textColor=MUTED,
                       spaceAfter=6 * mm)
S_H = ParagraphStyle("h", fontName="ArialB", fontSize=12, textColor=ACCENT,
                     spaceBefore=6 * mm, spaceAfter=2.5 * mm)
S_B = ParagraphStyle("b", fontName="Arial", fontSize=9.5, textColor=INK,
                     leading=13.5, spaceAfter=1.6 * mm)
S_LI = ParagraphStyle("li", parent=S_B, leftIndent=5 * mm, bulletIndent=1 * mm)
S_CODE = ParagraphStyle("c", fontName="Consolas", fontSize=8.2,
                        textColor=INK, backColor=CODE_BG, leading=11.5,
                        leftIndent=3 * mm, rightIndent=3 * mm,
                        spaceBefore=1 * mm, spaceAfter=1.5 * mm,
                        borderPadding=(2, 4, 2, 4))


def P(t, s=S_B):
    return Paragraph(t, s)


def code(t):
    return Paragraph(t.replace("\n", "<br/>").replace(" ", "&nbsp;"), S_CODE)


def li(t):
    return Paragraph("• " + t, S_LI)


def header_footer(canv, doc):
    canv.saveState()
    canv.setFillColor(ACCENT)
    canv.rect(0, A4[1] - 9 * mm, A4[0], 9 * mm, fill=1, stroke=0)
    canv.setFillColor(white)
    canv.setFont("ArialB", 8)
    canv.drawString(14 * mm, A4[1] - 6 * mm,
                    "HONOR MESELESI — Antigravity Handoff")
    canv.setFillColor(MUTED)
    canv.setFont("Arial", 7.5)
    canv.drawRightString(A4[0] - 14 * mm, 6 * mm, f"Sayfa {doc.page}")
    canv.restoreState()


doc = BaseDocTemplate(OUT, pagesize=A4,
                      leftMargin=16 * mm, rightMargin=16 * mm,
                      topMargin=16 * mm, bottomMargin=13 * mm)
frame = Frame(doc.leftMargin, doc.bottomMargin, doc.width, doc.height)
doc.addPageTemplates([PageTemplate(frames=[frame], onPage=header_footer)])

E = []

E.append(P("HONOR MESELESI", S_TITLE))
E.append(P("Antigravity için proje el devirme dosyası — oyunu geliştirmeye devam "
           "etmeden önce bu belgeyi eksiksiz uygula. Hazırlayan: Devin · "
           "Depo: github.com/Eruldin/Honor-Meselesi · Godot 4.7.2", S_SUB))

E.append(P("0) ANTIGRAVITY'E VEREBILECEGIN HAZIR PROMPT", S_H))
E.append(P("Aşağıdaki metni olduğu gibi ilk mesaj olarak kullanabilirsin:", S_B))
E.append(code(
    "Bu klasorde Godot 4.7.2 ile yazilmis 'Honor Meselesi' adli 2D aksiyon-\n"
    "platform oyunu var. Tasarim dokumani docs/SENARYO.md — once onu oku.\n"
    "Kurallar: (1) Gorsel/HUD/level-design icin asla kodla sekiller cizme;\n"
    "oncelik her zaman assets_external/ ve manifest'teki gercek asset'ler.\n"
    "(2) Glitch/CRT efekti sadece FX.glitch() ile senaryo anlarinda; oyun\n"
    "siradaki goruntude asla glitch olmayacak. (3) Degisiklikten sonra test\n"
    "kos: Godot_console --path . -s addons/gut/gut_cmdln.gd -gdir=res://tests\n"
    "-gexit (83 test yesil kalmali). (4) assets_external/ klasoru gitignore'da\n"
    "ve 343MB+ — asla silme/tasima. (5) Proje adi 'Honor Meselesi' dir."))

E.append(P("1) PROJENIN KIMLIK KARTI", S_H))
t = Table([
    ["Motor / dil", "Godot 4.7.2 · GDScript"],
    ["Yol", r"C:\Users\PC\Desktop\Honor meselesi"],
    ["Ana sahne", "res://src/ui/Title.tscn"],
    ["Viewport", "480x270 · window 1440x810 · stretch=viewport/integer"],
    ["Test catisi", "GUT 9.6.1 (uyari penceresi cikarsa 'Devam Et' — zararsiz)"],
    ["Tasarim doc", "docs/SENARYO.md — bolum akisi, boss'lar, tema"],
    ["Durum", "Prolog + Bolum 1-7 + final oynanabilir; 83/83 test yesil"],
], colWidths=[38 * mm, 140 * mm])
t.setStyle(TableStyle([
    ("FONTNAME", (0, 0), (0, -1), "ArialB"),
    ("FONTNAME", (1, 0), (1, -1), "Arial"),
    ("FONTSIZE", (0, 0), (-1, -1), 8.6),
    ("TEXTCOLOR", (0, 0), (0, -1), ACCENT),
    ("ROWBACKGROUNDS", (0, 0), (-1, -1), [white, CODE_BG]),
    ("TOPPADDING", (0, 0), (-1, -1), 3),
    ("BOTTOMPADDING", (0, 0), (-1, -1), 3),
]))
E.append(t)

E.append(P("2) ASSET SISTEMI — EN KRITIK BOLUM", S_H))
E.append(P("Oyun gorselleri kodla cizmez; her sey gercek asset dosyasindan "
           "gelir. Sistem su sekilde calisir:", S_B))
E.append(li("<b>assets_manifest.json</b> — mantiksal id → dosya yolu eslemesi. "
            "Ornek: <font face='Consolas' size='8'>enemy/rooster → "
            "generated/rooster.png</font>"))
E.append(li("<b>AssetLoader</b> (autoload) — PNG'yi <i>import gerektirmeden</i> "
            "diskten yukler (Image.load_from_file). OGG/MP3/WAV muzik de ayni."))
E.append(li("<b>assets_external/</b> — ~343MB, gitignore'da. Silinirse oyun "
            "placeholder'a duser. Yeni asset eklersen manifest'e girdi yaz."))
E.append(li("Animasyon konvansiyonu: <font face='Consolas' size='8'>"
            "enemy/&lt;key&gt;/idle|walk|attack|hurt|die</font> — EnemyBase "
            "bunlari otomatik SpriteFrames bankasina toplar."))
E.append(li("Yeni dekor/zemin parcasi gerekiyorsa tools/build_ch1_assets.py "
            "ornegini takip edip kaynak atlaslardan crop'la → generated/."))
E.append(P("<b>Asla yapma:</b> duz renk ColorRect ile 'dunya' insa etme, "
           "sprite'i placeholder'a birakma, kucuk sprite'i 6x buyutup blob "
           "yapma. Dekorlari _add_deco_ground() ile zemine oturt — hicbir "
           "nesne havada durmasin.", S_B))

E.append(P("3) GLITCH KURALI (SENARIO SARTI)", S_H))
E.append(P("CRT/scanline/glitch efekti <b>sadece senaryo anlarinda</b> "
           "calisir: PostFX baseline master her zaman 0'dir. Cutscene'de "
           "kullanmak icin:", S_B))
E.append(code("FX.glitch(0.7, 0.6)   # guc, sure — sinematik darbe"))
E.append(P("Settings.fx_intensity artik puls gucluluk carpani (0=kapali). "
           "Asla ortam glitch'i icin kullanma.", S_B))

E.append(P("4) KOMUTLAR — HER DEGISIKLIK SONRASI", S_H))
E.append(code(
    'G="C:/Users/PC/Desktop/Godot_v4.7.2-stable_win64.exe/"\n'
    'G+="Godot_v4.7.2-stable_win64_console.exe"\n'
    '"$G" --path . --import                 # parse/import kontrol\n'
    '"$G" --path . -s addons/gut/gut_cmdln.gd -gdir=res://tests -gexit\n'
    '"$G" --path . tools/ProbeCh1.tscn --probe=village|gate|arena  # ekran gor.'))
E.append(P("Kayit araclari: tools/record_ch1.gd (uzun playtest kareleri), "
           "tools/probe_ch1.gd (hizli nokta goruntusu → %TEMP%/ch1_*.png).", S_B))

E.append(P("5) GIDAKA BILINMESI GEREKEN YAPILAR", S_H))
t2 = Table([
    ["Oyuncu", "src/player/samurai.gd — durum makinesi (idle/run/jump/dash/"
     "attack/parry/pogo/hurt/dead/rest/transform/cutscene)"],
    ["Dusman tabani", "src/enemies/enemy_base.gd — health/hurtbox/hitbox/"
     "animasyon bankasi/faz"],
    ["Boss tabani", "src/enemies/boss_base.gd — faz esikleri, defeated sinyali"],
    ["Bolumler", "src/levels/chN/chN.gd — arazi/entity/fx/hud kurulumu"],
    ["HUD", "src/ui/hud_bars.gd — dokulu bar uretici (HudBars.make)"],
    ["Ogretici", "src/ui/pictogram.gd — sessiz ikon balonlari (diyalog yok)"],
    ["Muzik", "AudioManager.play_music(id) — bolge bazli, ZONE_MUSIC ornegi "
     "ch1.gd'de"],
    ["Kayit", "SaveSystem + GameState flag'leri; Devam Et checkpoint'ten yukler"],
], colWidths=[32 * mm, 146 * mm])
t2.setStyle(TableStyle([
    ("FONTNAME", (0, 0), (0, -1), "ArialB"),
    ("FONTNAME", (1, 0), (1, -1), "Arial"),
    ("FONTSIZE", (0, 0), (-1, -1), 8.2),
    ("TEXTCOLOR", (0, 0), (0, -1), ACCENT),
    ("ROWBACKGROUNDS", (0, 0), (-1, -1), [white, CODE_BG]),
    ("VALIGN", (0, 0), (-1, -1), "TOP"),
    ("TOPPADDING", (0, 0), (-1, -1), 3),
    ("BOTTOMPADDING", (0, 0), (-1, -1), 3),
]))
E.append(t2)

E.append(P("6) KONTROL HARITASI", S_H))
E.append(P("Hareket A/D · Ziplama Space · Dash Shift · <b>Saldiri J veya sol "
           "tiklama</b> · <b>Parry K veya sag tiklama</b> · Asagi+saldiri "
           "havada = pogo · Dinlenme noktasi yakinda E/etkilesim.", S_B))

E.append(P("7) BILINEN TUZAKLAR (SAATLER KAZANDIRIR)", S_H))
E.append(li("<font face='Consolas' size='8'>Tween.from()</font> diye bir metod "
            "yok — baslangic degerini elle set edip tween'le."))
E.append(li("<font face='Consolas' size='8'>SpriteFrames.new()</font> hazir "
            "'default' animasyonla gelir — bos-kontrolu kare sayisina gore yap."))
E.append(li("<font face='Consolas' size='8'>AssetLoader.texture(id, size)</font> — "
            "size sadece placeholder icin; texture'i boyutlandirmaz."))
E.append(li("Atlas crop'larken koordinatlari programatik dogrula "
            "(opaklik kumeleri) — yanlis crop 'beyaz kaz' felaketi yaratti."))
E.append(li("Zemin dekorlari: her zaman alt-kenari FLOOR_Y'a oturt."))
E.append(li("Testler sahne gecislerini auto_advance=false ile kapatir; "
            "test icin gercek gecis tetikleme."))

E.append(P("8) LISANS / YAYIN UYARISI", S_H))
E.append(P("CREDITS.md guncel. <b>Dikkat:</b> 'Modern tiles_Free' (prolog "
           "ic mekan) ve 'Post-apocalyptic' (Bolum 5) free surumleri "
           "<b>ticari satisa izin vermez</b>. Oyun ucretsizse sorun yok; "
           "satilacaksa bu iki paketin ticari surumu alinmali.", S_B))

E.append(P("9) ONERILEN SIRADAKI ISLER", S_H))
E.append(li("Bolum 1 ~1 saatlik akis: rota dallanmalari, mini-arena'lar, "
            "sirlari genislet (gecerli iskelet src/levels/ch1/ch1.gd'de)."))
E.append(li("Bolum 2-7'ye ayni gorsel revizyon: gercek prop setleri, "
            "zemin dokusu, dekor yerlesimi."))
E.append(li("Lord Cluck'a cok-kareli animasyon (idle/walk/attack) — EnemyBase "
            "bankasi hazir, manifest'e enemy/rooster/* girdileri yeterli."))
E.append(li("Export paketleme: CI zaten Windows+Linux artifact'i uretiyor."))
E.append(li("SFX zenginligi: Super Dialogue Audio Pack, MECHA SOUNDS gibi "
            "paketlerden vurus/adim/UI sesleri bagla."))

doc.build(E)
print("Yazildi:", OUT)
