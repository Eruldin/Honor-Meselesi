extends Node2D
## M10 — Bolum 7: Bosluk/Final. Perspektif kaymasi:
## Oyuncu aslinda Glitch Yaratik — samuray (kasa geri almis) final boss
## olarak onunla savasir. Yenilgi -> Ouroboros: yaratik kasayi geri
## birakip CRT'ye siner -> sahne Prolog'a doner (dongu kapanir).

const PROLOG_PATH := "res://src/levels/prolog/Prolog.tscn"
const FLOOR_Y := 250.0

@export var auto_advance := true

var samurai: Samurai            ## giris cutscene'i icin (sonra boss'a cevrilir)
var creature: GlitchCreature    ## oyuncu — perspektif kaymasi sonrasi
var boss: SamuraiBoss
var camera: ScreenShake
var _boss_bar: Control
var _boss_bars: Dictionary
var _boss_root: Control
var _respawn_pending := false
var _hat_prop: Sprite2D
var _black: ColorRect
var _motes: Array[Node2D] = []
var _hud_layer: CanvasLayer
var _hud: HudPlayer
var _meta_done := false
var _spear_done := false
## Zorunlu secim ekrani durumu: {give, fight, idx, timer, layer}
var _choice: Dictionary = {}


func _ready() -> void:
	GameState.current_chapter = &"ch7"
	AudioManager.play_music(&"music/ch7")
	AudioManager.play_ambience(&"amb/wind")
	_build_terrain()
	_build_fx()
	_build_hud()
	SceneRouter.fade_to(0.0, 0.45)
	EventBus.actor_died.connect(_on_actor_died)
	if auto_advance:
		if GameState.get_flag(&"ch7_boss_dead", false):
			if GameState.get_flag(&"ouroboros_done", false):
				# Oyun tamamlanmis — dongu kapandi; Continue dogrudan
				# Prolog'a doner (Ouroboros: basa sar).
				call_deferred(&"_emit_scene_change", PROLOG_PATH)
			else:
				# Final oynandi ama epilog yarida kesildi (quit/crash):
				# jenerik zincirini yeniden kur — soft-lock onlemi.
				call_deferred(&"_finish")
		elif GameState.get_flag(&"ch7_intro_done", false):
			_spawn_fight()  # olum sonrasi reload: giris atlanir
		else:
			_run_intro()
	else:
		_spawn_fight()  # testler icin dogrudan savas


func _process(_delta: float) -> void:
	if boss != null and is_instance_valid(boss) and boss.active:
		_boss_root.visible = true
		HudBars.drain(_boss_bars, float(boss.health.current) / maxf(boss.health.max_health, 1), 160.0, _delta)
		# MetaDirector: boss %55 cana dusunce oyun kendisi saldiri yapar —
		# kontroller tersine doner + goruntu 4:3 bantlariyla daralir.
		if not _meta_done and boss.health.current <= boss.health.max_health * 0.55:
			_meta_done = true
			_meta_assault()
		# Ikinci meta an: %30 can — HUD kalbi sokulup oyuncuya atilir.
		if not _spear_done and _meta_done and is_instance_valid(creature) \
				and not creature.controls_inverted \
				and boss.health.current <= boss.health.max_health * 0.30:
			_spear_done = true
			_meta_spear()
	# Zorunlu secim: "SAPKAYI VER" ustunde 0.35s duran imlec glitchle
	# SAVAS'a kaydirilir — baris secenegi asla secemeyiz.
	if not _choice.is_empty() and _choice.idx == 0:
		_choice.timer += _delta
		if _choice.timer > 0.35:
			_choice_glitch_away()
	# Bosluk dususu: platform kenarindan dusen yaratik 1 can kaybedip geri doner
	if creature != null and not _respawn_pending \
			and (creature.global_position.y > 430.0 \
				or creature.global_position.y < -80.0):
		creature.global_position = Vector2(150, FLOOR_Y - 10)
		creature.velocity = Vector2.ZERO
		FX.glitch(0.4, 0.3)
		creature.take_damage(DamageInfo.make(1, null, Vector2.ZERO, false, true))
	# Zerrecik suzulmesi: yavas yukari + hafif yalpa, ustte sarilir
	for m in _motes:
		m.position.y -= 7.0 * _delta
		m.position.x += sin(Time.get_ticks_msec() / 900.0 + m.position.y * 0.05) * 5.0 * _delta
		if m.position.y < -8.0:
			m.position.y = 278.0
			m.position.x = randf() * 480.0



