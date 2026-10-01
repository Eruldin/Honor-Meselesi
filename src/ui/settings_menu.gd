class_name SettingsMenu
extends CanvasLayer
## Tam ekran ayarlar menusu — sekmeli: GRAFIK / SES / DIL / KONTROLLER.
## Esc ile acilir/kapanir; acikken oyun duraklar (tree.paused).

const TABS: Array[StringName] = [&"grafik", &"ses", &"dil", &"kontrol"]
const REBINDABLE: Array[StringName] = [
	&"move_left", &"move_right", &"move_up", &"move_down",
	&"jump", &"attack", &"parry", &"dash", &"focus", &"form_prev", &"form_next",
]
const LABELS := {
	"tr": {"grafik": "GRAFIK", "ses": "SES", "dil": "DIL", "kontrol": "KONTROLLER",
		"title": "AYARLAR", "close": "Esc: kapat"},
	"en": {"grafik": "GRAPHICS", "ses": "AUDIO", "dil": "LANGUAGE", "kontrol": "CONTROLS",
		"title": "SETTINGS", "close": "Esc: close"},
}
const ACTION_NAMES := {
	"tr": {&"move_left": "Sola", &"move_right": "Saga", &"move_up": "Yukari",
		&"move_down": "Asagi", &"jump": "Zipla", &"attack": "Saldir",
		&"parry": "Parry", &"dash": "Dash", &"focus": "Odak/Iyilesme",
		&"form_prev": "Onceki Form", &"form_next": "Sonraki Form"},
	"en": {&"move_left": "Left", &"move_right": "Right", &"move_up": "Up",
		&"move_down": "Down", &"jump": "Jump", &"attack": "Attack",
		&"parry": "Parry", &"dash": "Dash", &"focus": "Focus/Heal",
		&"form_prev": "Prev Form", &"form_next": "Next Form"},
}

var _panel: PanelContainer
var _content: VBoxContainer
var _tab_buttons := {}
var _open := false
var _tab: StringName = &"grafik"
var _rebinding: StringName = &""


func _ready() -> void:
	layer = 90
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build()
	visible = false
	Settings.changed.connect(func() -> void:
		if _open:
			_rebuild_tab())


func tr_ui(key: String) -> String:
	return LABELS.get(Settings.language, LABELS["tr"]).get(key, key)


func _build() -> void:
	# Karanlik zemin — tam ekran
	var dim := ColorRect.new()
	dim.color = Color(0.02, 0.02, 0.04, 0.92)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)

	# Viewport oranli, her zaman ortali panel
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	_panel = PanelContainer.new()
	var vsz := get_viewport().get_visible_rect().size
	_panel.custom_minimum_size = Vector2(
		maxf(vsz.x * 0.92, 320.0), maxf(vsz.y * 0.9, 220.0))
	center.add_child(_panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	_panel.add_child(vbox)

	var title := Label.new()
	title.text = tr_ui("title")
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 16)
	vbox.add_child(title)

	# Sekme dugmeleri
	var tabs := HBoxContainer.new()
	tabs.alignment = BoxContainer.ALIGNMENT_CENTER
	tabs.add_theme_constant_override("separation", 4)
	vbox.add_child(tabs)
	for t in TABS:
		var b := Button.new()
		b.text = tr_ui(t)
		b.add_theme_font_size_override("font_size", 11)
		b.pressed.connect(func() -> void:
			AudioManager.play_sfx(&"sfx/ui", null, -6.0)
			_tab = t
			_rebuild_tab())
		tabs.add_child(b)
		_tab_buttons[t] = b

	_content = VBoxContainer.new()
	_content.add_theme_constant_override("separation", 8)
	_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(_content)

	var quit := Button.new()
	quit.text = "BASLIGA DON" if Settings.language == "tr" else "QUIT TO TITLE"
	quit.add_theme_font_size_override("font_size", 9)
	quit.pressed.connect(func() -> void:
		AudioManager.play_sfx(&"sfx/ui", null, -6.0)
		get_tree().paused = false
		SaveSystem.save_game()
		EventBus.scene_change_requested.emit("res://src/ui/Title.tscn"))
	vbox.add_child(quit)

	var hint := Label.new()
	hint.text = tr_ui("close")
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", 7)
	hint.add_theme_color_override("font_color", Color(0.6, 0.6, 0.65))
	vbox.add_child(hint)


func _rebuild_tab() -> void:
	for c in _content.get_children():
		c.queue_free()
	for t in TABS:
		_tab_buttons[t].modulate = Color(1.0, 0.85, 0.5) if t == _tab else Color.WHITE
	match _tab:
		&"grafik":
			_tab_graphics()
		&"ses":
			_tab_audio()
		&"dil":
			_tab_language()
		&"kontrol":
			_tab_controls()


