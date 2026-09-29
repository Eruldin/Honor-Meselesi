extends Node2D
## M3 icin Bolum 1 giris sahnesi (stub) — gercek seviye + Lord Cluck M4'te.
## Prolog'dan buraya dusulur; samuray oynanabilir, dinlenme noktasi ve
## koy siluetleri vardir.

var samurai: Samurai
var camera: ScreenShake
var hud_label: Label


func _ready() -> void:
	GameState.current_chapter = &"ch1"
	_build_terrain()
	_build_entities()
	_build_fx()
	_build_banner()


func _build_terrain() -> void:
	var sky := ColorRect.new()
	sky.color = Color(0.25, 0.09, 0.12)  # ofkeli koy — kizil alacakaranlik
	sky.size = Vector2(480, 270)
	add_child(sky)

	_add_ground(Vector2(240, 252), Vector2(480, 24))
	_add_ground(Vector2(-6, 135), Vector2(12, 270))
	_add_ground(Vector2(486, 135), Vector2(12, 270))
	_add_ground(Vector2(150, 200), Vector2(60, 8))

	# Koy siluetleri
	for i in 4:
		var house := ColorRect.new()
		house.color = Color(0.14, 0.08, 0.1).lightened(i * 0.03)
		house.position = Vector2(60 + i * 100, 190 - (i % 2) * 14)
		house.size = Vector2(46, 50)
		add_child(house)
		var roof := Polygon2D.new()
		roof.polygon = PackedVector2Array([
			Vector2(-4, 0), Vector2(23, -18), Vector2(50, 0)])
		roof.color = Color(0.1, 0.05, 0.07)
		roof.position = house.position
		add_child(roof)

	# Dinlenme noktasi (M4'te tam checkpoint olacak)
	var shrine := Sprite2D.new()
	shrine.texture = AssetLoader.placeholder_texture("prop/shrine", Vector2i(10, 16))
	shrine.modulate = Color(0.5, 0.8, 1.0)
	shrine.global_position = Vector2(120, 232)
	add_child(shrine)


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
	samurai.global_position = Vector2(60, 230)
	add_child(samurai)


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


func _build_banner() -> void:
	# UI katmani metin kullanabilir (dilsiz kurali diyalog icin).
	var layer := CanvasLayer.new()
	add_child(layer)
	hud_label = Label.new()
	hud_label.text = "BOLUM 1 — OFKELI KOY"
	hud_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hud_label.set_anchors_preset(Control.PRESET_CENTER_TOP)
	hud_label.position.y = 30
	hud_label.add_theme_font_size_override("font_size", 14)
	hud_label.add_theme_color_override("font_color", Color(0.95, 0.8, 0.7))
	layer.add_child(hud_label)
	var tw := hud_label.create_tween()
	tw.tween_interval(1.6)
	tw.tween_property(hud_label, "modulate:a", 0.0, 0.8)
