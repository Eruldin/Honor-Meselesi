extends Node2D
## Bolum 1 — Koyden Arena'ya (~1 saatlik ilk dilim).
## Bes bolge: Köy Şafagi -> Orman Yolu -> Magara Inisi -> Kale Gecidi
## (muhafiz+sovalye kapisi) -> Torii Arena + Lord Cluck.
## Ogretici tamamen cevresel: tabela-piktogramlar, guvenli deneme alanlari.

const CH2_PATH := "res://src/levels/ch2/Ch2.tscn"
const FLOOR_Y := 250.0
const LEVEL_W := 5000.0
const ZONE_MUSIC := [  # x sinirlari — soldan girince gecis
	{x = 700.0,  id = &"music/ch1_village", amb = &"amb/village"},  # pazar alani — sicak koy havasi
	{x = 1050.0, id = &"music/ch1_forest",  amb = &"amb/forest"},
	{x = 2300.0, id = &"music/ch1_cave",    amb = &"amb/cave"},
	{x = 3350.0, id = &"music/ch1_gate",    amb = &"amb/wind"},
]
const GATE_X := 4400.0       ## torii kapi cizgisi
const ARENA_L := 4520.0      ## arena sol duvari
const ARENA_R := 4900.0      ## arena sag duvari
const ARENA_TRIGGER := 4580.0  ## oyuncu tamamen icerideyken tetiklenir

## Testlerde gercek sahne gecisini kapatmak icin.
@export var auto_advance := true

var samurai: Samurai
var camera: ScreenShake
var boss: LordCluck
var knight: HeavyKnight
var _arena_walls: Array[StaticBody2D] = []
var _arena_wall_sprites: Array[Sprite2D] = []
var _boss_home := Vector2.ZERO
var _boss_bar: Control
var _boss_root: Control
var _boss_started := false
var _respawn_pending := false
var _music_zone := 0
var _gate_body: StaticBody2D
var _gate_sprite: Sprite2D


func _ready() -> void:
	GameState.current_chapter = &"ch1"
	AudioManager.play_music(&"music/ch1")
	AudioManager.play_ambience(&"amb/village")
	_build_terrain()
	_build_entities()
	_build_fx()
	_build_hud()
	EventBus.actor_died.connect(_on_actor_died)


func _process(delta: float) -> void:
	if samurai != null and is_instance_valid(samurai):
		camera.global_position.x = clampf(samurai.global_position.x, 240, LEVEL_W - 240)
		# Dikey takip: yuzeyde sabit y=135; yeraltina inince kamera kayar
		# (kuyu/kristal odasi gibi derin bolumler ekranda kalir).
		var cam_y := 135.0
		if samurai.global_position.y > FLOOR_Y + 24.0:
			cam_y = minf(samurai.global_position.y - 90.0,
				float(camera.limit_bottom) - 135.0)
		camera.global_position.y = lerpf(camera.global_position.y, cam_y,
			1.0 - exp(-8.0 * delta))
		# Bolge muzigi — oyuncu sinirdan gecince bir kez degisir
		while _music_zone < ZONE_MUSIC.size() \
				and samurai.global_position.x >= ZONE_MUSIC[_music_zone].x:
			AudioManager.play_music(ZONE_MUSIC[_music_zone].id)
			if ZONE_MUSIC[_music_zone].has("amb"):
				AudioManager.play_ambience(ZONE_MUSIC[_music_zone].amb)
			_music_zone += 1
	if boss != null and is_instance_valid(boss) and boss.active:
		_boss_root.visible = true
		_boss_bar.visible = true
		_boss_bar.size.x = 160.0 * float(boss.health.current) / maxf(boss.health.max_health, 1)


# --- Arazi kurulumu ---

func _add_ground(center: Vector2, size: Vector2,
		top_id: StringName = &"terrain/edge_grass",
		face_id: StringName = &"terrain/ground_face") -> void:
	var body := StaticBody2D.new()
	body.collision_layer = 1
	var col := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = size
	col.shape = rect
	body.add_child(col)
	body.global_position = center
	add_child(body)
	# Govde: collision'dan 24px asagi tasan toprak dolgu — saglam kutle
	var skirt := 24.0
	var fill := ColorRect.new()
	fill.color = Color(0.13, 0.09, 0.10)
	fill.position = Vector2(-size.x / 2.0, -size.y / 2.0)
	fill.size = Vector2(size.x, size.y + skirt)
	body.add_child(fill)
	# Yuz: doseme zemin dokusu — kutu gorunumunu kirir, saglam kutle hissi
	if AssetLoader.has_asset(face_id):
		var ftex := AssetLoader.tiled_texture(face_id,
			Vector2i(int(size.x), int(size.y + skirt)))
		var fs := Sprite2D.new()
		fs.texture = ftex
		fs.centered = false
		fs.position = Vector2(-size.x / 2.0, -size.y / 2.0)
		body.add_child(fs)
	# Kenar seridi: ust kenara yapisik, hafif bindirmeli kesintisiz dosemе
	if AssetLoader.has_asset(top_id):
		var ttex := AssetLoader.texture(top_id)
		var th := float(ttex.get_height())
		var seg_w := float(ttex.get_width())
		var overlap := 10.0 if top_id == &"terrain/edge_grass" else 6.0
		var x := -size.x / 2.0 - 2.0
		while x < size.x / 2.0:
			var s := Sprite2D.new()
			s.texture = ttex
			s.centered = false
			s.position = Vector2(x, -size.y / 2.0 - th + 3.0)
			body.add_child(s)
			x += seg_w - overlap


func _add_platform(pos: Vector2, id: StringName, w: float) -> void:
	## Organik zemin parcasi — sprite gercek parca, collision boyuna gore.
	var tex := AssetLoader.texture(id)
	if tex == null:
		return
	var body := StaticBody2D.new()
	body.collision_layer = 1
	var col := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(w, 8)
	col.shape = rect
	body.add_child(col)
	var s := Sprite2D.new()
	s.texture = tex
	var sc := w / tex.get_width()
	s.scale = Vector2(sc, sc)
	s.position = Vector2(-w / 2.0, -tex.get_height() * sc * 0.62)
	s.z_index = 2
	body.add_child(s)
	
	# Platform havada ucmamasi icin altina destek (wall) ekle
	var support_y := FLOOR_Y
	if pos.y >= FLOOR_Y:
		if pos.x > 3600:
			support_y = FLOOR_Y + 160.0 # Gecit mahzeni
		elif pos.x > 3000:
			support_y = FLOOR_Y + 140.0 # Magara kristal odasi
	
	var support_h := support_y - pos.y
	if support_h > 0 and AssetLoader.has_asset(&"terrain/wall_tile"):
		var col_w := mini(16, int(w))
		var wtex := AssetLoader.tiled_texture(&"terrain/wall_tile", Vector2i(col_w, int(support_h)))
		var ws := Sprite2D.new()
		ws.texture = wtex
		ws.centered = false
		ws.position = Vector2(-col_w / 2.0, 0)
		ws.modulate = Color(0.3, 0.28, 0.35) # Koyu destek
		ws.z_index = -2 # Zemin arkasinda kalsin
		body.add_child(ws)

	body.global_position = pos
	add_child(body)


