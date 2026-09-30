extends Node2D
## M3 Prolog — kulube sahnesi (DEVIN_PLAN §5, M3).
## Samuray CRT'de mini oyun oynar (oyuncu gercekten oynar) -> glitch ->
## Glitch Yaratik cikar, sapkayi calar, slapstick kovalamaca, katana alinir,
## portala dalis -> Bolum 1. Metinsiz; Esc ile atlanabilir.

const CH1_PATH := "res://src/levels/ch1/Ch1.tscn"
const FLOOR_Y := 236.0

## Testlerde gercek sahne gecisini kapatmak icin.
@export var auto_advance := true
## Demo/test icin oyun fazi suresini kisaltma (0 = tuning degerleri).
@export var fast_mode := false

var samurai: Samurai
var crt_vp: SubViewport
var crt_game: CrtGame
var creature: Node2D
var creature_sprite: Node2D
var hat: Sprite2D
var katana: Sprite2D
var portal: Node2D
var black: ColorRect
var cutscene: CutscenePlayer
var camera: ScreenShake
var tuning: Tuning

var _phase := &"boot"  # boot -> play -> cutscene -> done
var _play_time := 0.0


func _ready() -> void:
	tuning = load("res://config/tuning.tres")
	GameState.current_chapter = &"prolog"
	AudioManager.play_music(&"music/prolog")
	_build_room()
	_build_actors()
	_build_fx()
	_start_sequence()


func _process(delta: float) -> void:
	if _phase != &"play":
		return
	_play_time += delta
	var need_time: float = (tuning.prolog_min_play_time * 0.35) if fast_mode \
		else tuning.prolog_min_play_time
	var need_dodges: int = mini(tuning.prolog_min_dodges, 2) if fast_mode \
		else tuning.prolog_min_dodges
	# Oyuncu en az N engel atlattiysa ve sure dolduysa glitch baslar;
	# oyuncu hic oynamazsa 1.8x surede yine de gecer (seyir modu).
	if (_play_time >= need_time and crt_game.dodged >= need_dodges) \
			or _play_time >= need_time * 1.8:
		crt_game.glitch_out()


# --- Kurulum ---

