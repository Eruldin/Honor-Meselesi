extends Node2D
## M6 — Bolum 3: Gotik Salon + Kont Vlad.
## Hayaletler (kivilcimla aciga cikan), isinlanan vampirler (kanama DoT),
## duvar ziplayan kurtadamlar (parry'lenemez — kirmizi goz telegraph),
## dinlenme noktasi -> arena -> Vlad 2 faz (faz 2: karanlik + goz ipucu)
## -> Golge/Yarasa formu -> Bolum 4.

const CH4_PATH := "res://src/levels/ch4/Ch4.tscn"
const FLOOR_Y := 250.0
const LEVEL_W := 1500.0
const ARENA_X := 1180.0
const ARENA_L := 1190.0
const ARENA_R := 1470.0

@export var auto_advance := true

var samurai: Samurai
var camera: ScreenShake
var boss: CountVlad
var _walls: Array[StaticBody2D] = []
var _boss_bar: Control
var _boss_root: Control
var _player_fill: Control
var _hud_label: Label
var _boss_started := false
var _respawn_pending := false


func _ready() -> void:
	GameState.current_chapter = &"ch3"
	AudioManager.play_music(&"music/ch3")
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
	var bg := ColorRect.new()
	bg.color = Color(0.07, 0.04, 0.12)
	bg.size = Vector2(LEVEL_W, 270)
	add_child(bg)
	if AssetLoader.has_asset(&"bg/gothic"):
		var spr := Sprite2D.new()
		spr.texture = AssetLoader.texture(&"bg/gothic")
		spr.centered = false
		var ts := spr.texture.get_size()
		spr.scale = Vector2(LEVEL_W, 270) / ts
		spr.modulate = Color(0.8, 0.7, 0.9)
		add_child(spr)
	if AssetLoader.has_asset(&"bg/moon"):
		var moon := Sprite2D.new()
		moon.texture = AssetLoader.texture(&"bg/moon")
		moon.centered = false
		var ms := moon.texture.get_size()
		moon.scale = Vector2(480, 270) / ms
		moon.modulate = Color(0.9, 0.8, 1.0, 0.9)
		add_child(moon)

	# Sutunlar + gotik pencere siluetleri
	for i in 10:
		var pillar := ColorRect.new()
		pillar.color = Color(0.13, 0.09, 0.18)
		pillar.position = Vector2(70.0 + i * 150.0, 60)
		pillar.size = Vector2(16, 190)
		add_child(pillar)
		var arch := ColorRect.new()
		arch.color = Color(0.2, 0.12, 0.28)
		arch.position = pillar.position + Vector2(-8, -14)
		arch.size = Vector2(32, 14)
		add_child(arch)

	_add_ground(Vector2(LEVEL_W / 2, FLOOR_Y + 10), Vector2(LEVEL_W, 24))
	_add_ground(Vector2(-6, 135), Vector2(12, 270))
	_add_ground(Vector2(250, 180), Vector2(90, 8))
	_add_ground(Vector2(620, 175), Vector2(80, 8))
	_add_ground(Vector2(950, 185), Vector2(90, 8))
	# Kurtadam duvarlari
	_add_ground(Vector2(430, 140), Vector2(10, 120))
	_add_ground(Vector2(560, 140), Vector2(10, 120))

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
	sprite.texture = AssetLoader.placeholder_texture("terrain/ch3_ground", Vector2i(size))
	sprite.modulate = Color(0.25, 0.18, 0.35)
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

	var gh1 := Ghost.new()
	gh1.global_position = Vector2(340, FLOOR_Y - 14)
	add_child(gh1)
	var gh2 := Ghost.new()
	gh2.global_position = Vector2(520, FLOOR_Y - 14)
	add_child(gh2)

	var v1 := Vampire.new()
	v1.global_position = Vector2(700, FLOOR_Y - 12)
	add_child(v1)

	var w1 := Werewolf.new()
	w1.global_position = Vector2(430, 150)
	add_child(w1)
	var w2 := Werewolf.new()
	w2.global_position = Vector2(560, 160)
	add_child(w2)

	var rest := RestPoint.new()
	rest.checkpoint_id = &"ch3_shrine"
	rest.global_position = Vector2(1000, FLOOR_Y - 12)
	add_child(rest)

	var gh3 := Ghost.new()
	gh3.global_position = Vector2(1080, FLOOR_Y - 14)
	add_child(gh3)

	boss = CountVlad.new()
	boss.name = "KontVlad"
	boss.arena_root = self
	boss.global_position = Vector2(1430, FLOOR_Y - 14)
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
	var pb := HudBars.make(90, 7, Color(0.8, 0.3, 0.9))
	pb.root.position = Vector2(6, 16)
	layer.add_child(pb.root)
	_player_fill = pb.fill
	var boss_bar := HudBars.make(160, 6, Color(0.8, 0.3, 0.9))
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
	AudioManager.play_music(&"music/ch3_boss")
	boss.activate()


func _on_boss_defeated() -> void:
	GameState.unlock_form(&"golge")
	GameState.set_flag(&"ch3_boss_dead")
	if boss.darkness != null:
		boss.darkness.create_tween().tween_property(boss.darkness, "modulate:a", 0.0, 0.8)
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
	cutscene.finished.connect(_go_ch4, CONNECT_ONE_SHOT)


func _go_ch4() -> void:
	GameState.set_flag(&"ch3_done")
	GameState.current_chapter = &"ch4"
	if auto_advance:
		EventBus.scene_change_requested.emit(CH4_PATH)


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
