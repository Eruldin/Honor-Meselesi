extends Node2D
## M9 — Bolum 6: Parcalanmis Bellek + Glitch Amalgam.
## Coken boyutlarin kirintilari havada yuzen adaciklar gibi durur;
## platformlar "unutulup" geri gelir (FlickerPlatform), onceki
## bolumlerin dusmanlari soluk cyan yankilar olarak dolanir.
## Burada glitch serbest — senaryo geregi (CRT disinda tek bolge).

const CH7_PATH := "res://src/levels/ch7/Ch7.tscn"
const FLOOR_Y := 250.0
const LEVEL_W := 1700.0
const ARENA_X := 1300.0
const ARENA_L := 1310.0
const ARENA_R := 1610.0

@export var auto_advance := true

var samurai: Samurai
var camera: ScreenShake
var boss: GlitchAmalgam
var _walls: Array[StaticBody2D] = []
var _boss_bar: Control
var _boss_root: Control
var _player_fill: Control
var _hud_label: Label
var _boss_started := false
var _respawn_pending := false
var _glitch_t := 6.0


func _ready() -> void:
	GameState.current_chapter = &"ch6"
	AudioManager.play_music(&"music/ch6")
	_build_terrain()
	_build_entities()
	_build_fx()
	_build_hud()
	EventBus.actor_died.connect(_on_actor_died)


func _process(delta: float) -> void:
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
	# Ortam glitch'i: ara ara hafif dalgalanma (bu bolume ozel)
	_glitch_t -= delta
	if _glitch_t <= 0.0:
		_glitch_t = randf_range(5.0, 9.0)
		FX.glitch(0.25, 0.5)


func _build_terrain() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.09, 0.07, 0.16)  # derin bosluk moru
	bg.size = Vector2(LEVEL_W, 270)
	add_child(bg)
	# Uzakta kirik boyut goruntuleri — ash_far katmani cyan-magenta'da
	ParallaxBg.add(self, LEVEL_W, [
		{id = &"bg/ash_far", scroll = 0.08, modulate = Color(0.5, 0.55, 0.95, 0.85)},
		{id = &"bg/ash_sky", scroll = 0.2, modulate = Color(0.55, 0.6, 0.95, 0.7)},
	])

	# Ana zemin parcalari — araliklarla (bellek boslugu): ucus tehlikesi
	for seg in [[240, FLOOR_Y + 10, 480], [800, FLOOR_Y + 10, 330],
			[1300, FLOOR_Y + 10, 620]]:
		_add_ground(Vector2(seg[0], seg[1]), Vector2(seg[2], 24))
	_add_ground(Vector2(-6, 135), Vector2(12, 270))

	# FlickerPlatform'lar — bosluklari asma yollari
	for fp in [[480, 210, 0.0], [560, 190, 1.2], [660, 200, 2.3],
			[960, 205, 0.6], [1050, 185, 1.8], [1140, 198, 3.0]]:
		var f := FlickerPlatform.new()
		f.global_position = Vector2(fp[0], fp[1])
		f.phase_offset = fp[2]
		add_child(f)

	# Kirik boyut parcalari — onceki bolumlerin tile dokularindan adaciklar
	for frag in [[180, 120, &"terrain/ash_ground", Color(0.7, 0.7, 1.0)],
			[720, 110, &"terrain/block", Color(0.7, 0.8, 1.0)],
			[1150, 100, &"terrain/ash_ground", Color(0.6, 0.7, 1.1)],
			[1450, 95, &"terrain/block", Color(0.7, 0.7, 1.0)]]:
		var s := Sprite2D.new()
		s.texture = AssetLoader.tiled_texture(frag[2], Vector2i(48, 18))
		s.modulate = frag[3]
		s.global_position = Vector2(frag[0], frag[1])
		s.rotation = randf_range(-0.06, 0.06)
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


func _add_ground(center: Vector2, size: Vector2) -> void:
	var body := StaticBody2D.new()
	body.collision_layer = 1
	var col := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = size
	col.shape = rect
	body.add_child(col)
	var sprite := Sprite2D.new()
	sprite.texture = AssetLoader.tiled_texture(&"terrain/ash_ground", Vector2i(size))
	sprite.modulate = Color(0.75, 0.72, 1.0)
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

	# Bellek yankilari — onceki bolumlerin dusmanlari, cyan soluk
	var echoes: Array = [
		[Villager.new(), 300], [CyberNinja.new(), 540],
		[Villager.new(), 830], [AshHusk.new(), 1050],
		[Turtle.new(), 1190],
	]
	for e in echoes:
		var en: EnemyBase = e[0]
		en.modulate = Color(0.6, 0.95, 1.1, 0.85)
		en.global_position = Vector2(e[1], FLOOR_Y - 12)
		add_child(en)

	var rest := RestPoint.new()
	rest.checkpoint_id = &"ch6_shards"
	rest.global_position = Vector2(1260, FLOOR_Y - 12)
	add_child(rest)

	boss = GlitchAmalgam.new()
	boss.name = "GlitchAmalgam"
	boss.arena_root = self
	boss.arena_left = ARENA_L
	boss.arena_right = ARENA_R
	boss.floor_y = FLOOR_Y
	boss.global_position = Vector2(1520, FLOOR_Y - 16)
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
	var boss_bar := HudBars.make(160, 6, Color(0.4, 0.9, 1.0))
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
	FX.glitch(0.9, 0.8)
	AudioManager.play_music(&"music/ch6_boss")
	boss.activate()


func _on_boss_defeated() -> void:
	GameState.set_flag(&"ch6_boss_dead")
	await get_tree().create_timer(1.6, true).timeout
	var portal := PortalFx.make()
	portal.global_position = Vector2(ARENA_R - 30, FLOOR_Y - 34)
	add_child(portal)
	AudioManager.play_music(&"music/victory")

	samurai.sm.change_to(Samurai.S_CUTSCENE, true)
	var cutscene := CutscenePlayer.new()
	add_child(cutscene)
	cutscene.play([
		{op = "glitch", strength = 1.2, dur = 1.2},
		{op = "wait", t = 0.4},
		{op = "walk_to", node = "samurai", x = portal.global_position.x - 8, speed = 120.0},
		{op = "call", fn = func() -> void:
			samurai.create_tween().tween_property(samurai, "modulate:a", 0.0, 0.25)},
		{op = "wait", t = 0.3},
	], {"samurai": samurai, "portal": portal},
	func() -> void:
		samurai.global_position = portal.global_position)
	cutscene.finished.connect(_go_ch7, CONNECT_ONE_SHOT)


func _go_ch7() -> void:
	GameState.set_flag(&"ch6_done")
	GameState.current_chapter = &"ch7"
	if auto_advance:
		EventBus.scene_change_requested.emit(CH7_PATH)


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