func _build_room() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.07, 0.05, 0.09)
	bg.size = Vector2(480, 270)
	add_child(bg)

	# Japon ic mekan duvari — gercek ahsap panel dokusu
	var wall := ColorRect.new()
	wall.color = Color(0.16, 0.12, 0.13)
	wall.position = Vector2(20, 40)
	wall.size = Vector2(440, FLOOR_Y - 40)
	add_child(wall)
	var wall_id := &"tex/j_wall" if AssetLoader.has_asset(&"tex/j_wall") \
		else &"terrain/cabin_wall"
	if AssetLoader.has_asset(wall_id):
		var wtex := TextureRect.new()
		wtex.texture = AssetLoader.tiled_texture(
			wall_id, Vector2i(440, FLOOR_Y - 40))
		wtex.position = wall.position
		wtex.size = wall.size
		wtex.stretch_mode = TextureRect.STRETCH_TILE
		wtex.modulate = Color(0.85, 0.72, 0.68)
		add_child(wtex)

	var floor_rect := ColorRect.new()
	floor_rect.color = Color(0.22, 0.16, 0.11)
	floor_rect.position = Vector2(0, FLOOR_Y)
	floor_rect.size = Vector2(480, 270 - FLOOR_Y)
	add_child(floor_rect)
	var floor_id := &"tex/j_floor" if AssetLoader.has_asset(&"tex/j_floor") \
		else &"terrain/cabin_floor"
	if AssetLoader.has_asset(floor_id):
		var ftex := TextureRect.new()
		ftex.texture = AssetLoader.tiled_texture(
			floor_id, Vector2i(480, 270 - FLOOR_Y))
		ftex.position = floor_rect.position
		ftex.size = floor_rect.size
		ftex.stretch_mode = TextureRect.STRETCH_TILE
		ftex.modulate = Color(0.9, 0.78, 0.7)
		add_child(ftex)

	# Fizik zemini
	var body := StaticBody2D.new()
	body.collision_layer = 1
	var col := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(480, 30)
	col.shape = rect
	body.add_child(col)
	body.position = Vector2(240, FLOOR_Y + 15)
	add_child(body)

	# Duvar susleri: parşömenler, kirmizi armagan bayragi, parlayan
	# kagit fenerler (referans ic mekandaki gibi)
	var deco_specs := [
		{ id = &"prop/shoji",    pos = Vector2(56, 96), mod = Color(0.95, 0.9, 0.85) },
		{ id = &"prop/scroll_a", pos = Vector2(118, 80), mod = Color(1, 0.92, 0.82) },
		{ id = &"prop/moonwin",  pos = Vector2(432, 88), mod = Color(0.95, 0.9, 0.85) },
		{ id = &"prop/scroll_b", pos = Vector2(392, 80), mod = Color(1, 0.92, 0.82) },
		{ id = &"prop/banner",   pos = Vector2(228, 62), mod = Color(1, 0.9, 0.85) },
		{ id = &"prop/lantern_hang",  pos = Vector2(96, 62), mod = Color(1.05, 0.95, 0.85) },
		{ id = &"prop/lantern_hang2", pos = Vector2(378, 62), mod = Color(1.05, 0.95, 0.85) },
	]
	for f in deco_specs:
		if not AssetLoader.has_asset(f.id):
			continue
		var ds := Sprite2D.new()
		ds.texture = AssetLoader.texture(f.id)
		var ts := ds.texture.get_size()
		ds.offset = Vector2(-ts.x / 2.0, 0)  # tavandan asili
		ds.position = f.pos
		ds.modulate = f.mod
		add_child(ds)

	# Mobilyalar: kalabalik raf + dama dolap + yanan fener sagda;
	# masa + caydanlik + mum solda, hali ortada — referans kompozisyon
	var furn_specs := [
		{ id = &"prop/shelf_big",  pos = Vector2(430, FLOOR_Y - 2), mod = Color(1, 0.9, 0.85) },
		{ id = &"prop/cabinet",    pos = Vector2(28, FLOOR_Y - 2),  mod = Color(0.95, 0.82, 0.72) },
		{ id = &"prop/lantern3",   pos = Vector2(390, FLOOR_Y - 2), mod = Color(1.02, 0.95, 0.85) },
		{ id = &"prop/vase",       pos = Vector2(80, FLOOR_Y - 2),  mod = Color(0.95, 0.85, 0.8) },
		{ id = &"prop/table",      pos = Vector2(196, FLOOR_Y - 2), mod = Color(0.95, 0.85, 0.75) },
		{ id = &"prop/furn_rug",   pos = Vector2(196, FLOOR_Y - 3), mod = Color(0.85, 0.62, 0.55) },
		{ id = &"prop/candle",     pos = Vector2(330, FLOOR_Y - 2), mod = Color(1.02, 0.95, 0.85) },
		{ id = &"prop/kettle",     pos = Vector2(150, FLOOR_Y - 2), mod = Color(0.9, 0.8, 0.75) },
	]
	for f in furn_specs:
		if not AssetLoader.has_asset(f.id):
			continue
		var fs := Sprite2D.new()
		fs.texture = AssetLoader.texture(f.id)
		var ts := fs.texture.get_size()
		# Ayak hizasi: sprite'in alti zemine oturur
		fs.offset = Vector2(-ts.x / 2.0, -ts.y)
		fs.position = f.pos
		fs.modulate = f.mod
		add_child(fs)

	# CRT TV — gercek j_tv sprite'i; SubViewport ekrani ustune bindirilir
	var tv_pos := Vector2(112, FLOOR_Y - 2)
	var tv_screen := Rect2(114, 178, 46, 34)  # fallback ekran bolgesi
	if AssetLoader.has_asset(&"prop/crt_tv"):
		var tv := Sprite2D.new()
		tv.texture = AssetLoader.texture(&"prop/crt_tv")
		var ts := tv.texture.get_size()
		tv.offset = Vector2(-ts.x / 2.0, -ts.y)
		tv.position = tv_pos
		add_child(tv)
		# ekran bolgesini sprite oranina gore olcekle
		var sw: float = min(46.0, ts.x * 0.62)
		var sh: float = sw * 34.0 / 46.0
		tv_screen = Rect2(tv_pos.x - ts.x * 0.30, tv_pos.y - ts.y * 0.72, sw, sh)
	else:
		var table := ColorRect.new()
		table.color = Color(0.28, 0.2, 0.12)
		table.position = Vector2(108, 210)
		table.size = Vector2(56, 26)
		add_child(table)
		var tv := ColorRect.new()
		tv.color = Color(0.2, 0.2, 0.22)
		tv.position = Vector2(110, 172)
		tv.size = Vector2(52, 40)
		add_child(tv)

	# CRT ekrani: SubViewport icinde mini oyun
	crt_vp = SubViewport.new()
	crt_vp.size = CrtGame.VIEW
	crt_vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	crt_vp.handle_input_locally = false
	add_child(crt_vp)
	crt_game = CrtGame.new()
	crt_game.tuning = tuning
	crt_vp.add_child(crt_game)
	var screen := Sprite2D.new()
	screen.texture = crt_vp.get_texture()
	screen.centered = false
	screen.position = tv_screen.position
	screen.scale = Vector2(tv_screen.size.x / CrtGame.VIEW.x,
		tv_screen.size.y / CrtGame.VIEW.y)
	add_child(screen)

	# Duvardaki kilic rafi + alinacak katana
	var rack_id := &"prop/sword_rack" if AssetLoader.has_asset(&"prop/sword_rack") \
		else &"prop/katana_rack"
	if AssetLoader.has_asset(rack_id):
		var rack := Sprite2D.new()
		rack.texture = AssetLoader.texture(rack_id)
		var rs := rack.texture.get_size()
		rack.offset = Vector2(-rs.x / 2.0, -rs.y / 2.0)
		rack.global_position = Vector2(352, 150)
		add_child(rack)
	# Raf uzerinde duran, alinacak katana — gercek katana goruntusu
	katana = Sprite2D.new()
	if AssetLoader.has_asset(&"ui/hud_katana"):
		katana.texture = AssetLoader.texture(&"ui/hud_katana")
		katana.scale = Vector2(26.0 / katana.texture.get_size().x,
			26.0 / katana.texture.get_size().x)
	else:
		katana.texture = AssetLoader.texture(&"prop/katana", Vector2i(3, 26))
	katana.modulate = Color(0.9, 0.92, 1.0)
	katana.rotation = -0.12
	katana.global_position = Vector2(352, 146)
	add_child(katana)


