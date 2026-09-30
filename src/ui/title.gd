extends Node2D
## Baslik ekrani — Honor Meselesi. Alacakaranlik dag manzarasi, torii
## sutunlari ve duran samuray. YENI OYUN / DEVAM ET / AYARLAR / CIKIS.

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
var _petals: Array[Sprite2D] = []
var _new_game_armed := false
var _creature: Sprite2D
var _peek_timer := 5.0
var _peek_t := 0.0


func _ready() -> void:
	GameState.play_time = 0.0
	_build_scenery()
	_build_menu()
	_settings = SettingsMenu.new()
	add_child(_settings)
	AudioManager.play_music(&"music/title")


func _build_scenery() -> void:
	# Alacakaranlik dag katmanlari — sabit, kamera yok
	var specs := [
		{id = &"bg/dusk_sky", scale_to = 270.0, y = 0.0},
		{id = &"bg/dusk_clouds", scale_to = 120.0, y = 20.0, mod = Color(1, 0.9, 0.85, 0.8)},
		{id = &"bg/dusk_far", scale_to = 200.0, y = 40.0},
		{id = &"bg/dusk_mid", scale_to = 190.0, y = 80.0},
		{id = &"bg/dusk_trees", scale_to = 150.0, y = 140.0},
	]
	for s in specs:
		if not AssetLoader.has_asset(s.id):
			continue
		var tex := AssetLoader.texture(s.id)
		var sp := Sprite2D.new()
		sp.texture = tex
		sp.centered = false
		var k: float = s.scale_to / tex.get_height()
		sp.scale = Vector2(k, k)
		# Yatayda ekrani kaplayacak kadar dose
		var tiled_w := tex.get_width() * k
		var copies := int(ceilf(480.0 / maxf(tiled_w, 1.0))) + 1
		for i in copies:
			if i > 0:
				var extra := Sprite2D.new()
				extra.texture = tex
				extra.centered = false
				extra.scale = sp.scale
				extra.position = Vector2(tiled_w * i, s.y)
				if s.has("mod"):
					extra.modulate = s.mod
				add_child(extra)
		sp.position = Vector2(0, s.y)
		if s.has("mod"):
			sp.modulate = s.mod
		add_child(sp)

	# Zemin seridi
	var ground := ColorRect.new()
	ground.color = Color(0.10, 0.07, 0.10)
	ground.position = Vector2(0, 236)
	ground.size = Vector2(480, 34)
	add_child(ground)

	# Torii sutunlari cercevede
	for x in [30.0, 428.0]:
		var p := Sprite2D.new()
		p.texture = AssetLoader.texture(&"prop/deco_pillar", Vector2i(30, 70))
		p.position = Vector2(x, 176)
		p.modulate = Color(0.9, 0.55, 0.5)
		p.z_index = 5
		add_child(p)
	# Samuray — gercek idle animasyonu, orta sahne
	var frames: SpriteFrames = AssetLoader.frames(&"player/samurai/idle")
	if frames != null and frames.has_animation(&"default"):
		var sam := AnimatedSprite2D.new()
		sam.sprite_frames = frames
		sam.play(&"default")
		sam.scale = Vector2(0.85, 0.85)
		sam.position = Vector2(240, 192)
		sam.z_index = 4
		add_child(sam)

	# Ucusan yapraklar (atmosfer)
	for i in 7:
		var petal := Sprite2D.new()
		petal.texture = AssetLoader.texture(&"fx/petal", Vector2i(3, 2))
		petal.modulate = Color(0.9, 0.45, 0.4, 0.8)
		petal.position = Vector2(randf() * 480.0, randf() * 200.0)
		petal.z_index = 6
		petal.rotation = randf() * PI
		_petals.append(petal)
		add_child(petal)

	# Glitch Yaratik — arada belirip statikle gozden kaybolur (onsezme)
	_creature = Sprite2D.new()
	_creature.texture = AssetLoader.texture(&"enemy/glitch_creature", Vector2i(14, 12))
	_creature.modulate = Color(0.55, 0.9, 1.0, 0.95)
	_creature.z_index = 7
	_creature.visible = false
	add_child(_creature)