## Tek-sprite parallax katmani: tekil buyuk nesneler (ay, dag, selale)
## icin — Parallax2D dosemesiz, tek Sprite2D tasiyici.
func _add_para_sprite(id: StringName, scroll: float, pos: Vector2,
		mod := Color.WHITE) -> void:
	if not AssetLoader.has_asset(id):
		return
	var p := Parallax2D.new()
	p.scroll_scale = Vector2(scroll, 0.0)  # x suruklenir, y gokyuzunde sabit
	var s := Sprite2D.new()
	s.texture = AssetLoader.texture(id)
	s.centered = false
	s.position = pos  # konum katman-yerel; scroll Parallax2D uygular
	s.modulate = mod
	p.add_child(s)
	add_child(p)


func _add_deco(id: StringName, pos: Vector2, scale := 1.0,
		modulate := Color.WHITE, flip := false, z := 0) -> Sprite2D:
	if not AssetLoader.has_asset(id):
		return null
	var s := Sprite2D.new()
	s.texture = AssetLoader.texture(id)
	s.scale = Vector2(-scale if flip else scale, scale)
	s.position = pos
	s.modulate = modulate
	s.z_index = z
	add_child(s)
	return s


func _add_deco_ground(id: StringName, x: float, floor_y := FLOOR_Y,
		scale := 1.0, modulate := Color.WHITE, flip := false,
		z := 0) -> Sprite2D:
	## Alt kenari tam zemine oturan dekor — hicbir sey havada durmaz.
	var s := _add_deco(id, Vector2(x, floor_y), scale, modulate, flip, z)
	if s != null:
		s.position.y = floor_y - s.texture.get_height() * scale * 0.5
	return s


func _add_sign(pos: Vector2, icon: StringName) -> void:
	## Ogretici tabela: oyuncu yaklasinca balonla ikon gosterir.
	var sign := _add_deco_ground(&"prop/sign", pos.x, pos.y, 0.5,
		Color(0.9, 0.8, 0.7))
	if sign == null:
		sign = Sprite2D.new()
		sign.texture = AssetLoader.texture(&"prop/sign", Vector2i(10, 14))
		sign.position = pos + Vector2(0, -8)
		add_child(sign)
	var trig := Area2D.new()
	trig.collision_layer = 0
	trig.collision_mask = 4
	var col := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(70, 90)
	col.shape = rect
	trig.add_child(col)
	trig.position = pos
	var node := self
	var shown := [false]
	trig.area_entered.connect(func(_a: Area2D) -> void:
		if shown[0] or samurai == null:
			return
		shown[0] = true
		Pictogram.show_on(samurai, icon, 2.0, Vector2(0, -34))
		if node.has_method("_sign_sfx"):
			node._sign_sfx())
	add_child(trig)


func _sign_sfx() -> void:
	AudioManager.play_sfx(&"sfx/npc_blip", samurai.global_position if samurai else Vector2.ZERO, -8.0)


func _add_spikes(x0: float, x1: float, y: float) -> void:
	var x := x0
	while x < x1:
		var sp := Spike.new()
		sp.size = Vector2(24, 10)
		sp.global_position = Vector2(x + 12, y)
		add_child(sp)
		x += 24.0


func _add_rest(x: float, id: StringName, y: float = FLOOR_Y - 4) -> void:
	var rest := RestPoint.new()
	rest.checkpoint_id = id
	rest.global_position = Vector2(x, y)
	add_child(rest)
	# Tas fener gorunumu
	if AssetLoader.has_asset(&"prop/deco_lantern"):
		var sp := rest.get_node_or_null("sprite")
		if sp != null:
			sp.texture = AssetLoader.texture(&"prop/deco_lantern")
			sp.scale = Vector2(0.55, 0.55)
			sp.position.y = -11
			sp.modulate = Color(1.0, 0.85, 0.6)


## Gizli oda odulu — vurunca acilan sandik (tam iyilesme).
func _add_chest(x: float, ground_y: float) -> void:
	var ch := LootChest.new()
	ch.global_position = Vector2(x, ground_y - 8)
	add_child(ch)


## Kalp kristali — kalici +1 maks can (mahzen cikis platformunun ustunde).
func _add_shard(x: float, y: float, id: StringName) -> void:
	var sh := HeartShard.new()
	sh.pickup_id = id
	sh.global_position = Vector2(x, y)
	add_child(sh)