func _build_terrain() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.05, 0.04, 0.11)  # bosluk siyahi-moru (okunabilir)
	bg.size = Vector2(480, 270)
	bg.z_index = -10
	add_child(bg)
	# Uzak katman — kirik bellek artiklari, soluk mor parilti
	ParallaxBg.add(self, 480, [
		{id = &"bg/ash_far", scroll = 0.05, modulate = Color(0.6, 0.5, 0.9, 0.7)},
		{id = &"bg/ash_sky", scroll = 0.12, modulate = Color(0.5, 0.5, 0.85, 0.5)},
	])
	# Final sahnesinin merkezi: dunya yarigi (samurayin geldigi boyut yarisi)
	if AssetLoader.has_asset(&"prop/rift"):
		var rift := Sprite2D.new()
		rift.texture = AssetLoader.texture(&"prop/rift", Vector2i(96, 140))
		rift.global_position = Vector2(240, 78)
		rift.modulate = Color(1.2, 0.9, 1.5, 0.95)
		rift.z_index = -1
		add_child(rift)
		var rt := rift.create_tween().set_loops()
		rt.tween_property(rift, "scale", Vector2(1.06, 1.10), 1.6).set_trans(Tween.TRANS_SINE)
		rt.tween_property(rift, "scale", Vector2.ONE, 1.6).set_trans(Tween.TRANS_SINE)
	# Solgun ay — boslugun uzak ufku
	if AssetLoader.has_asset(&"bg/j_moon"):
		var moon := Sprite2D.new()
		moon.texture = AssetLoader.texture(&"bg/j_moon", Vector2i(26, 26))
		moon.global_position = Vector2(414, 36)
		moon.modulate = Color(0.7, 0.65, 1.0, 0.5)
		moon.z_index = -2
		add_child(moon)
	# Yuzan glitch zerrecikleri — CRT'den sizen kivilcim tozu
	for i in 9:
		var mt: Node2D
		if i < 4 and AssetLoader.has_frames(&"npc/glitchb"):
			var am := AnimatedSprite2D.new()
			am.sprite_frames = AssetLoader.frames(&"npc/glitchb")
			am.scale = Vector2(7, 7) / am.sprite_frames.get_frame_texture(
				am.sprite_frames.get_animation_names()[0], 0).get_size()
			am.play(am.sprite_frames.get_animation_names()[0])
			mt = am
		else:
			mt = Sprite2D.new()
			mt.texture = AssetLoader.texture(&"enemy/glitch", Vector2i(5, 5))
		mt.modulate = Color(0.5, 1.0, 0.9, randf_range(0.25, 0.6))
		mt.global_position = Vector2(randf() * 480.0, randf() * 270.0)
		mt.z_index = -1
		add_child(mt)
		_motes.append(mt)
	# Tek genis platform — boslukta asili
	var body := StaticBody2D.new()
	body.collision_layer = 1
	var col := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(360, 20)
	col.shape = rect
	body.add_child(col)
	body.global_position = Vector2(240, FLOOR_Y + 8)
	add_child(body)
	var sp := Sprite2D.new()
	sp.texture = AssetLoader.tiled_texture(&"terrain/cave_bricks", Vector2i(360, 20))
	sp.modulate = Color(0.6, 0.55, 0.9)
	sp.global_position = body.global_position
	add_child(sp)
	# Karaltma perdesi (cutscene fade icin)
	_black = ColorRect.new()
	_black.color = Color.BLACK
	_black.size = Vector2(480, 270)
	_black.modulate.a = 0.0
	_black.z_index = 60
	add_child(_black)


func _spawn_fight() -> void:
	GameState.set_flag(&"ch7_intro_done")  # reload'da intro bir daha oynamaz
	# Perspektif: oyuncu = Glitch Yaratik (solda, ufak), samuray = boss
	creature = GlitchCreature.new()
	creature.global_position = Vector2(150, FLOOR_Y - 10)
	creature.set_input_source(PlayerInputSource.new())
	add_child(creature)
	var hl := CanvasLayer.new()
	add_child(hl)
	# Yaratik kalpleri; portrede samuray degil yaratik yuzu (ruh cubugu yok —
	# yaratigin soul harcama aksiyonu yok, bos cubuk gostermeyiz)
	_hud = HudPlayer.make(creature, false, &"enemy/glitch_creature")
	hl.add_child(_hud)

	boss = SamuraiBoss.new()
	boss.name = "Samurai"
	boss.arena_root = self
	boss.arena_left = 60.0
	boss.arena_right = 420.0
	boss.global_position = Vector2(330, FLOOR_Y - 16)
	add_child(boss)
	boss.defeated.connect(_on_boss_defeated, CONNECT_ONE_SHOT)
	_fight_choice()

	if GameState.has_death_mark():
		var shade := DeathShade.new()
		shade.global_position = GameState.get_flag(&"death_mark_pos",
			Vector2(150, FLOOR_Y - 10))
		add_child(shade)


