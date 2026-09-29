extends Node2D
## M4 — Bolum 1: Ofkeli Koy + Lord Cluck (dikey dilim).
## Koy sokagi: koyluler -> kalkanli muhafiz -> dinlenme noktasi ->
## agir sovalye (gecici Sovalye formu dusurur) -> arena -> Lord Cluck ->
## Glitch Yaratik gecis sinematigi -> Bolum 2.

const CH2_PATH := "res://src/levels/ch2/Ch2.tscn"
const FLOOR_Y := 250.0
const LEVEL_W := 1500.0
const ARENA_X := 1180.0   ## boss tetik cizgisi
const ARENA_L := 1190.0
const ARENA_R := 1480.0

## Testlerde gercek sahne gecisini kapatmak icin.
@export var auto_advance := true

var samurai: Samurai
var camera: ScreenShake
var boss: LordCluck
var _walls: Array[StaticBody2D] = []
var _boss_bar: ColorRect
var _hud_label: Label
var _boss_started := false
var _respawn_pending := false


func _ready() -> void:
	GameState.current_chapter = &"ch1"
	_build_terrain()
	_build_entities()
	_build_fx()
	_build_hud()
	EventBus.actor_died.connect(_on_actor_died)
	EventBus.checkpoint_reached.connect(func(_id: StringName) -> void: pass)


func _process(_delta: float) -> void:
	# Kamera oyuncuyu takip eder
	if samurai != null and is_instance_valid(samurai):
		camera.global_position.x = clampf(samurai.global_position.x, 240, LEVEL_W - 240)
	if boss != null and is_instance_valid(boss) and boss.active:
		_boss_bar.visible = true
		var frac := float(boss.health.current) / maxf(boss.health.max_health, 1)
		_boss_bar.size.x = 160.0 * frac
	if samurai != null and _hud_label != null:
		_hud_label.text = "can %d/%d  form %s" % [
			samurai.health.current, samurai.health.max_health,
			samurai.form.id if samurai.form != null else "?"]


# --- Kurulum ---

func _build_terrain() -> void:
	var sky := ColorRect.new()
	sky.color = Color(0.25, 0.09, 0.12)
	sky.size = Vector2(LEVEL_W, 270)
	add_child(sky)

	_add_ground(Vector2(LEVEL_W / 2, FLOOR_Y + 10), Vector2(LEVEL_W, 24))
	_add_ground(Vector2(140, 195), Vector2(70, 8))
	_add_ground(Vector2(430, 190), Vector2(70, 8))
	_add_ground(Vector2(-6, 135), Vector2(12, 270))

	# Koy evleri + catilar (siluet)
	for i in 8:
		var hx := 60.0 + i * 180.0
		if hx > ARENA_L:
			break
		var house := ColorRect.new()
		house.color = Color(0.14, 0.08, 0.1).lightened((i % 3) * 0.04)
		house.position = Vector2(hx, 175 - (i % 2) * 16)
		house.size = Vector2(52, 75)
		add_child(house)
		var roof := Polygon2D.new()
		roof.polygon = PackedVector2Array([
			Vector2(-6, 0), Vector2(26, -22), Vector2(58, 0)])
		roof.color = Color(0.1, 0.05, 0.07)
		roof.position = house.position
		add_child(roof)

	# Arena duvarlari — boss tetiklenince etkinlesir
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
	var sprite := Sprite2D.new()
	sprite.texture = AssetLoader.placeholder_texture("terrain/arena_wall", Vector2i(16, 270))
	sprite.modulate = Color(0.3, 0.15, 0.2)
	body.add_child(sprite)
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
	sprite.texture = AssetLoader.placeholder_texture("terrain/ch1_ground", Vector2i(size))
	sprite.modulate = Color(0.4, 0.25, 0.3)
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

	var v1 := Villager.new()
	v1.global_position = Vector2(360, FLOOR_Y - 12)
	add_child(v1)
	var v2 := Villager.new()
	v2.global_position = Vector2(520, FLOOR_Y - 12)
	add_child(v2)

	var g := Guard.new()
	g.global_position = Vector2(700, FLOOR_Y - 12)
	add_child(g)

	var rest := RestPoint.new()
	rest.checkpoint_id = &"ch1_shrine"
	rest.global_position = Vector2(830, FLOOR_Y - 12)
	add_child(rest)

	var knight := HeavyKnight.new()
	knight.grants_form = &"sovalye"
	knight.global_position = Vector2(1010, FLOOR_Y - 14)
	add_child(knight)

	boss = LordCluck.new()
	boss.name = "LordCluck"
	boss.arena_root = self
	boss.global_position = Vector2(1420, FLOOR_Y - 16)
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
	_hud_label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
	layer.add_child(_hud_label)

	# Boss can cubugu — metinsiz kural, sadece bar
	var bar_bg := ColorRect.new()
	bar_bg.color = Color(0.1, 0.05, 0.08)
	bar_bg.position = Vector2(160, 250)
	bar_bg.size = Vector2(162, 6)
	bar_bg.visible = false
	layer.add_child(bar_bg)
	_boss_bar = ColorRect.new()
	_boss_bar.color = Color(0.9, 0.3, 0.35)
	_boss_bar.position = Vector2(161, 251)
	_boss_bar.size = Vector2(160, 4)
	_boss_bar.visible = false
	layer.add_child(_boss_bar)
	boss.health.damaged.connect(
		func(_a: int, _r: int) -> void: bar_bg.visible = true)


# --- Boss akisi ---

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
	FX.shake(2.0, 0.3)
	boss.activate()


func _on_boss_defeated() -> void:
	GameState.unlock_form(&"tavuk")
	GameState.set_flag(&"ch1_boss_dead")
	# Glitch Yaratik gecis sinematigi (metinsiz)
	var creature := Node2D.new()
	creature.global_position = boss.global_position + Vector2(0, -30)
	add_child(creature)
	var cs := Sprite2D.new()
	cs.texture = AssetLoader.placeholder_texture("enemy/glitch_creature", Vector2i(16, 14))
	cs.modulate = Color(0.05, 0.05, 0.1)
	creature.add_child(cs)
	for dx in [-3.0, 3.0]:
		var eye := ColorRect.new()
		eye.size = Vector2(2, 3)
		eye.position = Vector2(dx - 1, -4)
		eye.color = Color(0.4, 1.0, 0.9)
		creature.add_child(eye)
	var portal := Node2D.new()
	portal.global_position = Vector2(ARENA_R - 30, FLOOR_Y - 34)
	add_child(portal)
	var ring := ColorRect.new()
	ring.size = Vector2(20, 34)
	ring.position = -ring.size / 2.0
	ring.color = Color(0.4, 0.8, 1.0, 0.6)
	portal.add_child(ring)

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
	await get_tree().create_timer(1.4, true).timeout
	var cp: Variant = GameState.get_flag(&"respawn_pos", Vector2(60, FLOOR_Y - 20))
	samurai.global_position = cp + Vector2(0, -14)
	samurai.velocity = Vector2.ZERO
	samurai.health.reset()
	samurai.modulate.a = 1.0
	samurai.sm.change_to(Samurai.S_IDLE, true)
	_respawn_pending = false