func _build_terrain() -> void:
	# Gokyuzu zemin rengi (Tum bolume yayili, yeralti bosluklarini kapatir)
	var sky := ColorRect.new()
	sky.color = Color(0.12, 0.1, 0.15)
	sky.position = Vector2(0, -200)
	sky.size = Vector2(LEVEL_W, 800)
	sky.z_index = -10
	add_child(sky)
	
	# 1) Koy (0 - 1200) — japon koyu: ay + dag panoramasi + alacakaranlik
	ParallaxBg.add(self, LEVEL_W, [
		{id = &"bg/dusk_sky", scroll = 0.0, x0 = 0, x1 = 1200},
		{id = &"bg/j_mountains", scroll = 0.06, x0 = 0, x1 = 1200,
			modulate = Color(0.8, 0.7, 0.85)},
		{id = &"bg/dusk_far", scroll = 0.10, x0 = 0, x1 = 1200},
		{id = &"bg/dusk_mid", scroll = 0.22, x0 = 0, x1 = 1200},
		{id = &"bg/taiga_mid", scroll = 0.30, x0 = 0, x1 = 1200,
			modulate = Color(0.55, 0.5, 0.65)},  # taiga duzluk, dusk tint
		{id = &"bg/dusk_trees", scroll = 0.42, modulate = Color(0.95, 0.8, 0.8), x0 = 0, x1 = 1200},
		{id = &"bg/dusk_trees", scroll = 0.55, modulate = Color(0.35, 0.25, 0.3), x0 = 0, x1 = 1200},
	])
	# Ay gokyuzu kompozitine pisirilmis (bg_sky 1440px genislikte tek ay)
	
	# 2) Orman (1200 - 2300) — derin yesil katmanlar + japon agac bandi
	ParallaxBg.add(self, LEVEL_W, [
		{id = &"bg/forest_far", scroll = 0.08, x0 = 1200, x1 = 2300},
		{id = &"bg/forest_mid", scroll = 0.18, x0 = 1200, x1 = 2300},
		{id = &"bg/j_trees", scroll = 0.26, modulate = Color(0.7, 0.85, 0.75), x0 = 1200, x1 = 2300},
		{id = &"bg/forest_near", scroll = 0.35, x0 = 1200, x1 = 2300},
		{id = &"bg/forest_lights", scroll = 0.35, modulate = Color(1.0, 1.0, 1.0, 0.5), x0 = 1200, x1 = 2300},
	])
	# Selale ucurumu — ormanin arkasi, sabit dunya konumunda dekor
	_add_deco_ground(&"bg/j_falls", 1260, FLOOR_Y + 30, 1.6,
		Color(0.65, 0.75, 0.85), false, -3)

	# Magara (2300 - 3350) — Admurin dikilitas siluetleri: onplan
	# derinligi (z>0 → oynanisin onunde, HK tarzi ic perspektif)
	ParallaxBg.add(self, LEVEL_W, [
		{id = &"bg/cave_px_1", scroll = 0.8, x0 = 2300, x1 = 3350,
			z_index = 5, modulate = Color(0.5, 0.45, 0.6, 0.9)},
		{id = &"bg/cave_px_2", scroll = 0.9, x0 = 2300, x1 = 3350,
			z_index = 6, modulate = Color(0.4, 0.35, 0.5, 0.95)},
	])
	# 3) Magara (2300 - 3350) — duvar tum parallax bittikten sonra eklenir
	# (asagida, zeminlerden once: parallax ustunde, oynanis altinda)
	# 4) Gecit (3350 - 4500) — gothicvania gercek mezarlik katmanlari:
	# kizil ay gokyuzu + siluet daglar + mezartas bandi
	ParallaxBg.add(self, LEVEL_W, [
		{id = &"bg/cemetery_sky", scroll = 0.15, x0 = 3350, x1 = 4500},
		{id = &"bg/cemetery_mountains", scroll = 0.22, x0 = 3350, x1 = 4500},
		{id = &"bg/cemetery_yard", scroll = 0.30, x0 = 3350, x1 = 4500},
		{id = &"bg/cemetery_near", scroll = 0.3, x0 = 3350, x1 = 4500,
			modulate = Color(1.4, 1.4, 1.6, 0.35)},  # hayalet duvar — hafif sizar
	])
	
	# 5) Arena (4500 - LEVEL_W)
	# NOT: buraya ikinci bir scroll=0 gokyuzu KONMAZ — scroll-0 katman ekrana
	# sabittir ve bolgeden bagimsiz tum ekrani kaplar; son sirayla cizildigi
	# icin diger tum parallax katmanlari gizler. Tek global gokyuzu koy
	# grubunun ilk katmanidir (ustte).
	ParallaxBg.add(self, LEVEL_W, [
		{id = &"bg/dusk_far", scroll = 0.10, x0 = 4500, x1 = LEVEL_W},
		# ufukta gotik kale — Elden Ring tarzi uzak siluet; yaklastikca buyur
		{id = &"bg/gothic_castle", scroll = 0.35, x0 = 4500, x1 = LEVEL_W},
		# tek ince agac bandi — boss savasi icin temiz fon; yogun momiji yok
		{id = &"bg/dusk_trees", scroll = 0.5, modulate = Color(0.5, 0.4, 0.45, 0.55), x0 = 4500, x1 = LEVEL_W},
	])

	# Magara duvari: parallax'larin ustune, zeminlerin/varliklarin altina
	if AssetLoader.has_asset(&"bg/cave_back"):
		var cw := Sprite2D.new()
		cw.texture = AssetLoader.tiled_texture(&"bg/cave_back", Vector2i(1050, 700))
		cw.centered = false
		cw.position = Vector2(2300, -100)
		cw.modulate = Color(0.7, 0.65, 0.8)
		add_child(cw)

	# === ZEMINLER ===
	# A: koy duzlugu — kuyu girisi icin x=458-502 arasi bosluklu iki parca
	_add_ground(Vector2(230, FLOOR_Y + 10), Vector2(460, 26))   # 0-460
	_add_ground(Vector2(772, FLOOR_Y + 10), Vector2(540, 26))   # 504-1044
	
	# Cukur gorunumu: arkaya siyah perde ve kenarlara cikinti
	var well_bg := ColorRect.new()
	well_bg.color = Color(0.02, 0.01, 0.03)
	well_bg.position = Vector2(450, FLOOR_Y - 26)
	well_bg.size = Vector2(60, 200)
	well_bg.z_index = -6 # Gokyuzunun onunde, kuyu propunun arkasinda
	add_child(well_bg)
	if AssetLoader.has_asset(&"terrain/edge_dirt"):
		var lip_l := Sprite2D.new()
		lip_l.texture = AssetLoader.tiled_texture(&"terrain/edge_dirt", Vector2i(16, 26))
		lip_l.position = Vector2(452, FLOOR_Y - 3)
		add_child(lip_l)
		var lip_r := Sprite2D.new()
		lip_r.texture = AssetLoader.tiled_texture(&"terrain/edge_dirt", Vector2i(16, 26))
		lip_r.position = Vector2(510, FLOOR_Y - 3)
		lip_r.flip_h = true
		add_child(lip_r)
	# B: orman — kaya bariyerini platformlarla as (ust rota gizli)
	_add_ground(Vector2(1560, FLOOR_Y + 10), Vector2(1000, 26))
	_add_ground(Vector2(2200, FLOOR_Y + 10), Vector2(280, 26))
	# Kaya bariyer: 1380-1530 — ustunden platformla gecilir
	var barrier := StaticBody2D.new()
	barrier.collision_layer = 1
	var bc := CollisionShape2D.new()
	var br := RectangleShape2D.new()
	br.size = Vector2(150, 52)
	bc.shape = br
	barrier.add_child(bc)
	barrier.global_position = Vector2(1455, FLOOR_Y - 26)
	add_child(barrier)
	var bar_fill := ColorRect.new()
	bar_fill.color = Color(0.14, 0.1, 0.09)
	bar_fill.position = Vector2(-75, -26)
	bar_fill.size = Vector2(150, 52)
	barrier.add_child(bar_fill)
	# Bariyer yuzu: doseme kaya dokusu + ustte cim kenari (havada durmaz)
	if AssetLoader.has_asset(&"terrain/edge_dirt"):
		var face := Sprite2D.new()
		face.texture = AssetLoader.tiled_texture(&"terrain/edge_dirt", Vector2i(150, 52))
		face.centered = false
		face.position = Vector2(-75, -26)
		face.modulate = Color(0.55, 0.48, 0.45)
		barrier.add_child(face)
	# Havada durmamasi icin taban kenari ekle
	_add_deco_ground(&"terrain/cave_rock", 1455, FLOOR_Y, 1.0, Color(0.3, 0.25, 0.2))
	if AssetLoader.has_asset(&"terrain/edge_grass"):
		var gcap := Sprite2D.new()
		gcap.texture = AssetLoader.tiled_texture(&"terrain/edge_grass", Vector2i(150, 14))
		gcap.centered = false
		gcap.position = Vector2(-75, -26 - 12)
		barrier.add_child(gcap)
	# Bariyeri asan uc basamak + ust gizli rota
	_add_platform(Vector2(1390, 205), &"terrain/pf_ledge", 75)
	_add_platform(Vector2(1455, 178), &"terrain/pf_grass_wide", 80)
	_add_platform(Vector2(1525, 205), &"terrain/pf_ledge", 75)
	# B ust rota (gizli odul): yuksek seritler
	_add_platform(Vector2(1640, 140), &"terrain/pf_ledge", 90)
	_add_platform(Vector2(1760, 160), &"terrain/pf_slab", 85)
	# FlickerPlatform sekansi (yanilip sonen platformlar)
	var fp1 := FlickerPlatform.new()
	fp1.size = Vector2(40, 10)
	fp1.tex_id = &"terrain/pf_ledge"
	fp1.global_position = Vector2(1840, 150)
	fp1.phase_offset = 0.0
	add_child(fp1)

	var fp2 := FlickerPlatform.new()
	fp2.size = Vector2(40, 10)
	fp2.tex_id = &"terrain/pf_ledge"
	fp2.global_position = Vector2(1915, 135)
	fp2.phase_offset = 1.0
	add_child(fp2)

	# Gizli tapinak avlusu (BreakableBlock ardinda RestPoint)
	_add_ground(Vector2(2045, 135), Vector2(160, 26), &"terrain/edge_dirt")
	var bb_forest := BreakableBlock.new()
	bb_forest.size = Vector2(16, 60)
	bb_forest.global_position = Vector2(1975, 135 - 13 - 30)
	add_child(bb_forest)
	_add_rest(2035, &"ch1_forest_secret", 135 - 13 - 4)
	_add_deco_ground(&"prop/statue", 2085, 135 - 13, 0.7, Color(0.6, 0.7, 0.6))
	
	# Gizli odadan asagi donus yolu (dusup hasar almamasi icin platform)
	_add_platform(Vector2(2150, 190), &"terrain/pf_block", 44)
	# C: magara — daha alcak tavan hissi
	# Zemin iki parca: 2310-3130 ve 3190-3330 (60px bosluk kirilabilir zemin olacak)
	_add_ground(Vector2(2720, FLOOR_Y + 10), Vector2(820, 26),
		&"terrain/edge_dirt", &"terrain/cave_bricks")
	_add_ground(Vector2(3260, FLOOR_Y + 10), Vector2(140, 26),
		&"terrain/edge_dirt", &"terrain/cave_bricks")
	
	# Magara cukuru: diken + pogo platformlari
	_add_platform(Vector2(2540, 210), &"terrain/pf_block", 44)
	_add_platform(Vector2(2640, 195), &"terrain/pf_block", 44)
	_add_platform(Vector2(2740, 210), &"terrain/pf_block", 44)

	# Magara zemini bitki susleri (browncave paketi) — alacakaranlik tini
	for d in [
		[2450.0, &"prop/cave_grass1", 0.5],
		[2620.0, &"prop/cave_plant1", 0.45],
		[2870.0, &"prop/cave_grass2", 0.5],
		[3050.0, &"prop/cave_plants_grp", 0.55],
		[3250.0, &"prop/cave_grass3", 0.5],
	]:
		_add_deco_ground(d[1], d[0], FLOOR_Y, d[2], Color(0.55, 0.5, 0.65))

	# Kirilabilir zemin ve altındaki Kristal Odası
	var bb_cave := BreakableBlock.new()
	bb_cave.size = Vector2(60, 20)
	bb_cave.global_position = Vector2(3160, FLOOR_Y + 10)
	add_child(bb_cave)
	
	# Kristal odasi (sub-basement) zemin ve duvarlari
	var cry_floor_y := FLOOR_Y + 140.0
	_add_ground(Vector2(3160, cry_floor_y + 13), Vector2(240, 26),
		&"terrain/edge_dirt", &"terrain/cave_bricks")
	
	for wx in [3040.0, 3280.0]:
		var cw := StaticBody2D.new()
		cw.collision_layer = 1
		var cc := CollisionShape2D.new()
		var cr := RectangleShape2D.new()
		cr.size = Vector2(16, 140)
		cc.shape = cr
		cw.add_child(cc)
		cw.global_position = Vector2(wx, cry_floor_y - 70)
		add_child(cw)

	# Geri donus platformlari (asagidan yukari ziplamak icin)
	_add_platform(Vector2(3120, cry_floor_y - 30), &"terrain/pf_block", 32)
	_add_platform(Vector2(3170, cry_floor_y - 65), &"terrain/pf_block", 32)
	_add_platform(Vector2(3130, cry_floor_y - 105), &"terrain/pf_ledge", 36)
	# D: gecit — tirmanis + duzluk + alt crypt (Mezarlik Mahzeni)
	_add_platform(Vector2(3400, 205), &"terrain/pf_corner", 70)
	_add_platform(Vector2(3500, 175), &"terrain/pf_plateau", 100)
	
	# Zemin iki parca: 3490-3750 ve 3810-4410. Arada 60px mahzen inis boslugu.
	_add_ground(Vector2(3620, FLOOR_Y + 10), Vector2(260, 26), &"terrain/edge_dirt")
	_add_ground(Vector2(4110, FLOOR_Y + 10), Vector2(600, 26), &"terrain/edge_dirt")
	
	# Mahzen Inisi (Kırılabilir Zemin)
	var bb_crypt := BreakableBlock.new()
	bb_crypt.size = Vector2(60, 20)
	bb_crypt.global_position = Vector2(3780, FLOOR_Y + 10)
	add_child(bb_crypt)

	# Alt Mahzen Zemini ve Duvarlari
	var crypt_y := FLOOR_Y + 160.0
	_add_ground(Vector2(3780, crypt_y + 13), Vector2(300, 26), &"terrain/edge_dirt")
	for wx in [3630.0, 3930.0]:
		var cw := StaticBody2D.new()
		cw.collision_layer = 1
		var cc := CollisionShape2D.new()
		var cr := RectangleShape2D.new()
		cr.size = Vector2(16, 160)
		cc.shape = cr
		cw.add_child(cc)
		cw.global_position = Vector2(wx, crypt_y - 80)
		add_child(cw)

	# Mahzen Cikis Platformlari
	_add_platform(Vector2(3730, crypt_y - 35), &"terrain/pf_block", 32)
	_add_platform(Vector2(3810, crypt_y - 75), &"terrain/pf_block", 32)
	_add_platform(Vector2(3750, crypt_y - 115), &"terrain/pf_ledge", 36)

	# Gecit Ust Rota (Harabe Surlar)
	_add_platform(Vector2(3650, 140), &"terrain/pf_slab", 85)
	_add_platform(Vector2(3765, 140), &"terrain/pf_slab", 85)
	_add_platform(Vector2(3880, 140), &"terrain/pf_slab", 85)
	_add_platform(Vector2(3995, 140), &"terrain/pf_slab", 85)
	
	var bb_sur := BreakableBlock.new()
	bb_sur.size = Vector2(16, 50)
	bb_sur.global_position = Vector2(3935, 140 - 13 - 25)
	add_child(bb_sur)
	
	_add_deco_ground(&"prop/statue", 3995, 140 - 13, 0.7, Color(0.4, 0.45, 0.5))
	
	_add_platform(Vector2(4070, 160), &"terrain/pf_ledge", 40)
	_add_platform(Vector2(4120, 190), &"terrain/pf_ledge", 40)

	# E: arena zemini
	_add_ground(Vector2(4690, FLOOR_Y + 10), Vector2(560, 26), &"terrain/edge_dirt")


	# Magarayi karartan ortu
	var dark := ColorRect.new()
	dark.color = Color(0.04, 0.03, 0.1, 0.28)
	dark.position = Vector2(2300, -200)
	dark.size = Vector2(1050, 1000)
	dark.z_index = 20
	add_child(dark)

	# === KOY DEKORU ===
	var house_mod := Color(0.75, 0.6, 0.62)
	# === JAPON KOYU ===
	# Torii girisi — koyun batı ucunda ikonik kapi
	_add_deco_ground(&"prop/torii", 48, FLOOR_Y + 2, 1.15,
		Color(0.9, 0.55, 0.45))
	# Samurayin evi — prolog evinin dis gorunumu
	_add_deco_ground(&"prop/house_main", 178, FLOOR_Y + 4, 0.78,
		Color(0.88, 0.75, 0.7))
	# Mahalle evleri — ayni tip japon evi, farkli tonlarla varyasyon
	_add_deco_ground(&"prop/house_main", 520, FLOOR_Y + 4, 0.7,
		Color(0.75, 0.62, 0.62))
	_add_deco_ground(&"prop/house_main", 905, FLOOR_Y + 4, 0.74,
		Color(0.82, 0.66, 0.58))
	# Tas pagoda fenerler — sokak aydinlatmasi
	for x in [300.0, 660.0, 1010.0]:
		_add_deco_ground(&"prop/stone_lamp", x, FLOOR_Y, 0.55,
			Color(0.9, 0.85, 0.8))
	# Asili kagit fenerler — ev girislerinin saçaklari altinda
	for x in [150.0, 210.0, 492.0, 552.0, 875.0, 940.0]:
		_add_deco(&"prop/lantern_hang", Vector2(x, FLOOR_Y - 52), 0.42,
			Color(1.0, 0.85, 0.65), false, 1)
	# Ahsap citler — bahce sinirlari
	_add_deco_ground(&"prop/j_fence", 385, FLOOR_Y, 0.8, Color(0.7, 0.55, 0.45))
	_add_deco_ground(&"prop/j_fence", 620, FLOOR_Y, 0.8,
		Color(0.7, 0.55, 0.45), true)
	# Saksili bitkiler — ev onleri
	_add_deco_ground(&"prop/plant_0", 126, FLOOR_Y, 0.45, Color(0.8, 0.9, 0.7))
	_add_deco_ground(&"prop/plant_1", 236, FLOOR_Y, 0.5, Color(0.75, 0.85, 0.65))
	_add_deco_ground(&"prop/plant_2", 470, FLOOR_Y, 0.5, Color(0.8, 0.9, 0.7))
	_add_deco_ground(&"prop/plant_3", 850, FLOOR_Y, 0.55, Color(0.75, 0.85, 0.65))
	# Koy meydani: kuyu (gizli oda girisi), araba, kasalar, varil
	_add_deco_ground(&"prop/well", 480, FLOOR_Y + 18, 1.0, house_mod)
	_add_deco_ground(&"prop/wagon", 330, FLOOR_Y, 0.75, house_mod)
	_add_deco_ground(&"prop/crate_stack", 700, FLOOR_Y, 0.7, house_mod)
	_add_deco_ground(&"prop/crate", 745, FLOOR_Y, 0.8, house_mod)
	_add_deco_ground(&"prop/barrel", 985, FLOOR_Y, 0.85, house_mod)
	# === PAZAR ALANI (x=700-1040) ===
	_add_deco_ground(&"prop/market_stall", 740, FLOOR_Y, 0.55, Color(0.9, 0.8, 0.6))
	_add_deco_ground(&"prop/market_stall", 840, FLOOR_Y, 0.55, Color(0.85, 0.75, 0.55), true)
	_add_deco_ground(&"prop/sack", 780, FLOOR_Y, 0.5, Color(0.7, 0.62, 0.5))
	_add_deco_ground(&"prop/crate", 870, FLOOR_Y, 0.6, Color(0.65, 0.55, 0.48))
	# Kiraz agaci — koy meydaninin sag kenari, ormana gecis
	_add_deco_ground(&"bg/j_cherry", 1080, FLOOR_Y + 4, 1.15,
		Color(1.0, 0.85, 0.9))
	_add_deco_ground(&"prop/bush_small", 1030, FLOOR_Y, 0.7, Color(0.5, 0.65, 0.45))
	# Kumes hayvanlari + pasif koylu
	for i in 4:
		var npc := AmbientNpc.new()
		npc.npc_key = [&"peasant1", &"peasant3", &"monk", &"farmer"][i]
		# Piktogram atamalari: hikayeyi sessiz anlatan ikonlar
		npc.picto_icon = [&"alarm", &"alarm", &"dots", &"arrow_right"][i]
		npc.position = Vector2(260.0 + i * 190.0, FLOOR_Y - 8)
		add_child(npc)
	_add_deco_ground(&"npc/chicken", 310, FLOOR_Y, 0.9, Color.WHITE, false, 2)
	_add_deco_ground(&"npc/goose", 680, FLOOR_Y, 0.9, Color.WHITE, true, 2)
	_add_deco_ground(&"npc/duck", 880, FLOOR_Y, 0.8, Color.WHITE, false, 2)
	# Pazar pazarcisi (pasif NPC — pazar tarafinda)
	var merchant := AmbientNpc.new()
	merchant.npc_key = &"mage"
	merchant.picto_icon = &"dots"
	merchant.position = Vector2(800.0, FLOOR_Y - 8)
	add_child(merchant)
	# === GİZLİ KUYU ODASI ===
	# Kuyu altinda platform merdiveni — asagi iner, gizli oda, geri donus yolu var
	# Cukur giris: x=460-500 boslugu (zemin A iki parca). Oda tabani FLOOR_Y+86.
	var pit_x := 480.0
	var pit_floor := FLOOR_Y + 86.0  # gizli oda zemini
	# Oda yan duvarlari — oyuncu zeminin altina kacamaz
	for wx in [pit_x - 64.0, pit_x + 64.0]:
		var pw := StaticBody2D.new()
		pw.collision_layer = 1
		var pc := CollisionShape2D.new()
		var pr := RectangleShape2D.new()
		pr.size = Vector2(8, 110)
		pc.shape = pr
		pw.add_child(pc)
		pw.global_position = Vector2(wx, pit_floor - 40)
		add_child(pw)
	# Cukur tabanı — gizli oda zemini
	_add_ground(Vector2(pit_x, pit_floor + 13), Vector2(128, 26),
		&"terrain/edge_dirt", &"terrain/cave_bricks")
	# Inis/cikis platformlari (merdiven — her basamak <44px; ziplama ~56px)
	_add_platform(Vector2(pit_x - 20, FLOOR_Y + 40), &"terrain/pf_ledge", 36)
	_add_platform(Vector2(pit_x + 26, FLOOR_Y + 62), &"terrain/pf_block", 32)
	_add_platform(Vector2(pit_x - 26, pit_floor - 30), &"terrain/pf_block", 28)
	_add_platform(Vector2(pit_x - 28, pit_floor - 72), &"terrain/pf_ledge", 30)
	# Gizli oda kristal dekor (magara hissi)
	_add_deco_ground(&"terrain/cave_crystal", pit_x - 14, pit_floor,
		0.8, Color(0.8, 0.7, 1.0))
	_add_deco_ground(&"terrain/cave_crystal", pit_x + 18, pit_floor,
		0.7, Color(0.7, 0.8, 1.0))
	# Gizli rest point — kuyu gizli odasinin dibinde
	_add_rest(pit_x + 4, &"ch1_well_secret")
	_add_chest(pit_x + 48, pit_floor)

	# === OGRETICI TABELALAR ===
	_add_sign(Vector2(150, FLOOR_Y), &"move")      # A/D oku
	_add_sign(Vector2(430, FLOOR_Y), &"sword")     # saldiri (mouse/klavye)
	_add_sign(Vector2(1180, FLOOR_Y), &"jump")     # cukur oncesi
	_add_sign(Vector2(2490, FLOOR_Y), &"down")     # pogo (asagi+saldiri)
	_add_sign(Vector2(3660, FLOOR_Y), &"shield")   # parry — muhafizdan once


	# === ORMAN DEKORU ===
	# Yosunlar yuksek platformlarin altindan sarkar (havada durmaz)
	for spec in [[Vector2(1640, 152)], [Vector2(1760, 172)], [Vector2(1455, 190)]]:
		_add_deco(&"prop/moss", spec[0] + Vector2(0, 4), 0.7,
			Color(0.55, 0.7, 0.5))

	# === MAGARA DEKORU ===
	for x in [2350.0, 2520.0, 2900.0, 3150.0]:
		_add_deco_ground(&"terrain/cave_crystal", x, FLOOR_Y, 0.9,
			Color(0.8, 0.7, 1.0))
	_add_deco_ground(&"terrain/cave_shroom", 2420, FLOOR_Y, 0.9,
		Color(0.8, 0.6, 0.9))
	_add_deco_ground(&"terrain/cave_shroom", 3080, FLOOR_Y, 0.7,
		Color(0.7, 0.55, 0.85))
	# Alt Kristal Odasi (Sub-basement) Dekoru
	for x in [3060.0, 3110.0, 3210.0, 3250.0]:
		_add_deco_ground(&"terrain/cave_crystal", x, FLOOR_Y + 140.0, 0.9,
			Color(0.8, 0.5, 1.0))
	_add_deco_ground(&"terrain/cave_shroom", 3140.0, FLOOR_Y + 140.0, 0.8,
		Color(0.8, 0.4, 0.9))
	_add_rest(3170.0, &"ch1_cave_secret", FLOOR_Y + 140.0 - 4)
	_add_chest(3250.0, FLOOR_Y + 140.0)

	# === GECIT DEKORU — harabe mezarlik yolu ===
	# Oluler diyari hissi: mezar taslari, kuru agaclar, kapi nobetcisi heykelleri
	_add_deco_ground(&"prop/deadtree_1", 3380, FLOOR_Y, 0.55,
		Color(0.5, 0.42, 0.48))
	_add_deco_ground(&"prop/deadtree_3", 3900, FLOOR_Y, 0.5,
		Color(0.45, 0.38, 0.44))
	_add_deco_ground(&"prop/deadtree_2", 4300, FLOOR_Y, 0.5,
		Color(0.5, 0.4, 0.45), true)
	for spec in [[3520.0, &"prop/grave_1"], [3630.0, &"prop/grave_2"],
			[3980.0, &"prop/grave_3"], [4150.0, &"prop/grave_2"],
			[4340.0, &"prop/grave_1"]]:
		_add_deco_ground(spec[1], spec[0], FLOOR_Y, 0.85,
			Color(0.7, 0.62, 0.6))
	
	# Mahzen Ici Dekoru
	var decor_crypt_y := FLOOR_Y + 160.0
	_add_deco_ground(&"prop/statue", 3870, decor_crypt_y, 0.7, Color(0.4, 0.4, 0.5))
	_add_deco_ground(&"prop/grave_3", 3670, decor_crypt_y, 0.85, Color(0.6, 0.5, 0.5))
	_add_rest(3900, &"ch1_gate_secret", decor_crypt_y - 4)
	_add_chest(3940, decor_crypt_y)
	_add_shard(3750, decor_crypt_y - 128, &"ch1_crypt")

	# Ust Rota Dekoru (yosun, heykel kiriklari vb)
	_add_deco(&"prop/moss", Vector2(3650, 148), 0.7, Color(0.5, 0.45, 0.4))
	_add_deco(&"prop/moss", Vector2(3860, 148), 0.7, Color(0.5, 0.45, 0.4))
	# Torii kapi — sovalye olmeden kapali (kapi cercevesi zemine oturur)
	var torii := _add_deco_ground(&"prop/deco_gate", GATE_X, FLOOR_Y, 1.0,
		Color(1.15, 0.62, 0.5))
	if torii != null:
		_gate_sprite = torii
	# Kapiyi koruyan nobetci heykeller
	_add_deco_ground(&"prop/statue", GATE_X - 95, FLOOR_Y, 0.62,
		Color(0.75, 0.65, 0.7))
	_add_deco_ground(&"prop/statue", GATE_X + 95, FLOOR_Y, 0.62,
		Color(0.75, 0.65, 0.7), true)
	_gate_body = StaticBody2D.new()
	_gate_body.collision_layer = 1
	var gc := CollisionShape2D.new()
	var gr := RectangleShape2D.new()
	gr.size = Vector2(30, 120)
	gc.shape = gr
	_gate_body.add_child(gc)
	_gate_body.global_position = Vector2(GATE_X, FLOOR_Y - 62)
	add_child(_gate_body)
	# Kapali kapinin gorunur engeli — tugla surgu torii icinde
	if AssetLoader.has_asset(&"prop/deco_barrier"):
		var door := Sprite2D.new()
		var btex := AssetLoader.tiled_texture(&"prop/deco_barrier", Vector2i(30, 120))
		door.texture = btex
		door.modulate = Color(0.55, 0.4, 0.42)
		_gate_body.add_child(door)

	# Arena girisi: nobetci heykeller + ic duvarlar
	_add_deco_ground(&"prop/statue", ARENA_L - 34, FLOOR_Y, 0.7,
		Color(0.7, 0.5, 0.55))
	_add_deco_ground(&"prop/statue", ARENA_R + 34, FLOOR_Y, 0.7,
		Color(0.7, 0.5, 0.55), true)
	for wx in [ARENA_L, ARENA_R]:
		var wall := StaticBody2D.new()
		wall.collision_layer = 0  # tetikten once kapali
		var col := CollisionShape2D.new()
		var rect := RectangleShape2D.new()
		rect.size = Vector2(18, 160)
		col.shape = rect
		wall.add_child(col)
		wall.global_position = Vector2(wx, FLOOR_Y - 80)
		_arena_walls.append(wall)
		add_child(wall)