func _build_menu() -> void:
	# Gercek logo varsa kullan (ui/logo), yoksa metin basliga dus
	if AssetLoader.has_asset(&"ui/logo"):
		var logo := Sprite2D.new()
		logo.texture = AssetLoader.texture(&"ui/logo")
		logo.centered = true
		# 360px genislikte — torii+kasa+katana+isim butun olarak
		var lw := 210.0
		logo.scale = Vector2.ONE * (lw / logo.texture.get_width())
		logo.position = Vector2(240, 78)
		logo.z_index = 10
		add_child(logo)
	else:
		var title := Label.new()
		title.text = "HONOR  MESELESI"
		title.add_theme_font_size_override("font_size", 26)
		title.add_theme_color_override("font_color", Color(0.95, 0.82, 0.55))
		title.add_theme_color_override("font_shadow_color", Color(0.35, 0.05, 0.08))
		title.add_theme_constant_override("shadow_offset_x", 2)
		title.add_theme_constant_override("shadow_offset_y", 2)
		var tw := title.get_theme_default_font().get_string_size(
			title.text, HORIZONTAL_ALIGNMENT_LEFT, -1, 26).x
		title.position = Vector2(240 - tw / 2.0, 18)
		title.z_index = 10
		add_child(title)

		var sub := Label.new()
		sub.text = "~ onurunu geri al ~"
		sub.add_theme_font_size_override("font_size", 8)
		sub.add_theme_color_override("font_color", Color(0.8, 0.65, 0.6, 0.85))
		var sw := sub.get_theme_default_font().get_string_size(
			sub.text, HORIZONTAL_ALIGNMENT_LEFT, -1, 8).x
		sub.position = Vector2(240 - sw / 2.0, 48)
		sub.z_index = 10
		add_child(sub)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	vbox.position = Vector2(190, 196)
	vbox.z_index = 10
	add_child(vbox)
	if SaveSystem.has_save():
		vbox.add_child(_btn("DEVAM ET", _on_continue))
	var ng: Button
	ng = _btn("YENI OYUN", func() -> void:
		# Kayit varsa tek tikla silinmesin — ikinci tik onaylar
		if _new_game_armed or not SaveSystem.has_save():
			_on_new_game()
			return
		_new_game_armed = true
		ng.text = "EMIN MISIN?" if Settings.language == "tr" else "SURE?"
		ng.modulate = Color(1.0, 0.5, 0.5))
	vbox.add_child(ng)
	vbox.add_child(_btn("AYARLAR", _on_settings))
	if not OS.has_feature("web"):
		vbox.add_child(_btn("CIKIS", func() -> void: get_tree().quit()))


func _process(delta: float) -> void:
	# Yaratik pusuda: 5-9 saniyede bir kisaca goz kirpar
	if _peek_t > 0.0:
		_peek_t -= delta
		_creature.visible = int(Time.get_ticks_msec() / 45) % 3 != 0
		if _peek_t <= 0.0:
			_creature.visible = false
	else:
		_peek_timer -= delta
		if _peek_timer <= 0.0:
			_peek_timer = randf_range(5.0, 9.0)
			_peek_t = 1.0
			_creature.position = Vector2(
				randf_range(70.0, 410.0), randf_range(140.0, 215.0))
			_creature.visible = true
			AudioManager.play_sfx(&"sfx/glitch", null, -16.0, randf_range(1.1, 1.3))
	for p in _petals:
		p.position.x += 14.0 * delta
		p.position.y += (8.0 + sin(p.position.x * 0.05) * 5.0) * delta
		p.rotation += delta * 0.8
		if p.position.y > 235.0 or p.position.x > 490.0:
			p.position = Vector2(randf() * 300.0 - 20.0, -6.0)


func _btn(text: String, cb: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(100, 14)
	b.add_theme_font_size_override("font_size", 9)
	b.pressed.connect(func() -> void:
		AudioManager.play_sfx(&"sfx/ui", null, -6.0)
		cb.call())
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
