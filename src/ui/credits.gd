class_name Credits
extends CanvasLayer
## Jenerik: CREDITS.md tablosundan paket+yazar satirlari, ekranin
## altindan yukari akan yazi. Logo ustte sabit kalir. Herhangi bir
## aksiyon tusunda erken biter (finished yayar).

signal finished

var _scroll: VBoxContainer
var _done := false


func _init() -> void:
	layer = 130
	var bg := ColorRect.new()
	bg.color = Color.BLACK
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	if AssetLoader.has_asset(&"ui/logo"):
		var logo := Sprite2D.new()
		logo.texture = AssetLoader.texture(&"ui/logo")
		logo.centered = true
		logo.scale = Vector2.ONE * (150.0 / logo.texture.get_width())
		logo.position = Vector2(240, 40)
		add_child(logo)
	_scroll = VBoxContainer.new()
	_scroll.add_theme_constant_override("separation", 3)
	for line in _credit_lines():
		var l := Label.new()
		l.text = line
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		l.add_theme_font_size_override("font_size", 8)
		l.add_theme_color_override("font_color", Color(0.8, 0.78, 0.85, 0.9))
		_scroll.add_child(l)
	add_child(_scroll)
	_scroll.position = Vector2(40, 285)  # ekran altindan baslar
	_scroll.size.x = 400


func _ready() -> void:
	# Liste boyu ilk karede olculur (VBox layout deferred).
	await get_tree().process_frame
	var dist := _scroll.size.y + 300.0
	var tw := create_tween()
	tw.tween_property(_scroll, "position:y",
		-_scroll.size.y - 20.0, maxf(dist / 34.0, 10.0))
	tw.tween_callback(_finish)


func _unhandled_input(event: InputEvent) -> void:
	if _done:
		return
	if event.is_action_pressed(&"ui_accept") \
			or event.is_action_pressed(&"ui_cancel") \
			or event.is_action_pressed(&"attack") \
			or event.is_action_pressed(&"jump"):
		_finish()


func _finish() -> void:
	if _done:
		return
	_done = true
	finished.emit()


## CREDITS.md'den "| Paket | Yazar | Lisans |" satirlarini okur —
## baslik/ayirac satirlari atlanir, "paket — yazar" olarak gosterilir.
func _credit_lines() -> Array[String]:
	var lines: Array[String] = []
	var f := FileAccess.open("res://CREDITS.md", FileAccess.READ)
	if f == null:
		return lines
	while not f.eof_reached():
		var ln := f.get_line().strip_edges()
		if not ln.begins_with("|") or "---" in ln:
			continue
		var cols := ln.split("|", false)
		if cols.size() < 3:
			continue
		var paket := cols[0].strip_edges()
		var yazar := cols[1].strip_edges()
		if paket.is_empty() or paket == "Paket" or paket == "Arac":
			continue
		lines.append("%s  —  %s" % [paket, yazar])
	return lines