func _build_entities() -> void:
	samurai = Samurai.new()
	var spawn := Vector2(80, FLOOR_Y - 20)
	var cp: Vector2 = GameState.respawn_point(Vector2(-10000, -10000))
	if cp.x > -5000.0:
		spawn = cp + Vector2(0, -14)
	samurai.global_position = spawn
	add_child(samurai)

	# A — koy: kukla (güvenli saldiri denemesi) + uc koylu dalgasi
	var dummy := DummyEnemy.new()
	dummy.global_position = Vector2(452, FLOOR_Y - 12)
	add_child(dummy)
	for x in [620.0, 800.0, 900.0]:
		var v := Villager.new()
		v.global_position = Vector2(x, FLOOR_Y - 12)
		add_child(v)
	# Koy cikisi mini-encounter: pazar sonu muhafiz (ilk parry dersi)
	# Guard oyuncudan korkan koylulerden farkli davranir — onden gelmeli
	var market_guard := Guard.new()
	market_guard.global_position = Vector2(980.0, FLOOR_Y - 12)
	add_child(market_guard)

	# B — orman: mantarlar + kaplumbaga + ikinci koylu dalgasi
	for x in [1120.0, 1290.0]:
		var m := SplitMushroom.new()
		m.global_position = Vector2(x, FLOOR_Y - 12)
		add_child(m)
	var t1 := Turtle.new()
	t1.global_position = Vector2(1650, FLOOR_Y - 12)
	add_child(t1)
	var t_forest2 := Turtle.new()
	t_forest2.global_position = Vector2(1780, FLOOR_Y - 12)
	add_child(t_forest2)
	for x in [1900.0, 2200.0]:
		var v := Villager.new()
		v.global_position = Vector2(x, FLOOR_Y - 12)
		add_child(v)
	
	# Orman Ust Rota (Gizli Tapinak): Muhafiz hayalet
	var ghost := Ghost.new()
	ghost.global_position = Vector2(2000, 135 - 12)
	add_child(ghost)

	_add_rest(2250, &"ch1_forest")

	# C — magara: diken tarlasi + hayalet + kaplumbaga
	_add_spikes(2590, 2810, FLOOR_Y - 2)
	var t2 := Turtle.new()
	t2.global_position = Vector2(2660, 190)
	add_child(t2)
	for x in [2400.0, 2960.0]:
		var g := Ghost.new()
		g.global_position = Vector2(x, FLOOR_Y - 40)
		add_child(g)
	
	# Kristal odasi muhafizlari
	for x in [3100.0, 3230.0]:
		var m := SplitMushroom.new()
		m.global_position = Vector2(x, FLOOR_Y + 140.0 - 12)
		add_child(m)

	# D — gecit: ikili muhafiz + agir sovalye (kapi kilidi)
	for x in [3720.0, 3920.0]:
		var gd := Guard.new()
		gd.global_position = Vector2(x, FLOOR_Y - 12)
		add_child(gd)
		
	# Ust Rota Muhafizi
	var upper_guard := Guard.new()
	upper_guard.global_position = Vector2(3760, 120 - 12)
	add_child(upper_guard)

	# Mezarlik cehennem kedisi — yuzeyde hizli devriye
	var cat := Hellcat.new()
	cat.global_position = Vector2(3550, FLOOR_Y - 10)
	add_child(cat)
	
	# Alt Mahzen: hayalet + gomulu iskeletler (mezarlik pusu)
	var crypt_ghost := Ghost.new()
	crypt_ghost.global_position = Vector2(3800, FLOOR_Y + 160.0 - 12)
	add_child(crypt_ghost)
	for x in [3690.0, 3890.0]:
		var sk := CryptSkeleton.new()
		sk.global_position = Vector2(x, FLOOR_Y + 160.0 - 12)
		add_child(sk)

	# Kripta mini-boss: Undead Executioner + imp yancilari
	var exec := Executioner.new()
	exec.global_position = Vector2(3920, FLOOR_Y + 160.0 - 20)
	add_child(exec)
	for x in [3760.0, 3940.0]:
		var imp := ImpRed.new()
		imp.global_position = Vector2(x, FLOOR_Y + 160.0 - 10)
		add_child(imp)

	# Orman cikisi eliti: DuskBorne buyucusu
	var druid := Druid.new()
	druid.global_position = Vector2(2260, FLOOR_Y - 16)
	add_child(druid)

	# Magara yarasa + ucan kilic (Dark Fantasy / Legacy Vania)
	for x in [2560.0, 3060.0]:
		var bat := CaveBat.new()
		bat.global_position = Vector2(x, FLOOR_Y - 80)
		add_child(bat)
	var sword := FlyingSword.new()
	sword.global_position = Vector2(3260, FLOOR_Y - 90)
	add_child(sword)

	# Gecit yaklasimi: mezara gomulu iskeletler (yaklasinca yukselir)
	for x in [3450.0, 3630.0, 3900.0, 4320.0]:
		var gsk := CryptSkeleton.new()
		gsk.global_position = Vector2(x, FLOOR_Y - 10)
		add_child(gsk)
	var demon := DemonAxe.new()
	demon.global_position = Vector2(3980, FLOOR_Y - 12)
	add_child(demon)
	var crow := Crow.new()
	crow.global_position = Vector2(4150, FLOOR_Y - 70)
	add_child(crow)

	_add_rest(4050, &"ch1_gate")
	knight = HeavyKnight.new()
	knight.grants_form = &"sovalye"
	knight.global_position = Vector2(4230, FLOOR_Y - 14)
	add_child(knight)
	knight.health.died.connect(_open_gate, CONNECT_ONE_SHOT)

	# E — arena + boss (uyurken tetik bekler)
	boss = LordCluck.new()
	boss.name = "LordCluck"
	boss.arena_root = self
	boss.global_position = Vector2(4780, FLOOR_Y - 16)
	add_child(boss)
	_boss_home = boss.global_position
	boss.defeated.connect(_on_boss_defeated, CONNECT_ONE_SHOT)

	# Arena tetigi duvarin ICINDE — oyuncu tamamen girince kapanir
	var trigger := Area2D.new()
	trigger.collision_layer = 0
	trigger.collision_mask = 4
	var tc := CollisionShape2D.new()
	var tr := RectangleShape2D.new()
	tr.size = Vector2(10, 160)
	tc.shape = tr
	trigger.add_child(tc)
	trigger.global_position = Vector2(ARENA_TRIGGER, FLOOR_Y - 60)
	trigger.area_entered.connect(_on_arena_entered)
	add_child(trigger)

	# Sapka hirsizi cameo'su: sovalye gecilince kapi onunde kisa gorunum,
	# sonra kacip kaybolur — kelimesiz anlatimda hedef hatirlatmasi.
	var cameo_trig := Area2D.new()
	cameo_trig.collision_layer = 0
	cameo_trig.collision_mask = 4
	var cc := CollisionShape2D.new()
	var cr := RectangleShape2D.new()
	cr.size = Vector2(30, 80)
	cc.shape = cr
	cameo_trig.add_child(cc)
	cameo_trig.global_position = Vector2(4360, FLOOR_Y - 40)
	cameo_trig.area_entered.connect(_on_thief_cameo, CONNECT_ONE_SHOT)
	add_child(cameo_trig)


