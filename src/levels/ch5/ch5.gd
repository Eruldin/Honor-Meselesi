extends Node2D
## M8 — Bolum 5: Kul Diyari + Kul Muhafizi.
## Coken boyutlarin kuluna donusmus ovasi: moloz zemin, pasli variller,
## huysuz kovanlar ve dalis yapan yarasslar. Form odulu yok — bu bolumde
## yaratik'in pesine dusen samuray sadece atmosferle ve kalintilarla
## konusur. Arena -> Kul Muhafizi -> portal -> Bolum 6.

const CH6_PATH := "res://src/levels/ch6/Ch6.tscn"
const FLOOR_Y := 250.0
const LEVEL_W := 1700.0
const ARENA_X := 1290.0
const ARENA_L := 1300.0
const ARENA_R := 1600.0

@export var auto_advance := true

var samurai: Samurai
var camera: ScreenShake
var boss: AshGuardian
var _walls: Array[StaticBody2D] = []
var _boss_bar: Control
var _boss_root: Control
var _player_fill: Control
var _hud_label: Label
var _boss_started := false
var _respawn_pending := false


func _ready() -> void:
	GameState.current_chapter = &"ch5"
	AudioManager.play_music(&"music/ch5")
	_build_terrain()
	_build_entities()
	_build_fx()
	_build_hud()
	EventBus.actor_died.connect(_on_actor_died)


func _process(_delta: float) -> void:
	if samurai != null and is_instance_valid(samurai):
		camera.global_position.x = clampf(samurai.global_position.x, 240, LEVEL_W - 240)
	if boss != null and is_instance_valid(boss) and boss.active:
		_boss_root.visible = true
		_boss_bar.size.x = 160.0 * float(boss.health.current) / maxf(boss.health.max_health, 1)
	if samurai != null and _player_fill != null:
		_player_fill.size.x = 90.0 * float(samurai.health.current) / maxf(samurai.health.max_health, 1)
	if samurai != null and _hud_label != null:
		_hud_label.text = "can %d/%d  form %s" % [
			samurai.health.current, samurai.health.max_health,
			samurai.form.id if samurai.form != null else "?"]


func _build_terrain() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.32, 0.28, 0.3)  # kul grisi-mor gokyuzu
	bg.size = Vector2(LEVEL_W, 270)
	add_child(bg)
	ParallaxBg.add(self, LEVEL_W, [
		{id = &"bg/ash_sky", scroll = 0.0, modulate = Color(0.8, 0.72, 0.68)},
		{id = &"bg/ash_far", scroll = 0.15, modulate = Color(0.72, 0.62, 0.58)},
	])

	# Moloz zemin (Garbage tileset bolgesi doseme)
	_add_ground(Vector2(LEVEL_W / 2, FLOOR_Y + 10), Vector2(LEVEL_W, 24), &"terrain/ash_ground")
	_add_ground(Vector2(-6, 135), Vector2(12, 270))
	# Yikik yukseltiler
	_add_ground(Vector2(430, 196), Vector2(70, 10), &"terrain/ash_ground")
	_add_ground(Vector2(690, 178), Vector2(80, 10), &"terrain/ash_ground")
	_add_ground(Vector2(950, 196), Vector2(70, 10), &"terrain/ash_ground")
	_add_ground(Vector2(1120, 182), Vector2(64, 10), &"terrain/ash_ground")

	# Coken zemin kirigi (dusen parca — gerilim)
	for gx in [560.0, 1010.0]:
		var crack := CrackedGround.new()
		crack.global_position = Vector2(gx, FLOOR_Y - 6)
		add_child(crack)

	# Kalinti susleri: pasli variller, eski lastikler, kirilmis bank
	var prop_pos: Array = [
		[150, &"prop/barrel_rust"], [155, &"prop/barrel_rust"],
		[380, &"prop/tires"], [520, &"prop/barrel_rust"],
		[740, &"prop/bench"], [880, &"prop/tires"],
		[1080, &"prop/barrel_rust"], [1240, &"prop/bench"],
	]
	for pp in prop_pos:
		var s := Sprite2D.new()
		s.texture = AssetLoader.texture(pp[1], Vector2i(14, 14))
		s.global_position = Vector2(pp[0], FLOOR_Y - 9)
		add_child(s)

	for wx in [ARENA_L - 14, ARENA_R + 8]:
		var wall := _make_wall(Vector2(wx, 135))
		wall.set_deferred("collision_layer", 0)
		wall.visible = false
		_walls.append(wall)
		add_child(wall)


func _make_wall(center: Vector2) -> StaticBody2D:
	var body := StaticBody2D.new()
	body.collision_layer = 1
	var col := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(16, 270)
	col.shape = rect
	body.add_child(col)
	body.global_position = center
	return body


func _add_ground(center: Vector2, size: Vector2, tex_id := StringName()) -> void:
	var body := StaticBody2D.new()
	body.collision_layer = 1
	var col := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = size
	col.shape = rect
	body.add_child(col)
	var sprite := Sprite2D.new()
	if tex_id != &"" and AssetLoader.has_asset(tex_id):
		sprite.texture = AssetLoader.tiled_texture(tex_id, Vector2i(size))
	else:
		sprite.texture = AssetLoader.tiled_texture(&"terrain/ch5_ground", Vector2i(size))
		sprite.modulate = Color(0.42, 0.38, 0.36)
	body.add_child(sprite)
	body.global_position = center
	add_child(body)