func _run_intro() -> void:
	# Samuray bosluga girer; ortada kasayi tutan yaratik bekler
	samurai = Samurai.new()
	samurai.global_position = Vector2(40, FLOOR_Y - 20)
	add_child(samurai)

	_hat_prop = Sprite2D.new()
	_hat_prop.texture = AssetLoader.texture(&"prop/hat", Vector2i(22, 12))
	# Kasa, kucuk karanlik kutlenin ustunde (prolog yaratik gorunumu)
	var blob := Node2D.new()
	blob.name = "HatCreature"
	var bs := Sprite2D.new()
	bs.texture = AssetLoader.texture(&"enemy/glitch_creature", Vector2i(16, 14))
	bs.modulate = Color(0.05, 0.05, 0.12)
	blob.add_child(bs)
	for dx in [-3.0, 3.0]:
		var eye := ColorRect.new()
		eye.size = Vector2(2, 3)
		eye.position = Vector2(dx - 1, -4)
		eye.color = Color(0.4, 1.0, 0.9)
		bs.add_child(eye)
	_hat_prop.position = Vector2(0, -9)
	blob.add_child(_hat_prop)
	blob.global_position = Vector2(300, FLOOR_Y - 8)
	add_child(blob)

	samurai.sm.change_to(Samurai.S_CUTSCENE, true)
	var cs := CutscenePlayer.new()
	add_child(cs)
	cs.play([
		{op = "wait", t = 0.6},
		{op = "walk_to", node = "samurai", x = 230, speed = 60.0},
		{op = "picto", node = "samurai", icon = &"alarm", t = 1.0, wait = true},
		# Yaratik kasayi samuraya geri verir — ve dunya kafamizin ustune ters doner
		{op = "hop_to", node = "HatCreature", to = Vector2(280, FLOOR_Y - 40),
			dur = 0.4, arc = 18.0},
		{op = "call", fn = func() -> void:
			_hat_prop.get_parent().remove_child(_hat_prop)
			samurai.add_child(_hat_prop)
			_hat_prop.position = Vector2(0, -24)},
		{op = "wait", t = 0.4},
		{op = "glitch", strength = 1.4, dur = 1.4},
		{op = "fade", node = "black", to_a = 1.0, dur = 0.5},
		{op = "call", fn = func() -> void:
			# Perspektif kaymasi: samuray sahneden boss'a donusur,
			# oyuncu yaratigi kontrol eder
			samurai.queue_free()
			blob.queue_free()
			_spawn_fight()},
		{op = "wait", t = 0.3},
		{op = "fade", node = "black", to_a = 0.0, dur = 0.8},
	], {"samurai": samurai, "HatCreature": blob, "black": _black})


func _on_boss_defeated() -> void:
	# Bos bar dusme isini bitirdi — temizlenen arenada bos bar kalmasin.
	_boss_root.visible = false
	GameState.set_flag(&"ch7_boss_dead")
	SaveSystem.save_game()
	AudioManager.play_sfx(&"sfx/gameover")
	await get_tree().create_timer(1.8, true).timeout
	# Ouroboros: yaratik kasayi birakip CRT isigina siner -> Prolog
	var cs := CutscenePlayer.new()
	add_child(cs)
	cs.play([
		{op = "glitch", strength = 1.5, dur = 1.6},
		{op = "hop_to", node = "creature", to = Vector2(240, FLOOR_Y - 30),
			dur = 0.6, arc = 20.0},
		{op = "call", fn = func() -> void:
			var hat := Sprite2D.new()
			hat.texture = AssetLoader.texture(&"prop/hat", Vector2i(22, 12))
			hat.position = Vector2(0, -9)
			creature.add_child(hat)},
		{op = "wait", t = 0.6},
		{op = "fade", node = "black", to_a = 1.0, dur = 1.0},
		{op = "glitch", strength = 1.6, dur = 1.0},
	], {"creature": creature, "black": _black},
	func() -> void:
		GameState.set_flag(&"ouroboros_done", true)
		SaveSystem.save_game())
	cs.finished.connect(_finish, CONNECT_ONE_SHOT)


