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
var creature_sprite: Sprite2D
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

	var wall := ColorRect.new()
	wall.color = Color(0.16, 0.12, 0.13)
	wall.position = Vector2(40, 60)
	wall.size = Vector2(400, FLOOR_Y - 60)
	add_child(wall)
	# Gercek ahşap doku — Modern Interiors oda kurucu tileset
	if AssetLoader.has_asset(&"terrain/cabin_wall"):
		var wtex := TextureRect.new()
		wtex.texture = AssetLoader.tiled_texture(
			&"terrain/cabin_wall", Vector2i(400, FLOOR_Y - 60))
		wtex.position = wall.position
		wtex.size = wall.size
		wtex.modulate = Color(0.5, 0.4, 0.42)  # gece kulube tonu
		add_child(wtex)

	var floor_rect := ColorRect.new()
	floor_rect.color = Color(0.22, 0.16, 0.11)
	floor_rect.position = Vector2(0, FLOOR_Y)
	floor_rect.size = Vector2(480, 270 - FLOOR_Y)
	add_child(floor_rect)
	if AssetLoader.has_asset(&"terrain/cabin_floor"):
		var ftex := TextureRect.new()
		ftex.texture = AssetLoader.tiled_texture(
			&"terrain/cabin_floor", Vector2i(480, 270 - FLOOR_Y))
		ftex.position = floor_rect.position
		ftex.size = floor_rect.size
		ftex.modulate = Color(0.55, 0.4, 0.35)
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

	# TV sehpasi + CRT govde — gercek mobilya dokulari
	var table := ColorRect.new()
	table.color = Color(0.28, 0.2, 0.12)
	table.position = Vector2(108, 210)
	table.size = Vector2(56, 26)
	add_child(table)
	if AssetLoader.has_asset(&"prop/furn_table"):
		var ttex := TextureRect.new()
		ttex.texture = AssetLoader.tiled_texture(
			&"prop/furn_table", Vector2i(56, 26))
		ttex.position = table.position
		ttex.size = table.size
		ttex.modulate = Color(0.75, 0.6, 0.55)
		add_child(ttex)
	var tv := ColorRect.new()
	tv.color = Color(0.2, 0.2, 0.22)
	tv.position = Vector2(110, 172)
	tv.size = Vector2(52, 40)
	add_child(tv)

	# Mobilyalar: futon yatak, kitaplik, raf, hali, lamba, tabure
	var furn_specs := [
		{ id = &"prop/furn_bed", pos = Vector2(24, FLOOR_Y - 19), mod = Color(0.7, 0.55, 0.5) },
		{ id = &"prop/furn_books", pos = Vector2(392, FLOOR_Y - 20), mod = Color(0.75, 0.6, 0.55) },
		{ id = &"prop/furn_shelf", pos = Vector2(436, FLOOR_Y - 32), mod = Color(0.75, 0.6, 0.55) },
		{ id = &"prop/furn_rug", pos = Vector2(170, FLOOR_Y - 3), mod = Color(0.8, 0.55, 0.5) },
		{ id = &"prop/furn_lamp", pos = Vector2(460, FLOOR_Y - 20), mod = Color(1.0, 0.85, 0.6) },
		{ id = &"prop/furn_stool", pos = Vector2(330, FLOOR_Y - 17), mod = Color(0.75, 0.6, 0.55) },
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
	screen.position = Vector2(113, 175)
	screen.scale = Vector2(46.0 / CrtGame.VIEW.x, 34.0 / CrtGame.VIEW.y)
	add_child(screen)

	# Duvardaki katana
	katana = Sprite2D.new()
	katana.texture = AssetLoader.placeholder_texture("prop/katana", Vector2i(3, 26))
	katana.modulate = Color(0.8, 0.85, 0.95)
	katana.rotation = -0.5
	katana.global_position = Vector2(352, 150)
	add_child(katana)


func _build_actors() -> void:
	samurai = Samurai.new()
	samurai.tuning = tuning
	samurai.global_position = Vector2(215, FLOOR_Y - 2)
	add_child(samurai)
	samurai.set_input_source(AIInputSource.new())
	samurai.facing = -1
	samurai.sprite.flip_h = true
	# Oturma goruntusu: sprite hafif yassiltilir
	samurai.sprite.scale = Vector2(1.15, 0.7)
	if samurai._anims != null:
		samurai._anims.scale = Vector2(1.05, 0.82)
	samurai.sm.change_to(Samurai.S_CUTSCENE, true)

	# Sapka — samurayin basinda duran ayri node (calinacak)
	hat = Sprite2D.new()
	hat.texture = AssetLoader.texture(&"prop/hat", Vector2i(22, 10))
	hat.position = Vector2(2, -26)   # kasa, bas ustunde
	samurai.add_child(hat)

	# Glitch Yaratik — CRT'den cikacak
	creature = Node2D.new()
	creature.name = "Creature"
	creature.visible = false
	creature.global_position = Vector2(136, 178)
	add_child(creature)
	creature_sprite = Sprite2D.new()
	creature_sprite.texture = AssetLoader.placeholder_texture(
		"enemy/glitch_creature", Vector2i(16, 14))
	creature_sprite.modulate = Color(0.05, 0.05, 0.1)
	creature.add_child(creature_sprite)
	# Gozler
	for dx in [-3.0, 3.0]:
		var eye := ColorRect.new()
		eye.size = Vector2(2, 3)
		eye.position = Vector2(dx - 1, -4)
		eye.color = Color(0.4, 1.0, 0.9)
		creature.add_child(eye)

	# Portal — son adimda acilir
	portal = Node2D.new()
	portal.name = "Portal"
	portal.visible = false
	portal.global_position = Vector2(400, FLOOR_Y - 30)
	add_child(portal)
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
