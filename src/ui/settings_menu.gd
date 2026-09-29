class_name SettingsMenu
extends CanvasLayer
## Esc ile acilan ayar menusu: efekt yogunlugu, sarsinti, flas.
## Acikken oyun duraklar (tree.paused); menu ALWAYS modda calisir.

var _panel: PanelContainer
var _open := false


func _ready() -> void:
	layer = 90
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build()
	visible = false


func _build() -> void:
	_panel = PanelContainer.new()
	_panel.set_anchors_preset(Control.PRESET_CENTER)
	_panel.position = Vector2(140, 70)
	_panel.custom_minimum_size = Vector2(200, 110)
	add_child(_panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	_panel.add_child(vbox)

	var title := Label.new()
	title.text = "AYARLAR"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 10)
	vbox.add_child(title)

	vbox.add_child(_slider_row("Efekt", Settings.fx_intensity, Settings.set_fx_intensity))
	vbox.add_child(_slider_row("Sarsinti", Settings.shake_scale, Settings.set_shake_scale))
	vbox.add_child(_slider_row("Flas", Settings.flash_scale, Settings.set_flash_scale))

	var hint := Label.new()
	hint.text = "Esc: kapat"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", 7)
	hint.add_theme_color_override("font_color", Color(0.6, 0.6, 0.65))
	vbox.add_child(hint)


func _slider_row(label_text: String, initial: float, setter: Callable) -> HBoxContainer:
	var row := HBoxContainer.new()
	var label := Label.new()
	label.text = label_text
	label.custom_minimum_size = Vector2(48, 0)
	label.add_theme_font_size_override("font_size", 8)
	row.add_child(label)
	var slider := HSlider.new()
	slider.min_value = 0.0
	slider.max_value = 1.0
	slider.step = 0.05
	slider.value = initial
	slider.custom_minimum_size = Vector2(120, 0)
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.value_changed.connect(setter)
	row.add_child(slider)
	return row


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"pause"):
		toggle()


func toggle() -> void:
	_open = not _open
	visible = _open
	get_tree().paused = _open