func _tab_graphics() -> void:
	var fs := CheckButton.new()
	fs.text = "Tam Ekran" if Settings.language == "tr" else "Fullscreen"
	fs.button_pressed = Settings.fullscreen
	fs.toggled.connect(Settings.set_fullscreen)
	_content.add_child(fs)

	var row := HBoxContainer.new()
	var lbl := Label.new()
	lbl.text = ("Cozunurluk" if Settings.language == "tr" else "Resolution") + ": "
	lbl.add_theme_font_size_override("font_size", 9)
	row.add_child(lbl)
	var opt := OptionButton.new()
	opt.add_theme_font_size_override("font_size", 9)
	var sizes := [2, 3, 4, 6]
	for s in sizes:
		opt.add_item("%dx%d" % [480 * s, 270 * s], s)
		if s == Settings.window_scale:
			opt.select(opt.item_count - 1)
	opt.item_selected.connect(func(idx: int) -> void:
		Settings.set_window_scale(sizes[idx]))
	row.add_child(opt)
	_content.add_child(row)

	var is_tr := Settings.language == "tr"
	_content.add_child(_slider_row(
		"Sinematik Glitch" if is_tr else "Cinematic Glitch",
		Settings.fx_intensity, Settings.set_fx_intensity))
	_content.add_child(_slider_row(
		"Sarsinti" if is_tr else "Screen Shake",
		Settings.shake_scale, Settings.set_shake_scale))
	_content.add_child(_slider_row(
		"Flas" if is_tr else "Flash",
		Settings.flash_scale, Settings.set_flash_scale))


func _tab_audio() -> void:
	var is_tr := Settings.language == "tr"
	_content.add_child(_slider_row(
		"Ana Ses" if is_tr else "Master",
		Settings.master_volume, Settings.set_master_volume))
	_content.add_child(_slider_row(
		"Muzik" if is_tr else "Music",
		Settings.music_volume, Settings.set_music_volume))
	_content.add_child(_slider_row(
		"Efektler" if is_tr else "SFX",
		Settings.sfx_volume, Settings.set_sfx_volume))


func _tab_language() -> void:
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 10)
	for spec in [["tr", "Turkce"], ["en", "English"]]:
		var b := Button.new()
		b.text = spec[1]
		b.add_theme_font_size_override("font_size", 10)
		b.modulate = Color(1.0, 0.85, 0.5) if Settings.language == spec[0] else Color.WHITE
		b.pressed.connect(func() -> void:
			AudioManager.play_sfx(&"sfx/ui", null, -6.0)
			Settings.set_language(spec[0])
			_rebuild_all())
		row.add_child(b)
	_content.add_child(row)


func _tab_controls() -> void:
	var scroll := ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_content.add_child(scroll)
	var list := VBoxContainer.new()
	list.add_theme_constant_override("separation", 2)
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(list)
	for action in REBINDABLE:
		var row := HBoxContainer.new()
		var lbl := Label.new()
		lbl.text = ACTION_NAMES.get(Settings.language,
			ACTION_NAMES["tr"]).get(action, action)
		lbl.custom_minimum_size = Vector2(110, 0)
		lbl.add_theme_font_size_override("font_size", 10)
		row.add_child(lbl)
		var b := Button.new()
		b.text = _binding_text(action) if _rebinding != action else "...?"
		b.add_theme_font_size_override("font_size", 10)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.pressed.connect(func() -> void:
			AudioManager.play_sfx(&"sfx/ui", null, -6.0)
			_rebinding = action
			_rebuild_tab())
		row.add_child(b)
		list.add_child(row)


func _binding_text(action: StringName) -> String:
	var parts: Array[String] = []
	for ev in InputMap.action_get_events(action):
		if ev is InputEventKey:
			parts.append(OS.get_keycode_string(ev.physical_keycode))
		elif ev is InputEventMouseButton:
			parts.append("Mouse%d" % ev.button_index)
		elif ev is InputEventJoypadButton:
			parts.append("Pad%d" % ev.button_index)
	return ", ".join(parts) if parts.size() > 0 else "-"


func _slider_row(label_text: String, initial: float, setter: Callable) -> HBoxContainer:
	var row := HBoxContainer.new()
	var label := Label.new()
	label.text = label_text
	label.custom_minimum_size = Vector2(110, 0)
	label.add_theme_font_size_override("font_size", 10)
	row.add_child(label)
	var slider := HSlider.new()
	slider.min_value = 0.0
	slider.max_value = 1.0
	slider.step = 0.05
	slider.value = initial
	slider.custom_minimum_size = Vector2(200, 0)
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.value_changed.connect(setter)
	row.add_child(slider)
	return row


func _rebuild_all() -> void:
	for c in get_children():
		c.queue_free()
	_tab_buttons.clear()
	_build()
	_rebuild_tab()


func _unhandled_input(event: InputEvent) -> void:
	if _rebinding != &"" and _open:
		if event is InputEventKey and event.pressed and not event.echo:
			if event.keycode == KEY_ESCAPE:
				_rebinding = &""  # Esc: atamayi iptal et (menuyu de kapatmaz)
				_rebuild_tab()
				get_viewport().set_input_as_handled()
				return
			InputMap.action_erase_events(_rebinding)
			InputMap.action_add_event(_rebinding, event)
			Settings.set_binding(_rebinding)
			_rebinding = &""
			_rebuild_tab()
			get_viewport().set_input_as_handled()
		elif event is InputEventMouseButton and event.pressed:
			InputMap.action_add_event(_rebinding, event)
			Settings.set_binding(_rebinding)
			_rebinding = &""
			_rebuild_tab()
			get_viewport().set_input_as_handled()
		elif event is InputEventJoypadButton and event.pressed:
			InputMap.action_add_event(_rebinding, event)
			Settings.set_binding(_rebinding)
			_rebinding = &""
			_rebuild_tab()
			get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed(&"pause"):
		toggle()


func toggle() -> void:
	_open = not _open
	visible = _open
	get_tree().paused = _open
	if _open:
		_rebuild_tab()
