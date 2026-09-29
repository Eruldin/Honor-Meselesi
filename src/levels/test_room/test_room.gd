extends Node2D
## M1 test odasi: kukla dusman, pogo dikenleri, parry mermisi atan kule.
## Tum geometri kodla kurulur — placeholder asamasinda editor sahnesi
## yerine deterministik kurulum tercih edildi.

var samurai: Samurai
var camera: ScreenShake
var hud_label: Label
var _respawn_pending := false


func _ready() -> void:
	_build_terrain()
	_build_entities()
	_build_fx()
	_build_hud()
	EventBus.actor_died.connect(_on_actor_died)


func _build_terrain() -> void:
	_add_ground(Vector2(240, 252), Vector2(480, 20))     # ana zemin
	_add_ground(Vector2(392, 184), Vector2(96, 10))     # platform
	_add_ground(Vector2(60, 110), Vector2(70, 10))      # ust platform
	_add_ground(Vector2(-6, 135), Vector2(12, 270))     # sol duvar
	_add_ground(Vector2(486, 135), Vector2(12, 270))    # sag duvar


func _add_ground(center: Vector2, size: Vector2) -> void:
	var body := StaticBody2D.new()
	body.collision_layer = 1
	body.collision_mask = 0
	var col := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = size
	col.shape = rect
	body.add_child(col)
	var sprite := Sprite2D.new()
	sprite.texture = AssetLoader.placeholder_texture("terrain/ground", Vector2i(size))
	sprite.modulate = Color(0.35, 0.3, 0.45)
	body.add_child(sprite)
	body.global_position = center
	add_child(body)


func _build_entities() -> void:
	samurai = Samurai.new()
	samurai.global_position = Vector2(80, 230)
	add_child(samurai)

	var spike := Spike.new()
	spike.global_position = Vector2(196, 238)
	add_child(spike)

	var dummy := DummyEnemy.new()
	dummy.name = "Kukla"
	dummy.global_position = Vector2(290, 234)
	add_child(dummy)

	var turret := Turret.new()
	turret.name = "Kule"
	turret.global_position = Vector2(448, 232)
	turret.fire_direction = -1
	add_child(turret)


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


func _build_hud() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	hud_label = Label.new()
	hud_label.position = Vector2(6, 4)
	hud_label.add_theme_font_size_override("font_size", 8)
	hud_label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
	layer.add_child(hud_label)

	var hint := Label.new()
	hint.text = "A/D:hareket Space:zipla J:saldiri(alt+pogo) K:parry L:dash"
	hint.position = Vector2(6, 256)
	hint.add_theme_font_size_override("font_size", 7)
	hint.add_theme_color_override("font_color", Color(0.6, 0.6, 0.65))
	layer.add_child(hint)


func _process(_delta: float) -> void:
	if samurai != null and hud_label != null:
		hud_label.text = "durum: %s  can: %d/%d  kombo: %d" % [
			samurai.sm.current_name,
			samurai.health.current,
			samurai.health.max_health,
			samurai.combo_index,
		]


func _on_actor_died(actor: Node) -> void:
	if actor != samurai or _respawn_pending:
		return
	_respawn_pending = true
	await get_tree().create_timer(1.2, true).timeout
	samurai.global_position = Vector2(80, 230)
	samurai.velocity = Vector2.ZERO
	samurai.health.reset()
	samurai.sm.change_to(Samurai.S_IDLE, true)
	_respawn_pending = false
