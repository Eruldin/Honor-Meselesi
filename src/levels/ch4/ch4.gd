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

var _spawn_grace := false
var samurai: Samurai
var camera: ScreenShake
var _look_x := 0.0
var boss: RedTyrant
var _walls: Array[StaticBody2D] = []
var _boss_bar: Control
var _boss_bars: Dictionary
var _boss_root: Control
var _boss_started := false
var _boss_home := Vector2.ZERO
var _respawn_pending := false
var _gameover: Label


func _ready() -> void:
	GameState.current_chapter = &"ch4"
	AudioManager.play_music(&"music/ch4")
	AudioManager.play_ambience(&"amb/forest")  # neseli platform dunyasi
	_build_terrain()
	_build_entities()
	_build_fx()
	_build_hud()
	SceneRouter.fade_to(0.0, 0.45)
	EventBus.actor_died.connect(_on_actor_died)
	# M10: sakin/savas muzik katmani — yakin dusman combat temaya gecirir
	var md := MusicDirector.new()
	md.player = samurai
	md.calm_track = &"music/ch4"
	add_child(md)


func _process(delta: float) -> void:
	if samurai != null and is_instance_valid(samurai):
		_look_x = lerpf(_look_x,
			clampf(samurai.velocity.x * 0.14, -30.0, 30.0),
			1.0 - exp(-3.0 * delta))
		camera.global_position.x = clampf(
			samurai.global_position.x + _look_x, 240, LEVEL_W - 240)
	if boss != null and is_instance_valid(boss) and boss.active:
		_boss_root.visible = true
		HudBars.drain(_boss_bars, float(boss.health.current) / maxf(boss.health.max_health, 1), 160.0, delta)

	# Bosluk dususu: asama disina dusen 1 can kaybedip checkpoint'e doner
	if samurai != null and not _respawn_pending 			and (samurai.global_position.y > 430.0 				or samurai.global_position.y < -80.0):
		var cp2: Vector2 = GameState.respawn_point(Vector2(60, FLOOR_Y - 20))
		samurai.global_position = cp2 + Vector2(0, -14)
		samurai.velocity = Vector2.ZERO
		samurai.set_gravity_flipped(false)
		FX.glitch(0.4, 0.3)
		samurai.take_damage(DamageInfo.make(1, null, Vector2.ZERO, false, true))

func _build_terrain() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.45, 0.62, 0.9)  # nostaljik acik gokyuzu
	bg.size = Vector2(LEVEL_W, 270)
	add_child(bg)
	# SunnyLand Winter parallax'i — retro platforum derinligi
	ParallaxBg.add(self, LEVEL_W, [
		{id = &"bg/winter_sky", scroll = 0.0},
		{id = &"bg/winter_far", scroll = 0.12},
		{id = &"bg/winter_mid", scroll = 0.3},
		{id = &"bg/winter_near", scroll = 0.55},
	])

	# Bozuk dekor: gozlu bulutlar (bir iki tanesi ara ara devrilir)
	for i in 7:
		var c := MadCloud.new()
		c.global_position = Vector2(120.0 + i * 190.0, 40.0 + (i % 3) * 22.0)
		add_child(c)

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
		ps.texture = AssetLoader.tiled_texture(&"terrain/pipe", Vector2i(20, 26))
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
	sprite.texture = AssetLoader.tiled_texture(&"terrain/ch4_ground", Vector2i(size))
	sprite.modulate = Color(0.35, 0.6, 0.3)
	body.add_child(sprite)
	body.global_position = center
	add_child(body)


func _build_entities() -> void:
	samurai = Samurai.new()
	var spawn := Vector2(60, FLOOR_Y - 20)
	var cp: Vector2 = GameState.respawn_point(Vector2(-10000, -10000))
	if cp.x > -5000.0:
		spawn = cp + Vector2(0, -14)
		_spawn_grace = true
	if _spawn_grace:
		samurai.invuln_timer = maxf(samurai.invuln_timer, 1.0)
	samurai.global_position = spawn
	add_child(samurai)

	# Kalp kristali — en yuksek retro platformun ustunde
	var sh := HeartShard.new()
	sh.pickup_id = &"ch4_ridge"
	sh.global_position = Vector2(700, 138)
	add_child(sh)

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

	# Havada bozuk veri — boru bolgesindeki platformlari korur
	var fs := FlyingSword.new()
	fs.global_position = Vector2(640, FLOOR_Y - 95)
	add_child(fs)

	# Kargalar gokyuzu devriyesi — dinlenme noktasi oncesi son baski
	var cw := Crow.new()
	cw.global_position = Vector2(880, FLOOR_Y - 80)
	add_child(cw)

	var rest := RestPoint.new()
	rest.checkpoint_id = &"ch4_plaza"
	rest.global_position = Vector2(1060, FLOOR_Y - 12)
	add_child(rest)

	# Hirsiz cameo — boyutlar arasi kacis goruntusu, tek seferlik
	var cameo_trig := Area2D.new()
	cameo_trig.collision_layer = 0
	cameo_trig.collision_mask = 4
	var cc := CollisionShape2D.new()
	var cr := RectangleShape2D.new()
	cr.size = Vector2(10, 200)
	cc.shape = cr
	cameo_trig.add_child(cc)
	cameo_trig.global_position = Vector2(850, FLOOR_Y - 40)
	cameo_trig.area_entered.connect(_on_thief_cameo, CONNECT_ONE_SHOT)
	add_child(cameo_trig)

	if not GameState.get_flag(&"ch4_boss_dead", false):
		boss = RedTyrant.new()
		boss.name = "KizilTulumluTiran"
		boss.arena_root = self
		boss.arena_left = ARENA_L
		boss.arena_right = ARENA_R
		boss.global_position = Vector2(1420, FLOOR_Y - 14)
		add_child(boss)
		_boss_home = boss.global_position
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
	elif not GameState.get_flag(&"ch4_done", false):
		# Boss olmus ama bolum-gecisi hic oynanmamis (quit/crash/olum):
		# odul yazili, epilog yok — arena cikisina portal dogur.
		_make_cleared_exit(&"fx/portal")

	# Olum golgesi — olumde birakilan ruh vurunca geri alinir
	if GameState.has_death_mark():
		var shade := DeathShade.new()
		shade.global_position = GameState.get_flag(&"death_mark_pos",
			Vector2(60, FLOOR_Y - 14))
		add_child(shade)


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
	# Checkpoint/olum respawn'i: kamerayi oyuncuya kilit olarak kur —
	# smoothing (240,135)'ten spawn'a haritayi taramasin.
	camera.global_position.x = clampf(samurai.global_position.x,
		240.0, LEVEL_W - 240.0)
	camera.reset_smoothing()
	var fx := FxListener.new()
	fx.camera_path = camera.get_path()
	add_child(fx)
	add_child(PostFX.new())
	add_child(SettingsMenu.new())

	# Retro alem CRT gurultusu — kisa omurlu renkli piksel parlamalari
	var weather := WeatherFx.new()
	add_child(weather)
	weather.setup(camera, [{x0 = 0.0, x1 = LEVEL_W, kind = "static"}])


