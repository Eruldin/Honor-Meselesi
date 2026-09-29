extends Node2D
## Bolum 3 stub (gercek gotik seviye + Kont Vlad M6'da).

var samurai: Samurai


func _ready() -> void:
	GameState.current_chapter = &"ch3"
	var bg := ColorRect.new()
	bg.color = Color(0.08, 0.05, 0.14)  # gotik mor karanlik
	bg.size = Vector2(480, 270)
	add_child(bg)

	var ground := StaticBody2D.new()
	ground.collision_layer = 1
	var col := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(480, 24)
	col.shape = rect
	ground.add_child(col)
	ground.position = Vector2(240, 260)
	add_child(ground)

	samurai = Samurai.new()
	samurai.global_position = Vector2(80, 230)
	add_child(samurai)

	var cam := ScreenShake.new()
	cam.global_position = Vector2(240, 135)
	add_child(cam)
	cam.make_current()
	add_child(PostFX.new())
	add_child(SettingsMenu.new())

	var layer := CanvasLayer.new()
	add_child(layer)
	var banner := Label.new()
	banner.text = "BOLUM 3 — GOTIK SALON"
	banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	banner.set_anchors_preset(Control.PRESET_CENTER_TOP)
	banner.position.y = 30
	banner.add_theme_font_size_override("font_size", 14)
	banner.add_theme_color_override("font_color", Color(0.8, 0.6, 1.0))
	layer.add_child(banner)
