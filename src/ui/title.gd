extends Node2D
## Baslik ekrani: YENI OYUN / DEVAM ET (kayit varsa) / AYARLAR / CIKIS.
## Devam, kaydedilen bolume atlar (GameState.current_chapter).

const CHAPTER_SCENES := {
	&"prolog": "res://src/levels/prolog/Prolog.tscn",
	&"ch1": "res://src/levels/ch1/Ch1.tscn",
	&"ch2": "res://src/levels/ch2/Ch2.tscn",
	&"ch3": "res://src/levels/ch3/Ch3.tscn",
	&"ch4": "res://src/levels/ch4/Ch4.tscn",
	&"ch5": "res://src/levels/ch5/Ch5.tscn",
	&"ch6": "res://src/levels/ch6/Ch6.tscn",
	&"ch7": "res://src/levels/ch7/Ch7.tscn",
}

var _settings: SettingsMenu


func _ready() -> void:
	GameState.play_time = 0.0
	var bg := ColorRect.new()
	bg.color = Color(0.03, 0.02, 0.07)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	# Soluk ay + samuray silueti (sessiz tanitim)
	var moon := Sprite2D.new()
	AssetLoader.apply_to_sprite(moon, &"bg/moon", Vector2i(64, 64))
	moon.position = Vector2(140, 80)
	moon.modulate = Color(0.8, 0.8, 0.9, 0.7)
	add_child(moon)

	var frames: SpriteFrames = AssetLoader.frames(&"player/samurai/idle")
	if frames != null and frames.has_animation(&"default"):
		var sam := AnimatedSprite2D.new()
		sam.sprite_frames = frames
		sam.play(&"default")
		sam.position = Vector2(240, 158)
		add_child(sam)
	else:
		var ph := Sprite2D.new()
		AssetLoader.apply_to_sprite(ph, &"boot/placeholder", Vector2i(24, 40))
		ph.position = Vector2(240, 190)
		add_child(ph)

	var title := Label.new()
	title.text = "SAMSARA  GLITCH"
	title.add_theme_font_size_override("font_size", 22)
	title.add_theme_color_override("font_color", Color(0.85, 0.8, 0.95))
	title.position = Vector2(240 - title.get_theme_default_font().get_string_size(title.text, HORIZONTAL_ALIGNMENT_LEFT, -1, 22).x / 2.0, 30)
	add_child(title)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	vbox.position = Vector2(190, 200)
	add_child(vbox)
	if SaveSystem.has_save():
		vbox.add_child(_btn("DEVAM ET", _on_continue))
	vbox.add_child(_btn("YENI OYUN", _on_new_game))
	vbox.add_child(_btn("AYARLAR", _on_settings))
	if not OS.has_feature("web"):
		vbox.add_child(_btn("CIKIS", func() -> void: get_tree().quit()))

	_settings = SettingsMenu.new()
	add_child(_settings)
	AudioManager.play_music(&"music/prolog")


func _btn(text: String, cb: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(100, 14)
	b.add_theme_font_size_override("font_size", 9)
	b.pressed.connect(cb)
	return b


func _on_new_game() -> void:
	SaveSystem.wipe()
	GameState.reset()
	EventBus.scene_change_requested.emit(CHAPTER_SCENES[&"prolog"])


func _on_continue() -> void:
	if SaveSystem.load_game() != OK:
		_on_new_game()
		return
	var scene: String = CHAPTER_SCENES.get(GameState.current_chapter, CHAPTER_SCENES[&"prolog"])
	EventBus.scene_change_requested.emit(scene)


func _on_settings() -> void:
	if _settings.visible == false:
		_settings.toggle()
