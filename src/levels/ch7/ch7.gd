extends Node2D
## M10 — Bolum 7: Bosluk/Final. Perspektif kaymasi:
## Oyuncu aslinda Glitch Yaratik — samuray (kasa geri almis) final boss
## olarak onunla savasir. Yenilgi -> Ouroboros: yaratik kasayi geri
## birakip CRT'ye siner -> sahne Prolog'a doner (dongu kapanir).

const PROLOG_PATH := "res://src/levels/prolog/Prolog.tscn"
const FLOOR_Y := 250.0

@export var auto_advance := true

var samurai: Samurai            ## giris cutscene'i icin (sonra boss'a cevrilir)
var creature: GlitchCreature    ## oyuncu — perspektif kaymasi sonrasi
var boss: SamuraiBoss
var camera: ScreenShake
var _player_fill: Control
var _hud_label: Label
var _boss_bar: Control
var _boss_root: Control
var _respawn_pending := false
var _hat_prop: Sprite2D
var _black: ColorRect


func _ready() -> void:
	GameState.current_chapter = &"ch7"
	AudioManager.play_music(&"music/ch7")
	_build_terrain()
	_build_fx()
	_build_hud()
	EventBus.actor_died.connect(_on_actor_died)
	if auto_advance:
		_run_intro()
	else:
		_spawn_fight()  # testler icin dogrudan savas


func _process(_delta: float) -> void:
	if boss != null and is_instance_valid(boss) and boss.active:
		_boss_root.visible = true
		_boss_bar.size.x = 160.0 * float(boss.health.current) / maxf(boss.health.max_health, 1)
	if creature != null and _player_fill != null:
		_player_fill.size.x = 90.0 * float(creature.health.current) / maxf(creature.health.max_health, 1)


func _build_terrain() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.05, 0.04, 0.11)  # bosluk siyahi-moru (okunabilir)
	bg.size = Vector2(480, 270)
	add_child(bg)
	# Uzak katman — kirik bellek artiklari, soluk mor parilti
	ParallaxBg.add(self, 480, [
		{id = &"bg/ash_far", scroll = 0.05, modulate = Color(0.6, 0.5, 0.9, 0.7)},
		{id = &"bg/ash_sky", scroll = 0.12, modulate = Color(0.5, 0.5, 0.85, 0.5)},
	])
	# Tek genis platform — boslukta asili
	var body := StaticBody2D.new()
	body.collision_layer = 1
	var col := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(360, 20)
	col.shape = rect
	body.add_child(col)
	body.global_position = Vector2(240, FLOOR_Y + 8)
	add_child(body)
	var sp := Sprite2D.new()
	sp.texture = AssetLoader.tiled_texture(&"terrain/ash_ground", Vector2i(360, 20))
	sp.modulate = Color(0.6, 0.55, 0.9)
	sp.global_position = body.global_position
	add_child(sp)
	# Karaltma perdesi (cutscene fade icin)
	_black = ColorRect.new()
	_black.color = Color.BLACK
	_black.size = Vector2(480, 270)
	_black.modulate.a = 0.0
	_black.z_index = 60
	add_child(_black)


func _spawn_fight() -> void:
	# Perspektif: oyuncu = Glitch Yaratik (solda, ufak), samuray = boss
	creature = GlitchCreature.new()
	creature.global_position = Vector2(150, FLOOR_Y - 10)
	creature.set_input_source(PlayerInputSource.new())
	add_child(creature)

	boss = SamuraiBoss.new()
	boss.name = "Samurai"
	boss.arena_root = self
	boss.arena_left = 60.0
	boss.arena_right = 420.0
	boss.global_position = Vector2(330, FLOOR_Y - 16)
	add_child(boss)
	boss.defeated.connect(_on_boss_defeated, CONNECT_ONE_SHOT)
	boss.activate()