func _build_fx() -> void:
	camera = ScreenShake.new()
	camera.global_position = Vector2(240, 135)
	camera.limit_left = 0
	camera.limit_right = int(LEVEL_W)
	camera.limit_top = 0
	camera.limit_bottom = int(FLOOR_Y + 190)  # yeralti odalari icin derinlik
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 6.0
	add_child(camera)
	camera.make_current()

	var fx := FxListener.new()
	fx.camera_path = camera.get_path()
	add_child(fx)
	add_child(PostFX.new())
	add_child(SettingsMenu.new())

	# Bolge bazli hava: koy+ormanda kiraz petali, gecitte hafif yagmur
	var weather := WeatherFx.new()
	add_child(weather)
	weather.setup(camera, [
		{x0 = 0.0,    x1 = 2300.0, kind = "petals"},
		{x0 = 3350.0, x1 = 4500.0, kind = "rain"},
	])


func _build_hud() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)

	# HK-vari HUD: portre + oni-maske kalpler + katana ruh olceri
	layer.add_child(HudPlayer.make(samurai))

	var boss_bar := HudBars.make(170, 9, Color(0.9, 0.3, 0.35))
	boss_bar.root.position = Vector2(155, 248)
	layer.add_child(boss_bar.root)
	_boss_root = boss_bar.root
	_boss_root.visible = false
	_boss_bar = boss_bar.fill
	if AssetLoader.has_asset(&"ui/bar_frame"):
		var bfr := TextureRect.new()
		bfr.texture = AssetLoader.texture(&"ui/bar_frame")
		bfr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		bfr.stretch_mode = TextureRect.STRETCH_SCALE
		bfr.size = Vector2(170, 9)
		boss_bar.root.add_child(bfr)
	# Boss adi etiketi — barin ustunde
	var bn := Label.new()
	bn.text = "LORD CLUCK"
	bn.add_theme_font_size_override("font_size", 8)
	bn.add_theme_color_override("font_color", Color(0.95, 0.85, 0.6))
	bn.position = Vector2(0, -12)
	bn.size = Vector2(170, 10)
	bn.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	boss_bar.root.add_child(bn)
	boss.health.damaged.connect(
		func(_a: int, _r: int) -> void:
			_boss_root.visible = true
			_boss_bar.visible = true)