func _build_actors() -> void:
	samurai = Samurai.new()
	samurai.tuning = tuning
	samurai.global_position = Vector2(215, FLOOR_Y - 2)
	add_child(samurai)
	samurai.set_input_source(AIInputSource.new())
	samurai.facing = -1
	samurai.sprite.flip_h = true
	samurai.sm.change_to(Samurai.S_CUTSCENE, true)
	# Oturma goruntusu: gercek oturan-samuray sprite'i varsa onu goster,
	# ayakta duran animasyonu oyun fazi bitene kadar gizle.
	if AssetLoader.has_asset(&"prop/player_sit"):
		var sit := Sprite2D.new()
		sit.name = "SitSprite"
		sit.texture = AssetLoader.texture(&"prop/player_sit")
		var ss := sit.texture.get_size()
		sit.offset = Vector2(-ss.x / 2.0, -ss.y)
		sit.scale = Vector2(1.4, 1.4)
		sit.flip_h = true
		samurai.add_child(sit)
		if samurai._anims != null:
			samurai._anims.visible = false
		samurai.sprite.visible = false
	else:
		samurai.sprite.scale = Vector2(1.15, 0.7)
		if samurai._anims != null:
			samurai._anims.scale = Vector2(1.05, 0.82)

	# Sapka — samurayin basinda duran ayri node (calinacak)
	hat = Sprite2D.new()
	hat.texture = AssetLoader.texture(&"prop/hat", Vector2i(22, 10))
	hat.position = Vector2(2, -26)   # kasa, bas ustunde
	samurai.add_child(hat)

	# Glitch Yaratik — CRT'den cikacak; gercek mor hayalet animasyonu
	creature = Node2D.new()
	creature.name = "Creature"
	creature.visible = false
	creature.global_position = Vector2(136, 178)
	add_child(creature)
	var gframes := AssetLoader.frames(&"enemy/glitch/idle")
	if gframes != null and gframes.get_frame_count(&"default") > 0:
		var ganims := AnimatedSprite2D.new()
		ganims.sprite_frames = gframes
		ganims.scale = Vector2(0.42, 0.42)
		ganims.play(&"default")
		creature.add_child(ganims)
		creature_sprite = ganims
	else:
		creature_sprite = Sprite2D.new()
		creature_sprite.texture = AssetLoader.texture(&"enemy/glitch_creature", Vector2i(16, 14))
		creature_sprite.modulate = Color(0.3, 0.1, 0.5)
		creature.add_child(creature_sprite)

	# Portal — son adimda acilir; gercek rift goruntusu
	portal = Node2D.new()
	portal.name = "Portal"
	portal.visible = false
	portal.global_position = Vector2(400, FLOOR_Y - 30)
	add_child(portal)
	if AssetLoader.has_asset(&"prop/rift"):
		var rs := Sprite2D.new()
		rs.texture = AssetLoader.texture(&"prop/rift")
		var ts2 := rs.texture.get_size()
		rs.scale = Vector2(40.0 / ts2.x, 40.0 / ts2.x)
		portal.add_child(rs)
	else:
		for i in 3:
			var ring := ColorRect.new()
			var s := 34 - i * 9
			ring.size = Vector2(s * 0.6, s)
			ring.position = -ring.size / 2.0
			ring.color = Color(0.3 + i * 0.2, 0.7, 1.0 - i * 0.25, 0.55)
			portal.add_child(ring)


