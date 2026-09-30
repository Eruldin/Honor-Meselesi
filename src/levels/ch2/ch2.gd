extends Node2D
## M5 — Bolum 2: Cyberpunk + Unit-0.
## Neon sokak: siber-hirsizlar -> ucan dronlar -> terminal bulmacasi
## (Drone formu gerekir; debug amacli oyuncuya drone acik degil —
## terminal yaninda DroneAcar dusmani birakir) -> dev koruma -> arena
## -> Unit-0 (parry ile zirh kirma) -> Glitch Yaratik -> Bolum 3.

const CH3_PATH := "res://src/levels/ch3/Ch3.tscn"
const FLOOR_Y := 250.0
const LEVEL_W := 1600.0
const ARENA_X := 1300.0
const ARENA_L := 1310.0
const ARENA_R := 1580.0

## Drone formunu level icinde acan dusurucu (test odasi disinda).
@export var grant_drone_to_player := true
@export var auto_advance := true

var samurai: Samurai
var camera: ScreenShake
var boss: Unit0
var _walls: Array[StaticBody2D] = []
var _boss_bar: Control
var _boss_root: Control
var _player_fill: Control
var _hud_label: Label
var _boss_started := false
var _respawn_pending := false


func _ready() -> void:
	GameState.current_chapter = &"ch2"
	AudioManager.play_music(&"music/ch2")
	if grant_drone_to_player:
		GameState.unlock_form(&"drone")
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
		_boss_bar.visible = true
		_boss_bar.size.x = 160.0 * float(boss.health.current) / maxf(boss.health.max_health, 1)
	if samurai != null and _player_fill != null:
		_player_fill.size.x = 90.0 * float(samurai.health.current) / maxf(samurai.health.max_health, 1)
	if samurai != null and _hud_label != null:
		_hud_label.text = "can %d/%d  form %s" % [
			samurai.health.current, samurai.health.max_health,
			samurai.form.id if samurai.form != null else "?"]


func _build_terrain() -> void:
	var sky := ColorRect.new()
	sky.color = Color(0.03, 0.09, 0.14)
	sky.size = Vector2(LEVEL_W, 270)
	add_child(sky)
	# Warped City parallax'i — neon gece
	ParallaxBg.add(self, LEVEL_W, [
		{id = &"bg/warped_sky", scroll = 0.0},
		{id = &"bg/warped_far", scroll = 0.18, modulate = Color(0.75, 0.8, 1.0)},
		{id = &"bg/warped_near", scroll = 0.4, modulate = Color(0.7, 0.75, 1.0)},
	])

	# Neon tabela siluetleri
	for i in 9:
		var sign_ := ColorRect.new()
		sign_.color = [Color(0.2, 0.8, 1.0), Color(1.0, 0.3, 0.7),
			Color(0.4, 1.0, 0.6)][i % 3] * 0.5
		sign_.position = Vector2(80.0 + i * 170.0, 60.0 + (i % 3) * 26.0)
		sign_.size = Vector2(34, 10 + (i % 2) * 8)
		add_child(sign_)

	_add_ground(Vector2(LEVEL_W / 2, FLOOR_Y + 10), Vector2(LEVEL_W, 24))
	_add_ground(Vector2(-6, 135), Vector2(12, 270))
	_add_ground(Vector2(300, 190), Vector2(80, 8))
	_add_ground(Vector2(760, 185), Vector2(90, 8))
	_add_ground(Vector2(1050, 195), Vector2(70, 8))

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
	sprite.texture = AssetLoader.texture(&"terrain/ch2_ground", Vector2i(size))
	sprite.modulate = Color(0.15, 0.3, 0.4)
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

	var n1 := CyberNinja.new()
	n1.global_position = Vector2(400, FLOOR_Y - 12)
	add_child(n1)

	var d1 := DroneEnemy.new()
	d1.global_position = Vector2(600, FLOOR_Y - 60)
	add_child(d1)

	# Orius devriye piyade
	var s1 := Soldier.new()
	s1.variant = 1
	s1.global_position = Vector2(500, FLOOR_Y - 12)
	add_child(s1)
	var mg := MachineGuy.new()
	mg.global_position = Vector2(700, FLOOR_Y - 13)
	add_child(mg)

	# Terminal + lazer kapi bulmacasi
	var term := HackTerminal.new()
	term.gate_id = &"ch2_gate1"
	term.global_position = Vector2(780, FLOOR_Y - 14)
	add_child(term)
	var gate := LaserGate.new()
	gate.gate_id = &"ch2_gate1"
	gate.size = Vector2(8, 70)
	gate.global_position = Vector2(900, FLOOR_Y - 35)
	add_child(gate)

	var n2 := CyberNinja.new()
	n2.global_position = Vector2(960, FLOOR_Y - 12)
	add_child(n2)

	var rest := RestPoint.new()
	rest.checkpoint_id = &"ch2_shrine"
	rest.global_position = Vector2(1100, FLOOR_Y - 12)
	add_child(rest)

	var s2 := Soldier.new()
	s2.variant = 3
	s2.global_position = Vector2(1150, FLOOR_Y - 12)
	add_child(s2)

	var gd := Guardian.new()
	gd.global_position = Vector2(1200, FLOOR_Y - 18)
	add_child(gd)

	boss = Unit0.new()
	boss.name = "Unit0"
	boss.arena_root = self
	boss.global_position = Vector2(1520, FLOOR_Y - 18)
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
	var pb := HudBars.make(90, 7, Color(0.4, 0.8, 1.0))
	pb.root.position = Vector2(6, 16)
	layer.add_child(pb.root)
	_player_fill = pb.fill
	var boss_bar := HudBars.make(160, 6, Color(0.4, 0.8, 1.0))
	boss_bar.root.position = Vector2(160, 250)
	layer.add_child(boss_bar.root)
	_boss_root = boss_bar.root
	_boss_root.visible = false
	_boss_bar = boss_bar.fill
	_boss_bar.visible = false


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
	FX.glitch(0.7, 0.7)
	AudioManager.play_music(&"music/ch2_boss")
	boss.activate()


func _on_boss_defeated() -> void:
	GameState.unlock_form(&"robot")
	GameState.set_flag(&"ch2_boss_dead")
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
		{op = "picto", node = "samurai", icon = &"dots", t = 1.0, wait = true},
		{op = "walk_to", node = "samurai", x = portal.global_position.x - 8, speed = 130.0},
		{op = "call", fn = func() -> void:
			samurai.create_tween().tween_property(samurai, "modulate:a", 0.0, 0.25)},
		{op = "wait", t = 0.3},
	], {"samurai": samurai, "portal": portal},
	func() -> void:
		samurai.global_position = portal.global_position)
	cutscene.finished.connect(_go_ch3, CONNECT_ONE_SHOT)


func _go_ch3() -> void:
	GameState.set_flag(&"ch2_done")
	GameState.current_chapter = &"ch3"
	if auto_advance:
		EventBus.scene_change_requested.emit(CH3_PATH)


func _on_actor_died(actor: Node) -> void:
	if actor != samurai or _respawn_pending:
		return
	_respawn_pending = true
	await get_tree().create_timer(1.4, true).timeout
	var cp: Variant = GameState.get_flag(&"respawn_pos", Vector2(60, FLOOR_Y - 20))
	samurai.global_position = cp + Vector2(0, -14)
	samurai.velocity = Vector2.ZERO
	samurai.health.reset()
	samurai.modulate.a = 1.0
	samurai.sm.change_to(Samurai.S_IDLE, true)
	_respawn_pending = false