# --- Boss / kapi akisi ---

func _open_gate() -> void:
	GameState.set_flag(&"ch1_knight_dead")
	if _gate_body != null:
		_gate_body.set_deferred("collision_layer", 0)
		var tw := _gate_body.create_tween()
		tw.tween_property(_gate_body, "modulate:a", 0.0, 0.4)
	Pictogram.show_on(samurai, &"dots", 1.2, Vector2(0, -30))
	AudioManager.play_sfx(&"sfx/door", Vector2(GATE_X, FLOOR_Y - 40))


func _on_thief_cameo(area: Area2D) -> void:
	var p := area.get_parent()
	while p != null and not p.is_in_group(&"player"):
		p = p.get_parent()
	if p == null:
		return
	ThiefCameo.spawn(self, Vector2(4470, FLOOR_Y - 14))


func _on_arena_entered(area: Area2D) -> void:
	var p := area.get_parent()
	while p != null and not p.is_in_group(&"player"):
		p = p.get_parent()
	if p == null or _boss_started:
		return
	_boss_started = true
	for w in _arena_walls:
		w.set_deferred("collision_layer", 1)
		var ws := Sprite2D.new()
		if AssetLoader.has_asset(&"prop/deco_barrier"):
			ws.texture = AssetLoader.texture(&"prop/deco_barrier")
		else:
			ws.texture = AssetLoader.tiled_texture(&"terrain/cave_bricks", Vector2i(18, 160))
		ws.modulate = Color(0.8, 0.5, 0.45)
		w.add_child(ws)
		ws.scale = Vector2(1.0, 0.0)
		ws.create_tween().set_trans(Tween.TRANS_BACK) \
			.tween_property(ws, "scale", Vector2.ONE, 0.3)
		_arena_wall_sprites.append(ws)
	FX.glitch(0.7, 0.7)
	FX.shake(2.0, 0.3)
	AudioManager.play_music(&"music/ch1_boss")
	_boss_intro()