func _finish() -> void:
	# Dongu kapanir: "15 YIL SONRA..." karti — prologdaki sabah, bu kez
	# kasayi takacak olan genc samurayin dongusu. Sonra jenerik + Prolog.
	await get_tree().create_timer(1.0, true).timeout
	var card := Label.new()
	card.text = "15 YIL SONRA..." if Settings.language == "tr" else "15 YEARS LATER..."
	card.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	card.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	card.set_anchors_preset(Control.PRESET_FULL_RECT)
	card.modulate.a = 0.0
	card.add_theme_font_size_override("font_size", 18)
	card.add_theme_color_override("font_color", Color(0.9, 0.85, 0.7))
	card.add_theme_color_override("font_shadow_color", Color(0.2, 0.05, 0.08))
	card.add_theme_constant_override("shadow_offset_x", 2)
	card.add_theme_constant_override("shadow_offset_y", 2)
	var cl := CanvasLayer.new()
	cl.layer = 125
	add_child(cl)
	cl.add_child(card)
	var tw := create_tween()
	tw.tween_property(card, "modulate:a", 1.0, 0.8)
	tw.tween_interval(2.0)
	tw.tween_property(card, "modulate:a", 0.0, 0.8)
	await tw.finished
	cl.queue_free()
	# Jenerik (CREDITS.md'den) sonra Prolog'a don
	AudioManager.play_music(&"music/credits")
	var credits := Credits.new()
	add_child(credits)
	credits.finished.connect(func() -> void:
		if auto_advance:
			EventBus.scene_change_requested.emit(PROLOG_PATH),
		CONNECT_ONE_SHOT)


func _emit_scene_change(path: String) -> void:
	EventBus.scene_change_requested.emit(path)


## MetaDirector saldirisi: glitch pulsu + swap isaretiyle uyarilir,
## sonra ~6s boyunca kontroller ters doner ve ust/alt siyah bantlar
## goruntuyu 4:3'e kisitlar. Sure bitince her sey geri acilir.
## Zorunlu secim: perspektif kaymasindan sonra oyun oyuncuya iki
## secenek sunar — "SAPKAYI VER" uzerinde imlec durunca buton glitchlenip
## imleci "SAVAS"a kaydirir. Barisin yolu yok — Ouroboros temasi.
func _fight_choice() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 50
	add_child(layer)
	var box := HBoxContainer.new()
	box.add_theme_constant_override("separation", 64)
	var give := _choice_label("SAPKAYI VER")
	var fight := _choice_label("SAVAS")
	box.add_child(give)
	box.add_child(fight)
	layer.add_child(box)
	box.position = Vector2(240, 206)
	box.set_pivot_offset(Vector2.ZERO)
	await get_tree().process_frame
	box.position.x = 240 - box.size.x * 0.5
	_choice = {give = give, fight = fight, idx = 1,
		timer = 0.0, layer = layer}
	_choice_highlight()


func _choice_label(text: String) -> Label:
	var l := Label.new()
	l.text = text
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", 11)
	return l


func _choice_highlight() -> void:
	if _choice.is_empty():
		return
	var on := Color(0.95, 0.85, 0.55)
	var off := Color(0.55, 0.5, 0.6, 0.7)
	(_choice.give as Label).add_theme_color_override("font_color",
		on if _choice.idx == 0 else off)
	(_choice.fight as Label).add_theme_color_override("font_color",
		on if _choice.idx == 1 else off)


func _unhandled_input(event: InputEvent) -> void:
	if _choice.is_empty():
		return
	if event.is_action_pressed(&"move_left") or event.is_action_pressed(&"move_right"):
		_choice.idx = 1 - _choice.idx
		_choice.timer = 0.0
		AudioManager.play_sfx(&"sfx/ui")
		_choice_highlight()
	elif event.is_action_pressed(&"attack") or event.is_action_pressed(&"jump") \
			or event.is_action_pressed(&"ui_accept"):
		if _choice.idx == 0:
			_choice_glitch_away()  # "VER" secilemez — imlec SAVAS'a kayar
		else:
			_choice_decide()


## "SAPKAYI VER" butonu glitchlenir ve secim SAVAS'a kaydirilir —
## plan'daki 'zorunlu secim': hareketle de ustunde durmak mumkun degil.
func _choice_glitch_away() -> void:
	AudioManager.play_sfx(&"sfx/glitch")
	FX.glitch(0.7, 0.35)
	var give := _choice.give as Label
	var tw := create_tween()
	tw.tween_property(give, "modulate:a", 0.2, 0.06)
	tw.tween_property(give, "modulate:a", 1.0, 0.06)
	tw.tween_property(give, "modulate:a", 0.2, 0.06)
	tw.tween_property(give, "modulate:a", 1.0, 0.06)
	_choice.idx = 1
	_choice.timer = 0.0
	_choice_highlight()