func _build_fx() -> void:
	camera = ScreenShake.new()
	camera.global_position = Vector2(240, 135)
	camera.limit_left = 0
	camera.limit_right = 480
	add_child(camera)
	camera.make_current()

	var fx := FxListener.new()
	fx.camera_path = camera.get_path()
	add_child(fx)
	add_child(PostFX.new())
	add_child(SettingsMenu.new())

	black = ColorRect.new()
	black.color = Color.BLACK
	black.size = Vector2(480, 270)
	var layer := CanvasLayer.new()
	layer.layer = 50
	layer.add_child(black)
	add_child(layer)


# --- Prolog akisi ---

func _start_sequence() -> void:
	# glitch sinyali fade-in'den once baglanir — test/hizli modda
	# glitch_out() fade sirasinda da cagrilabilir.
	crt_game.glitched.connect(_begin_cutscene, CONNECT_ONE_SHOT)
	var tw := create_tween()
	tw.tween_property(black, "modulate:a", 0.0, 1.2)
	await tw.finished
	if _phase == &"boot":
		_phase = &"play"


func _begin_cutscene() -> void:
	if _phase == &"cutscene" or _phase == &"done":
		return
	_phase = &"cutscene"
	samurai.sprite.scale = Vector2.ONE  # ayaga kalkti
	samurai.sprite.position.y = 0.0
	var sit := samurai.get_node_or_null("SitSprite")
	if sit != null:
		sit.queue_free()
		samurai.sprite.visible = true
		if samurai._anims != null:
			samurai._anims.visible = true

	var ctx := {
		"samurai": samurai, "creature": creature, "hat": hat,
		"katana": katana, "portal": portal, "black": black,
	}
	cutscene = CutscenePlayer.new()
	add_child(cutscene)
	cutscene.play(_steps(), ctx, _apply_end_state)
	cutscene.finished.connect(_finish_prolog, CONNECT_ONE_SHOT)


