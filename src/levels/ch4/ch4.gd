extends Node2D
## M7 — Bolum 4: Retro Platform + Kizil Tulumlu Tiran.
## Bloklar/borular, kesilince bolunen mantarlar, kabuk seken kaplumbaga,
## borulardan ates cicegi, gozleri oynayan bozuk bulutlar.
## Arena -> Tiran (yer kaldirma, yercekimi cevirme, piksel yagmuru)
## -> "GAME OVER" dususu -> Piksel Sicramasi -> Bolum 5.

const CH5_PATH := "res://src/levels/ch5/Ch5.tscn"
const FLOOR_Y := 250.0
const LEVEL_W := 1500.0
const ARENA_X := 1180.0
const ARENA_L := 1190.0
const ARENA_R := 1470.0

@export var auto_advance := true

var samurai: Samurai
var camera: ScreenShake
var boss: RedTyrant
var _walls: Array[StaticBody2D] = []
var _boss_bar: Control
var _boss_root: Control
var _player_fill: Control
var _hud_label: Label
var _boss_started := false
var _respawn_pending := false
var _gameover: Label


func _ready() -> void:
	GameState.current_chapter = &"ch4"
	AudioManager.play_music(&"music/ch4")
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
	bg.color = Color(0.45, 0.62, 0.9)  # nostaljik acik gokyuzu
	bg.size = Vector2(LEVEL_W, 270)
	add_child(bg)

	# Bozuk dekor: gozlu bulutlar (bir iki tanesi ara ara devrilir)
	for i in 7:
		var c := MadCloud.new()
		c.global_position = Vector2(120.0 + i * 190.0, 40.0 + (i % 3) * 22.0)
		add_child(c)
	# Uzak tepe siluetleri
	for i in 5:
		var hill := ColorRect.new()
		hill.color = Color(0.4, 0.7, 0.4, 0.5)
		hill.position = Vector2(200.0 + i * 300.0, FLOOR_Y - 26)
		hill.size = Vector2(120, 26)
		add_child(hill)

	_add_ground(Vector2(LEVEL_W / 2, FLOOR_Y + 10), Vector2(LEVEL_W, 24))
	_add_ground(Vector2(-6, 135), Vector2(12, 270))
	# Retro platform susleri
	_add_ground(Vector2(300, 185), Vector2(60, 8))
	_add_ground(Vector2(700, 170), Vector2(60, 8))
	_add_ground(Vector2(960, 190), Vector2(70, 8))

	# Kirilabilir blok sirasi (Piksel Sicramasi sonrasi da islevsel)
	for i in 4:
		var b := BreakableBlock.new()
		b.global_position = Vector2(430.0 + i * 18.0, 210)
		add_child(b)

	# Borular + ates cicekleri
	for px in [560.0, 830.0]:
		var pipe := StaticBody2D.new()
		pipe.collision_layer = 1
		var pc := CollisionShape2D.new()
		var pr := RectangleShape2D.new()
		pr.size = Vector2(20, 26)
		pc.shape = pr
		pipe.add_child(pc)
		var ps := Sprite2D.new()
		ps.texture = AssetLoader.placeholder_texture("terrain/pipe", Vector2i(20, 26))
		ps.modulate = Color(0.2, 0.6, 0.25)
		pipe.add_child(ps)
		pipe.global_position = Vector2(px, FLOOR_Y - 13)
		add_child(pipe)
		var fl := FireFlower.new()
		fl.global_position = Vector2(px, FLOOR_Y - 26)
		add_child(fl)

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
	sprite.texture = AssetLoader.placeholder_texture("terrain/ch4_ground", Vector2i(size))
	sprite.modulate = Color(0.35, 0.6, 0.3)
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

	var m1 := SplitMushroom.new()
	m1.global_position = Vector2(300, FLOOR_Y - 12)
	add_child(m1)
	var t1 := Turtle.new()
	t1.global_position = Vector2(520, FLOOR_Y - 10)
	add_child(t1)
	var m2 := SplitMushroom.new()
	m2.global_position = Vector2(760, FLOOR_Y - 12)
	add_child(m2)
	var t2 := Turtle.new()
	t2.global_position = Vector2(920, FLOOR_Y - 10)
	add_child(t2)

	var rest := RestPoint.new()
	rest.checkpoint_id = &"ch4_plaza"
	rest.global_position = Vector2(1060, FLOOR_Y - 12)
	add_child(rest)

	boss = RedTyrant.new()
	boss.name = "KizilTulumluTiran"
	boss.arena_root = self
	boss.arena_left = ARENA_L
	boss.arena_right = ARENA_R
	boss.global_position = Vector2(1420, FLOOR_Y - 14)
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
	# Oyuncu can cubugu (Kasaya bar dokulari)
	var pb := HudBars.make(90, 7, Color(0.8, 0.25, 0.3))
	pb.root.position = Vector2(6, 16)
	layer.add_child(pb.root)
	_player_fill = pb.fill
	# Boss can cubugu
	var boss_bar := HudBars.make(160, 6, Color(0.95, 0.3, 0.2))
	boss_bar.root.position = Vector2(160, 250)
	layer.add_child(boss_bar.root)
	_boss_root = boss_bar.root
	_boss_root.visible = false
	_boss_bar = boss_bar.fill

	# "GAME OVER" — Tiran duserken gorunen retro yazi (siyah bantta).
	_gameover = Label.new()
	_gameover.text = "GAME OVER"
	_gameover.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_gameover.set_anchors_preset(Control.PRESET_CENTER)
	_gameover.add_theme_font_size_override("font_size", 24)
	_gameover.add_theme_color_override("font_color", Color(1, 0.2, 0.2))
	_gameover.visible = false
	layer.add_child(_gameover)


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
	AudioManager.play_music(&"music/ch4_boss")
	boss.activate()


func _on_boss_defeated() -> void:
	GameState.set_flag(&"ch4_boss_dead")
	AudioManager.play_sfx(&"sfx/gameover")
	# Retro olum: "GAME OVER" bandi + Tiran asagi duser
	_gameover.visible = true
	if is_instance_valid(boss):
		var tw := boss.create_tween()
		tw.tween_property(boss, "position:y", boss.position.y + 320.0, 1.2)
		tw.parallel().tween_property(boss, "rotation", PI * 2.0, 1.2)

	await get_tree().create_timer(1.6, true).timeout
	_gameover.visible = false

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
		{op = "picto", node = "samurai", icon = &"jump", t = 1.0, wait = true},
		{op = "walk_to", node = "samurai", x = portal.global_position.x - 8, speed = 130.0},
		{op = "call", fn = func() -> void:
			samurai.create_tween().tween_property(samurai, "modulate:a", 0.0, 0.25)},
		{op = "wait", t = 0.3},
	], {"samurai": samurai, "portal": portal},
	func() -> void:
		samurai.global_position = portal.global_position)
	cutscene.finished.connect(_go_ch5, CONNECT_ONE_SHOT)


func _go_ch5() -> void:
	GameState.set_flag(&"ch4_done")
	GameState.current_chapter = &"ch5"
	if auto_advance:
		EventBus.scene_change_requested.emit(CH5_PATH)


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