func _choice_decide() -> void:
	var layer: CanvasLayer = _choice.layer
	_choice = {}
	if is_instance_valid(layer):
		layer.queue_free()
	AudioManager.play_sfx(&"sfx/reward")
	boss.activate()
	AudioManager.play_music(&"music/final_boss")


func _meta_assault() -> void:
	FX.glitch(1.0, 0.6)
	AudioManager.play_sfx(&"sfx/glitch")
	Pictogram.show_on(creature, &"swap", 2.0, Vector2(0, -18))
	await get_tree().create_timer(0.8, true).timeout
	if not is_instance_valid(creature):
		return
	creature.controls_inverted = true
	var top := ColorRect.new()
	top.color = Color.BLACK
	top.size = Vector2(480, 0)
	top.position = Vector2(0, 0)
	_hud_layer.add_child(top)
	var bottom := ColorRect.new()
	bottom.color = Color.BLACK
	bottom.size = Vector2(480, 0)
	bottom.position = Vector2(0, 270)
	_hud_layer.add_child(bottom)
	var tw := create_tween().set_parallel()
	tw.tween_property(top, "size:y", 38.0, 0.45).set_trans(Tween.TRANS_CUBIC)
	tw.tween_property(bottom, "size:y", 38.0, 0.45).set_trans(Tween.TRANS_CUBIC)
	tw.tween_property(bottom, "position:y", 232.0, 0.45).set_trans(Tween.TRANS_CUBIC)
	await get_tree().create_timer(5.5, true).timeout
	FX.glitch(1.0, 0.5)
	if is_instance_valid(creature):
		creature.controls_inverted = false
	var tw2 := create_tween().set_parallel()
	tw2.tween_property(top, "size:y", 0.0, 0.45).set_trans(Tween.TRANS_CUBIC)
	tw2.tween_property(bottom, "size:y", 0.0, 0.45).set_trans(Tween.TRANS_CUBIC)
	tw2.tween_property(bottom, "position:y", 270.0, 0.45).set_trans(Tween.TRANS_CUBIC)
	tw2.chain().tween_callback(func() -> void:
		top.queue_free()
		bottom.queue_free())


## Ikinci MetaDirector ani: HUD'daki son dolu kalp yerinden sokulur,
## glitchlenip yaratiga atilir (yavas homing). Degince hasar; sonra
## kalp yuvasina geri ucar. <2 kalpte sokulmez — adil degil.
func _meta_spear() -> void:
	if _hud == null or not is_instance_valid(_hud) \
			or creature.health.current < 2:
		return
	FX.glitch(1.0, 0.5)
	AudioManager.play_sfx(&"sfx/glitch")
	var idx := creature.health.current - 1
	# Asset'siz kurulumda HUD yedek bara duser, _hearts bos kalir —
	# mizrak yine de atilir (sprite AssetLoader yedegiyle cizilir).
	var heart: TextureRect = _hud._hearts[idx] \
		if idx < _hud._hearts.size() else null
	if heart != null:
		heart.visible = false
	var spear := HeartSpear.new()
	spear.global_position = heart.global_position + Vector2(4, 4) \
		if heart != null else Vector2(36, 10)
	add_child(spear)
	spear.returned.connect(func(sp: HeartSpear) -> void:
		if is_instance_valid(heart):
			heart.visible = true
		sp.queue_free(), CONNECT_ONE_SHOT)
	spear.launch(creature)


func _on_actor_died(actor: Node) -> void:
	if actor != creature or _respawn_pending:
		return
	_respawn_pending = true
	AudioManager.play_sfx(&"sfx/gameover", creature.global_position)
	FX.glitch(0.6, 0.5)
	await SceneRouter.fade_to(1.0, 0.7)
	GameState.mark_death(
		creature.last_ground_pos if creature.last_ground_pos != Vector2.ZERO
		else creature.global_position)
	SceneRouter.reload()  # dusmanlar + boss sifirlanir (intro atlanir)


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
	# Yarilmis dunya: glitch statik parlamalari butun arenayi kaplar
	var weather := WeatherFx.new()
	add_child(weather)
	weather.setup(camera, [{x0 = 0.0, x1 = 480.0, kind = "static"}])


func _build_hud() -> void:
	var layer := CanvasLayer.new()
	_hud_layer = layer
	add_child(layer)
	var bb := HudBars.make(160, 6, Color(0.9, 0.4, 0.3), true)
	bb.root.position = Vector2(160, 250)
	layer.add_child(bb.root)
	_boss_root = bb.root
	_boss_root.visible = false
	_boss_bars = bb
	_boss_bar = bb.fill