func _run_intro() -> void:
	# Samuray bosluga girer; ortada kasayi tutan yaratik bekler
	samurai = Samurai.new()
	samurai.global_position = Vector2(40, FLOOR_Y - 20)
	add_child(samurai)

	_hat_prop = Sprite2D.new()
	_hat_prop.texture = AssetLoader.texture(&"prop/hat", Vector2i(22, 12))
	# Kasa, kucuk karanlik kutlenin ustunde (prolog yaratik gorunumu)
	var blob := Node2D.new()
	blob.name = "HatCreature"
	var bs := Sprite2D.new()
	bs.texture = AssetLoader.placeholder_texture("enemy/glitch_creature", Vector2i(16, 14))
	bs.modulate = Color(0.05, 0.05, 0.12)
	blob.add_child(bs)
	for dx in [-3.0, 3.0]:
		var eye := ColorRect.new()
		eye.size = Vector2(2, 3)
		eye.position = Vector2(dx - 1, -4)
		eye.color = Color(0.4, 1.0, 0.9)
		bs.add_child(eye)
	_hat_prop.position = Vector2(0, -9)
	blob.add_child(_hat_prop)
	blob.global_position = Vector2(300, FLOOR_Y - 8)
	add_child(blob)

	samurai.sm.change_to(Samurai.S_CUTSCENE, true)
	var cs := CutscenePlayer.new()
	add_child(cs)
	cs.play([
		{op = "wait", t = 0.6},
		{op = "walk_to", node = "samurai", x = 230, speed = 60.0},
		{op = "picto", node = "samurai", icon = &"alarm", t = 1.0, wait = true},
		# Yaratik kasayi samuraya geri verir — ve dunya kafamizin ustune ters doner
		{op = "hop_to", node = "HatCreature", to = Vector2(280, FLOOR_Y - 40),
			dur = 0.4, arc = 18.0},
		{op = "call", fn = func() -> void:
			_hat_prop.get_parent().remove_child(_hat_prop)
			samurai.add_child(_hat_prop)
			_hat_prop.position = Vector2(0, -24)},
		{op = "wait", t = 0.4},
		{op = "glitch", strength = 1.4, dur = 1.4},
		{op = "fade", node = "black", to_a = 1.0, dur = 0.5},
		{op = "call", fn = func() -> void:
			# Perspektif kaymasi: samuray sahneden boss'a donusur,
			# oyuncu yaratigi kontrol eder
			samurai.queue_free()
			blob.queue_free()
			_spawn_fight()},
		{op = "wait", t = 0.3},
		{op = "fade", node = "black", to_a = 0.0, dur = 0.8},
	], {"samurai": samurai, "HatCreature": blob, "black": _black})


func _on_boss_defeated() -> void:
	GameState.set_flag(&"ch7_boss_dead")
	AudioManager.play_sfx(&"sfx/gameover")
	await get_tree().create_timer(1.8, true).timeout
	# Ouroboros: yaratik kasayi birakip CRT isigina siner -> Prolog
	var cs := CutscenePlayer.new()
	add_child(cs)
	cs.play([
		{op = "glitch", strength = 1.5, dur = 1.6},
		{op = "hop_to", node = "creature", to = Vector2(240, FLOOR_Y - 30),
			dur = 0.6, arc = 20.0},
		{op = "call", fn = func() -> void:
			var hat := Sprite2D.new()
			hat.texture = AssetLoader.texture(&"prop/hat", Vector2i(22, 12))
			hat.position = Vector2(0, -9)
			creature.add_child(hat)},
		{op = "wait", t = 0.6},
		{op = "fade", node = "black", to_a = 1.0, dur = 1.0},
		{op = "glitch", strength = 1.6, dur = 1.0},
	], {"creature": creature, "black": _black},
	func() -> void:
		GameState.set_flag(&"ouroboros_done", true))
	cs.finished.connect(_finish, CONNECT_ONE_SHOT)


func _finish() -> void:
	# Dongu kapanir — jenerik yazisi sonra Prolog'a don
	AudioManager.play_music(&"music/credits")
	var layer := CanvasLayer.new()
	add_child(layer)
	var label := Label.new()
	label.text = "SAMSARA — dongu kapanir."
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.set_anchors_preset(Control.PRESET_CENTER)
	label.add_theme_font_size_override("font_size", 14)
	label.add_theme_color_override("font_color", Color(0.8, 0.9, 1.0))
	layer.add_child(label)
	await get_tree().create_timer(3.0, true).timeout
	if auto_advance:
		EventBus.scene_change_requested.emit(PROLOG_PATH)


func _on_actor_died(actor: Node) -> void:
	if actor != creature or _respawn_pending:
		return
	_respawn_pending = true
	await get_tree().create_timer(1.4, true).timeout
	creature.global_position = Vector2(150, FLOOR_Y - 10)
	creature.velocity = Vector2.ZERO
	creature.health.reset()
	creature.dead = false
	creature.sprite.scale = Vector2.ONE
	creature.sprite.modulate = Color(0.05, 0.05, 0.12)
	_respawn_pending = false


func _build_fx() -> void:
	camera = ScreenShake.new()
	camera.global_position = Vector2(240, 135)
	camera.limit_left = 0
	camera.limit_right = 480
	camera.limit_top = 0
	camera.limit_bottom = 270
	add_child(camera)
	camera.make_current()
	var fx := FxListener.new()
	fx.camera_path = camera.get_path()
	add_child(fx)
	add_child(PostFX.new())
	add_child(SettingsMenu.new())


func _build_hud() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	_hud_label = Label.new()
	_hud_label.text = "sen: glitch yaratik"
	_hud_label.position = Vector2(6, 4)
	_hud_label.add_theme_font_size_override("font_size", 8)
	layer.add_child(_hud_label)
	var pb := HudBars.make(90, 7, Color(0.4, 1.0, 0.9))
	pb.root.position = Vector2(6, 16)
	layer.add_child(pb.root)
	_player_fill = pb.fill
	var bb := HudBars.make(160, 6, Color(0.9, 0.4, 0.3))
	bb.root.position = Vector2(160, 250)
	layer.add_child(bb.root)
	_boss_root = bb.root
	_boss_root.visible = false
	_boss_bar = bb.fill