func _steps() -> Array:
	return [
		# Yaratik CRT'den sizar
		{op = "glitch", strength = 1.0, dur = 1.2},
		{op = "call", fn = func() -> void: creature.visible = true},
		{op = "wait", t = 0.4},
		{op = "picto", node = "samurai", icon = &"alarm", t = 1.0, wait = true},
		# Sapka kapisi! Yaratic ziplayip sapkayi alir
		{op = "hop_to", node = "creature", to = samurai.global_position + Vector2(0, -16), dur = 0.45, arc = 40.0},
		{op = "call", fn = _steal_hat},
		{op = "hop_to", node = "creature", to = Vector2(300, 150), dur = 0.5, arc = 50.0},
		{op = "picto", node = "samurai", icon = &"question", t = 0.9, wait = true},
		# Kovalamaca — slapstick: samuray kayip duser
		{op = "walk_to", node = "samurai", x = 295.0, speed = 130.0},
		{op = "hop_to", node = "creature", to = Vector2(370, 170), dur = 0.45, arc = 45.0},
		{op = "call", fn = _slip_samurai},
		{op = "picto", node = "samurai", icon = &"anger", t = 0.8, wait = true},
		{op = "wait", t = 0.3},
		{op = "call", fn = _stand_samurai},
		# Katana alinir
		{op = "walk_to", node = "samurai", x = 348.0, speed = 110.0},
		{op = "call", fn = _take_katana},
		{op = "picto", node = "samurai", icon = &"sword", t = 1.0, wait = true},
		# Portal acilir, yaratik dalip kacar
		{op = "glitch", strength = 0.8, dur = 0.8},
		{op = "call", fn = func() -> void: portal.visible = true},
		{op = "hop_to", node = "creature", to = portal.global_position, dur = 0.5, arc = 30.0},
		{op = "call", fn = func() -> void:
			var tw := creature.create_tween()
			tw.tween_property(creature, "scale", Vector2.ZERO, 0.3)},
		{op = "wait", t = 0.4},
		# Samuray da dalar
		{op = "hop_to", node = "samurai", to = portal.global_position + Vector2(0, 20), dur = 0.5, arc = 35.0},
		{op = "call", fn = func() -> void:
			var tw := samurai.create_tween()
			tw.tween_property(samurai, "modulate:a", 0.0, 0.25)},
		{op = "flag", key = &"prolog_done", value = true},
		{op = "fade", node = "black", to_a = 1.0, dur = 0.6},
	]


func _steal_hat() -> void:
	var wp := hat.global_position
	samurai.remove_child(hat)
	creature.add_child(hat)
	hat.global_position = wp
	var tw := hat.create_tween()
	tw.tween_property(hat, "position", Vector2(0, -12), 0.2)
	GameState.set_flag(&"hat_stolen")


func _slip_samurai() -> void:
	FX.shake(tuning.shake_heavy, 0.3)
	var tw := samurai.create_tween()
	tw.tween_property(samurai.sprite, "rotation", -PI / 2.2, 0.15)
	tw.parallel().tween_property(samurai.sprite, "position:y", 4.0, 0.15)


func _stand_samurai() -> void:
	var tw := samurai.create_tween()
	tw.tween_property(samurai.sprite, "rotation", 0.0, 0.2)
	tw.parallel().tween_property(samurai.sprite, "position:y", 0.0, 0.2)


func _take_katana() -> void:
	katana.visible = false
	GameState.set_flag(&"has_katana")


## Skip'te son duruma zipla: portal acik, sapka yaratikta, katana alinmis.
func _apply_end_state() -> void:
	creature.visible = false
	portal.visible = true
	katana.visible = false
	samurai.sprite.rotation = 0.0
	samurai.sprite.position.y = 0.0
	samurai.sprite.scale = Vector2.ONE
	samurai.sprite.visible = true
	if samurai._anims != null:
		samurai._anims.visible = true
	var sit := samurai.get_node_or_null("SitSprite")
	if sit != null:
		sit.queue_free()
	samurai.global_position = portal.global_position + Vector2(0, 20)
	samurai.modulate.a = 0.0
	black.modulate.a = 1.0
	GameState.set_flag(&"hat_stolen")
	GameState.set_flag(&"has_katana")
	GameState.set_flag(&"prolog_done")


func _finish_prolog() -> void:
	_phase = &"done"
	GameState.set_flag(&"prolog_done")
	GameState.current_chapter = &"ch1"
	if auto_advance:
		EventBus.scene_change_requested.emit(CH1_PATH)