func _build_entities() -> void:
	samurai = Samurai.new()
	var spawn := Vector2(60, FLOOR_Y - 20)
	var cp: Variant = GameState.get_flag(&"respawn_pos", false)
	if cp is Vector2:
		spawn = cp + Vector2(0, -14)
	samurai.global_position = spawn
	add_child(samurai)

	# Kul kovanlari — surunen balta zombileri
	for hx in [330.0, 640.0, 900.0, 1160.0]:
		var h := AshHusk.new()
		h.global_position = Vector2(hx, FLOOR_Y - 12)
		add_child(h)
	# Kul yarasslari — yukseklik cesitli
	for bp in [Vector2(480, 160), Vector2(820, 150), Vector2(1090, 155)]:
		var b := AshBat.new()
		b.global_position = bp
		add_child(b)

	var rest := RestPoint.new()
	rest.checkpoint_id = &"ch5_ruins"
	rest.global_position = Vector2(1230, FLOOR_Y - 12)
	add_child(rest)

	boss = AshGuardian.new()
	boss.name = "KulMuhafizi"
	boss.arena_root = self
	boss.arena_left = ARENA_L
	boss.arena_right = ARENA_R
	boss.floor_y = FLOOR_Y
	boss.global_position = Vector2(1500, FLOOR_Y - 16)
	add_child(boss)
	boss.defeated.connect(_on_boss_defeated, CONNECT_ONE_SHOT)

	var trigger := Area2D.new()
	trigger.collision_layer = 0
	trigger.collision_mask = 4
	var tc := CollisionShape2D.new()
	var tr := RectangleShape2D.new()
	tr.size = Vector2(10, 200)
	tc.shape = tr
	trigger.add_child(tc)
	trigger.global_position = Vector2(ARENA_X, 170)
	trigger.area_entered.connect(_on_arena_entered)
	add_child(trigger)


func _build_fx() -> void:
	camera = ScreenShake.new()
	camera.global_position = Vector2(240, 135)
	camera.limit_left = 0
	camera.limit_right = int(LEVEL_W)
	camera.limit_top = 0
	camera.limit_bottom = 270
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 6.0
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
	_hud_label.position = Vector2(6, 4)
	_hud_label.add_theme_font_size_override("font_size", 8)
	layer.add_child(_hud_label)
	var pb := HudBars.make(90, 7, Color(0.8, 0.25, 0.3))
	pb.root.position = Vector2(6, 16)
	layer.add_child(pb.root)
	_player_fill = pb.fill
	var boss_bar := HudBars.make(160, 6, Color(0.7, 0.5, 0.4))
	boss_bar.root.position = Vector2(160, 250)
	layer.add_child(boss_bar.root)
	_boss_root = boss_bar.root
	_boss_root.visible = false
	_boss_bar = boss_bar.fill


func _on_arena_entered(area: Area2D) -> void:
	var p := area.get_parent()
	while p != null and not p.is_in_group(&"player"):
		p = p.get_parent()
	if p == null or _boss_started:
		return
	_boss_started = true
	for w in _walls:
		w.set_deferred("collision_layer", 1)
		w.visible = true
	FX.glitch(0.55, 0.6)
	AudioManager.play_music(&"music/ch5_boss")
	boss.activate()


func _on_boss_defeated() -> void:
	GameState.set_flag(&"ch5_boss_dead")
	await get_tree().create_timer(1.4, true).timeout
	var portal := PortalFx.make(Vector2(24, 40), &"fx/portal_dark")
	portal.global_position = Vector2(ARENA_R - 30, FLOOR_Y - 34)
	add_child(portal)
	AudioManager.play_music(&"music/victory")

	samurai.sm.change_to(Samurai.S_CUTSCENE, true)
	var cutscene := CutscenePlayer.new()
	add_child(cutscene)
	cutscene.play([
		{op = "glitch", strength = 0.8, dur = 0.9},
		{op = "wait", t = 0.4},
		{op = "walk_to", node = "samurai", x = portal.global_position.x - 8, speed = 120.0},
		{op = "call", fn = func() -> void:
			samurai.create_tween().tween_property(samurai, "modulate:a", 0.0, 0.25)},
		{op = "wait", t = 0.3},
	], {"samurai": samurai, "portal": portal},
	func() -> void:
		samurai.global_position = portal.global_position)
	cutscene.finished.connect(_go_ch6, CONNECT_ONE_SHOT)


func _go_ch6() -> void:
	GameState.set_flag(&"ch5_done")
	GameState.current_chapter = &"ch6"
	if auto_advance:
		EventBus.scene_change_requested.emit(CH6_PATH)


func _on_actor_died(actor: Node) -> void:
	if actor != samurai or _respawn_pending:
		return
	_respawn_pending = true
	await get_tree().create_timer(1.4, true).timeout
	var cp: Variant = GameState.get_flag(&"respawn_pos", Vector2(60, FLOOR_Y - 20))
	samurai.global_position = cp + Vector2(0, -14)
	samurai.velocity = Vector2.ZERO
	samurai.set_gravity_flipped(false)
	samurai.health.reset()
	samurai.modulate.a = 1.0
	samurai.sm.change_to(Samurai.S_IDLE, true)
	_respawn_pending = false