func _build_hud() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	layer.add_child(HudPlayer.make(samurai))
	# Boss can cubugu
	var boss_bar := HudBars.make(160, 6, Color(0.95, 0.3, 0.2), true)
	boss_bar.root.position = Vector2(160, 250)
	layer.add_child(boss_bar.root)
	_boss_root = boss_bar.root
	_boss_root.visible = false
	_boss_bars = boss_bar
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
	BossIntro.play(boss)
	_boss_root.visible = true
	_boss_bar.size.x = 160.0
	await get_tree().create_timer(1.15, false).timeout
	if is_instance_valid(boss) and boss.health.is_alive() and _boss_started:
		boss.activate()


func _on_boss_defeated() -> void:
	# Bos bar dusme isini bitirdi — temizlenen arenada bos bar kalmasin.
	_boss_root.visible = false
	# Kesik boyunca kalan dusmanlar sersemleyerek durur — dalis
	# artik sinemayi kirpmaz.
	for e in get_tree().get_nodes_in_group(&"enemies"):
		if e is EnemyBase and e.health.is_alive():
			e.stagger_timer = maxf(e.stagger_timer, 4.0)
	GameState.set_flag(&"ch4_boss_dead")
	SaveSystem.save_game()
	AudioManager.play_sfx(&"sfx/gameover")
	# Retro olum: "GAME OVER" bandi + Tiran asagi duser
	_gameover.visible = true
	if is_instance_valid(boss):
		var tw := boss.create_tween()
		tw.tween_property(boss, "position:y", boss.position.y + 320.0, 1.2)
		tw.parallel().tween_property(boss, "rotation", PI * 2.0, 1.2)

	await get_tree().create_timer(1.6, false).timeout
	_gameover.visible = false

	var portal := PortalFx.make()
	portal.global_position = Vector2(ARENA_R - 30, FLOOR_Y - 34)
	add_child(portal)
	AudioManager.play_music(&"music/victory", &"music/ch4")

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
	SaveSystem.save_game()
	if auto_advance:
		EventBus.scene_change_requested.emit(CH5_PATH)


## Boss odasi temizlenmis ama bolum-gecisi oynanmamis durumda: arena
## cikisina portal + giris tetigi — oyuncu yuruyerek sonraki bolume gecer.
func _make_cleared_exit(portal_key: StringName) -> void:
	var portal := PortalFx.make(Vector2(38, 62), portal_key)
	portal.global_position = Vector2(ARENA_R - 30, FLOOR_Y - 34)
	add_child(portal)
	var trig := Area2D.new()
	trig.collision_layer = 0
	trig.collision_mask = 4
	var c := CollisionShape2D.new()
	var r := RectangleShape2D.new()
	r.size = Vector2(30, 140)
	c.shape = r
	trig.add_child(c)
	trig.global_position = portal.global_position
	trig.area_entered.connect(
		func(_a: Area2D) -> void: _go_ch5(), CONNECT_ONE_SHOT)
	add_child(trig)


func _on_thief_cameo(area: Area2D) -> void:
	var p := area.get_parent()
	while p != null and not p.is_in_group(&"player"):
		p = p.get_parent()
	if p == null or GameState.get_flag(&"ch4_cameo_done", false):
		return
	GameState.set_flag(&"ch4_cameo_done")
	ThiefCameo.spawn(self, Vector2(880, FLOOR_Y - 14))


func _on_actor_died(actor: Node) -> void:
	if actor != samurai or _respawn_pending:
		return
	_respawn_pending = true
	AudioManager.play_sfx(&"sfx/gameover", samurai.global_position)
	FX.glitch(0.6, 0.5)
	await SceneRouter.fade_to(1.0, 0.7)
	GameState.mark_death(
		samurai.last_ground_pos if samurai.last_ground_pos != Vector2.ZERO
		else samurai.global_position)
	SceneRouter.reload()