func _boss_intro() -> void:
	# HK tarzi kisa intro: boss kabarip kukrer, isim+belirir, sonra savas acilir.
	if is_instance_valid(boss):
		Pictogram.show_on(boss, &"anger", 1.3, Vector2(0, -30))
		var s: Node2D = boss.anims if boss.anims != null else boss.sprite
		if s != null:
			var base: Vector2 = s.scale
			var tw := s.create_tween()
			tw.tween_property(s, "scale", base * 1.28, 0.35).set_trans(Tween.TRANS_BACK)
			tw.tween_property(s, "scale", base, 0.25)
		AudioManager.play_sfx(&"sfx/npc_grunt_3", boss.global_position)
	_boss_root.visible = true
	_boss_bar.size.x = 160.0
	await get_tree().create_timer(1.15).timeout
	if is_instance_valid(boss) and boss.health.is_alive() and _boss_started:
		boss.activate()


func _on_boss_defeated() -> void:
	GameState.unlock_form(&"tavuk")
	GameState.set_flag(&"ch1_boss_dead")
	var creature := Node2D.new()
	creature.global_position = boss.global_position + Vector2(0, -30)
	add_child(creature)
	var cs := Sprite2D.new()
	cs.texture = AssetLoader.texture(&"enemy/glitch_creature", Vector2i(16, 14))
	cs.modulate = Color(0.05, 0.05, 0.1)
	creature.add_child(cs)
	for dx in [-3.0, 3.0]:
		var eye := ColorRect.new()
		eye.size = Vector2(2, 3)
		eye.position = Vector2(dx - 1, -4)
		eye.color = Color(0.4, 1.0, 0.9)
		creature.add_child(eye)
	var portal := PortalFx.make()
	portal.global_position = Vector2(ARENA_R - 30, FLOOR_Y - 34)
	add_child(portal)
	AudioManager.play_music(&"music/victory")

	samurai.sm.change_to(Samurai.S_CUTSCENE, true)
	var cutscene := CutscenePlayer.new()
	add_child(cutscene)
	cutscene.play([
		{op = "glitch", strength = 1.0, dur = 1.0},
		{op = "wait", t = 0.5},
		{op = "hop_to", node = "creature", to = samurai.global_position + Vector2(10, -20), dur = 0.5, arc = 40.0},
		{op = "picto", node = "samurai", icon = &"alarm", t = 0.9, wait = true},
		{op = "hop_to", node = "creature", to = portal.global_position, dur = 0.5, arc = 30.0},
		{op = "call", fn = func() -> void:
			creature.create_tween().tween_property(creature, "scale", Vector2.ZERO, 0.3)},
		{op = "walk_to", node = "samurai", x = portal.global_position.x - 8, speed = 130.0},
		{op = "call", fn = func() -> void:
			samurai.create_tween().tween_property(samurai, "modulate:a", 0.0, 0.25)},
		{op = "wait", t = 0.3},
	], {"samurai": samurai, "creature": creature, "portal": portal},
	func() -> void:
		samurai.global_position = portal.global_position)
	cutscene.finished.connect(_go_ch2, CONNECT_ONE_SHOT)


func _go_ch2() -> void:
	GameState.set_flag(&"ch1_done")
	GameState.current_chapter = &"ch2"
	if auto_advance:
		EventBus.scene_change_requested.emit(CH2_PATH)


func _on_actor_died(actor: Node) -> void:
	if actor != samurai or _respawn_pending:
		return
	_respawn_pending = true
	AudioManager.play_sfx(&"sfx/gameover", samurai.global_position)
	FX.glitch(0.6, 0.5)
	await SceneRouter.fade_to(1.0, 0.7)
	await get_tree().create_timer(0.3, true).timeout
	var cp: Vector2 = GameState.respawn_point(Vector2(80, FLOOR_Y - 20))
	samurai.global_position = cp + Vector2(0, -14)
	samurai.velocity = Vector2.ZERO
	samurai.health.reset()
	samurai.modulate.a = 1.0
	samurai.sm.change_to(Samurai.S_IDLE, true)
	_respawn_pending = false
	await SceneRouter.fade_to(0.0, 0.45)
	_reset_boss_fight()


## Bossa olunce arena sifirlanir: duvarlar iner, boss dogdugu yere
## doner, tetik yeniden ateslenebilir (HK tarzi yeniden deneme).
func _reset_boss_fight() -> void:
	if not _boss_started or not is_instance_valid(boss) \
			or not boss.health.is_alive():
		return
	_boss_started = false
	for w in _arena_walls:
		w.set_deferred("collision_layer", 0)
	for ws in _arena_wall_sprites:
		ws.queue_free()
	_arena_wall_sprites.clear()
	_boss_root.visible = false
	boss.reset_fight(_boss_home)
	AudioManager.play_music(&"music/ch1_gate")
	AudioManager.play_ambience(&"amb/wind")
