extends Node2D
## M9 — Bolum 6: Parcalanmis Bellek + Glitch Amalgam.
## Coken boyutlarin kirintilari havada yuzen adaciklar gibi durur;
## platformlar "unutulup" geri gelir (FlickerPlatform), onceki
## bolumlerin dusmanlari soluk cyan yankilar olarak dolanir.
## Burada glitch serbest — senaryo geregi (CRT disinda tek bolge).

const CH7_PATH := "res://src/levels/ch7/Ch7.tscn"
const FLOOR_Y := 250.0
const LEVEL_W := 1700.0
const ARENA_X := 1300.0
const ARENA_L := 1310.0
const ARENA_R := 1610.0

@export var auto_advance := true

var _spawn_grace := false
var samurai: Samurai
var camera: ScreenShake
var _look_x := 0.0
var boss: GlitchAmalgam
var _walls: Array[StaticBody2D] = []
var _boss_bar: Control
var _boss_bars: Dictionary
var _boss_root: Control
var _boss_started := false
var _boss_home := Vector2.ZERO
var _respawn_pending := false
var _glitch_t := 6.0


func _ready() -> void:
	GameState.current_chapter = &"ch6"
	AudioManager.play_music(&"music/ch6")
	AudioManager.play_ambience(&"amb/cave")  # boslugun yankisi
	_build_terrain()
	_build_entities()
	_build_fx()
	_build_hud()
	SceneRouter.fade_to(0.0, 0.45)
	EventBus.actor_died.connect(_on_actor_died)
	# M10: sakin/savas muzik katmani — yakin dusman combat temaya gecirir
	var md := MusicDirector.new()
	md.player = samurai
	md.calm_track = &"music/ch6"
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
	# Ortam glitch'i: ara ara hafif dalgalanma (bu bolume ozel)
	_glitch_t -= delta
	if _glitch_t <= 0.0:
		_glitch_t = randf_range(5.0, 9.0)
		FX.glitch(0.25, 0.5)

	# Bosluk dususu: asama disina dusen 1 can kaybedip checkpoint'e doner
	if samurai != null and not _respawn_pending 			and (samurai.global_position.y > 430.0 				or samurai.global_position.y < -80.0):
		var cp2: Vector2 = GameState.respawn_point(Vector2(60, FLOOR_Y - 20))
		samurai.global_position = cp2 + Vector2(0, -14)
		samurai.velocity = Vector2.ZERO
		samurai.set_gravity_flipped(false)
		FX.glitch(0.4, 0.3)
		samurai.take_damage(DamageInfo.make(1, null, Vector2.ZERO, false, true))

func _build_terrain() -> void:
	# Bosluk gokyuzu: derin mordan ufuk cizgisinde soluk magenta pariltiya
	var grad := Gradient.new()
	grad.set_color(0, Color(0.06, 0.05, 0.13))
	grad.set_color(1, Color(0.3, 0.13, 0.38))
	grad.add_point(0.55, Color(0.10, 0.08, 0.2))
	grad.add_point(0.82, Color(0.2, 0.14, 0.34))
	var gtex := GradientTexture2D.new()
	gtex.gradient = grad
	gtex.fill = GradientTexture2D.FILL_LINEAR
	gtex.fill_from = Vector2(0.5, 0.0)
	gtex.fill_to = Vector2(0.5, 1.0)
	var bg := TextureRect.new()
	bg.texture = gtex
	bg.size = Vector2(LEVEL_W, 270)
	bg.stretch_mode = TextureRect.STRETCH_SCALE
	add_child(bg)
	# Uzakta kirik boyut goruntuleri — ash_far katmani cyan-magenta'da
	ParallaxBg.add(self, LEVEL_W, [
		{id = &"bg/ash_far", scroll = 0.08, modulate = Color(0.5, 0.55, 0.95, 0.55)},
		{id = &"bg/ash_sky", scroll = 0.2, modulate = Color(0.55, 0.6, 0.95, 0.38)},
	])

	# Ana zemin parcalari — araliklarla (bellek boslugu): ucus tehlikesi
	for seg in [[240, FLOOR_Y + 10, 480], [800, FLOOR_Y + 10, 330],
			[1300, FLOOR_Y + 10, 620]]:
		_add_ground(Vector2(seg[0], seg[1]), Vector2(seg[2], 24))
	_add_ground(Vector2(-6, 135), Vector2(12, 270))

	# FlickerPlatform'lar — bosluklari asma yollari
	for fp in [[480, 210, 0.0], [560, 190, 1.2], [660, 200, 2.3],
			[960, 205, 0.6], [1050, 185, 1.8], [1140, 198, 3.0]]:
		var f := FlickerPlatform.new()
		f.global_position = Vector2(fp[0], fp[1])
		f.phase_offset = fp[2]
		add_child(f)

	# Kirik boyut parcalari — onceki bolumlerin tile dokularindan adaciklar
	for frag in [[180, 120, &"terrain/ground_face", Color(0.7, 0.7, 1.0)],
			[720, 110, &"terrain/block", Color(0.7, 0.8, 1.0)],
			[1150, 100, &"terrain/ground_face", Color(0.6, 0.7, 1.1)],
			[1450, 95, &"terrain/block", Color(0.7, 0.7, 1.0)]]:
		var s := Sprite2D.new()
		s.texture = AssetLoader.tiled_texture(frag[2], Vector2i(48, 18))
		s.modulate = frag[3]
		s.global_position = Vector2(frag[0], frag[1])
		s.rotation = randf_range(-0.06, 0.06)
		add_child(s)

	# Bellek monolitleri — boslukta yuzuce dev soluk veri saslaklari
	for slab in [[330.0, 150.0, 34.0, 130.0, Color(0.5, 0.7, 1.0, 0.11)],
			[890.0, 120.0, 44.0, 170.0, Color(0.9, 0.4, 0.8, 0.10)],
			[1210.0, 145.0, 30.0, 150.0, Color(0.5, 0.7, 1.0, 0.12)],
			[1660.0, 120.0, 52.0, 165.0, Color(0.6, 0.5, 1.0, 0.10)]]:
		var m := ColorRect.new()
		m.size = Vector2(slab[2], slab[3])
		m.color = slab[4]
		m.position = Vector2(slab[0] - slab[2] / 2.0, slab[1] - slab[3] / 2.0)
		add_child(m)
		# kristal ust kenar — pariltili sath
		var edge := ColorRect.new()
		var c: Color = slab[4]
		edge.color = Color(minf(c.r * 1.7, 1.0), minf(c.g * 1.7, 1.0), c.b, 0.4)
		edge.size = Vector2(slab[2], 1.5)
		edge.position = m.position
		add_child(edge)

	# Bellek yankisi prop'lar — onceki dunyalarin soluk hatiralari
	for echo in [[300, &"prop/deco_pillar", Vector2i(20, 60), Color(0.45, 0.5, 0.9, 0.5)],
			[760, &"prop/deco_lantern", Vector2i(12, 18), Color(0.9, 0.5, 0.85, 0.45)],
			[1080, &"prop/deco_tower", Vector2i(30, 70), Color(0.45, 0.55, 1.0, 0.45)],
			[1540, &"prop/deco_pillar2", Vector2i(18, 55), Color(0.6, 0.5, 1.0, 0.5)]]:
		if not AssetLoader.has_asset(echo[1]):
			continue
		var e := Sprite2D.new()
		e.texture = AssetLoader.texture(echo[1], echo[2])
		e.modulate = echo[3]
		e.global_position = Vector2(echo[0], 135.0 - float(echo[2].y) * 0.5 + 28.0)
		e.rotation = randf_range(-0.05, 0.05)
		add_child(e)

	for wx in [ARENA_L - 14, ARENA_R + 8]:
		var wall := _make_wall(Vector2(wx, 135))
		wall.set_deferred("collision_layer", 0)
		wall.visible = false
		_walls.append(wall)
		add_child(wall)

	# Bosluk yankisi — iki damla kaynagi magara hissini derinlestirir
	for dx in [700.0, 1050.0]:
		var drip := AmbientDrip.new()
		drip.global_position = Vector2(dx, 180)
		add_child(drip)


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
	sprite.texture = AssetLoader.tiled_texture(&"terrain/cave_bricks", Vector2i(size))
	sprite.modulate = Color(0.4, 0.38, 0.62)
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

	# Kalp kristali — bellek adasinin ustundeki flicker platformdan erisilir
	var sh := HeartShard.new()
	sh.pickup_id = &"ch6_isle"
	sh.global_position = Vector2(1050, 153)
	add_child(sh)

	# Bellek yankilari — onceki bolumlerin dusmanlari, cyan soluk
	var echoes: Array = [
		[Villager.new(), 300], [CyberNinja.new(), 540],
		[Villager.new(), 830], [AshHusk.new(), 1050],
		[FlyingSword.new(), 1100, -40], [Turtle.new(), 1190],
	]
	for e in echoes:
		var en: EnemyBase = e[0]
		en.modulate = Color(0.6, 0.95, 1.1, 0.85)
		var yo: float = e[2] if e.size() > 2 else 0.0
		en.global_position = Vector2(e[1], FLOOR_Y - 12 + yo)
		add_child(en)

	var rest := RestPoint.new()
	rest.checkpoint_id = &"ch6_shards"
	rest.global_position = Vector2(1260, FLOOR_Y - 12)
	add_child(rest)

	# Hirsiz cameo — bellek dunyasinda bile kaciyor, tek seferlik
	var cameo_trig := Area2D.new()
	cameo_trig.collision_layer = 0
	cameo_trig.collision_mask = 4
	var cc := CollisionShape2D.new()
	var cr := RectangleShape2D.new()
	cr.size = Vector2(10, 200)
	cc.shape = cr
	cameo_trig.add_child(cc)
	cameo_trig.global_position = Vector2(950, FLOOR_Y - 40)
	cameo_trig.area_entered.connect(_on_thief_cameo, CONNECT_ONE_SHOT)
	add_child(cameo_trig)

	if not GameState.get_flag(&"ch6_boss_dead", false):
		boss = GlitchAmalgam.new()
		boss.name = "GlitchAmalgam"
		boss.arena_root = self
		boss.arena_left = ARENA_L
		boss.arena_right = ARENA_R
		boss.floor_y = FLOOR_Y
		boss.global_position = Vector2(1520, FLOOR_Y - 16)
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
	elif not GameState.get_flag(&"ch6_done", false):
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

	# Hafiza boslugu: havada suruklenen cyan toz taneleri
	var weather := WeatherFx.new()
	add_child(weather)
	weather.setup(camera, [{x0 = 0.0, x1 = LEVEL_W, kind = "motes"}])


func _build_hud() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	layer.add_child(HudPlayer.make(samurai))
	var boss_bar := HudBars.make(160, 6, Color(0.4, 0.9, 1.0), true)
	boss_bar.root.position = Vector2(160, 250)
	layer.add_child(boss_bar.root)
	_boss_root = boss_bar.root
	_boss_root.visible = false
	_boss_bars = boss_bar
	_boss_bar = boss_bar.fill


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
	FX.glitch(0.9, 0.8)
	AudioManager.play_music(&"music/ch6_boss")
	BossIntro.play(boss)
	_boss_root.visible = true
	_boss_bar.size.x = 160.0
	await get_tree().create_timer(1.15).timeout
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
	GameState.set_flag(&"ch6_boss_dead")
	SaveSystem.save_game()
	await get_tree().create_timer(1.6, true).timeout
	var portal := PortalFx.make()
	portal.global_position = Vector2(ARENA_R - 30, FLOOR_Y - 34)
	add_child(portal)
	AudioManager.play_music(&"music/victory", &"music/ch6")

	samurai.sm.change_to(Samurai.S_CUTSCENE, true)
	var cutscene := CutscenePlayer.new()
	add_child(cutscene)
	cutscene.play([
		{op = "glitch", strength = 1.2, dur = 1.2},
		{op = "wait", t = 0.4},
		{op = "walk_to", node = "samurai", x = portal.global_position.x - 8, speed = 120.0},
		{op = "call", fn = func() -> void:
			samurai.create_tween().tween_property(samurai, "modulate:a", 0.0, 0.25)},
		{op = "wait", t = 0.3},
	], {"samurai": samurai, "portal": portal},
	func() -> void:
		samurai.global_position = portal.global_position)
	cutscene.finished.connect(_go_ch7, CONNECT_ONE_SHOT)


func _go_ch7() -> void:
	GameState.set_flag(&"ch6_done")
	GameState.current_chapter = &"ch7"
	SaveSystem.save_game()
	if auto_advance:
		EventBus.scene_change_requested.emit(CH7_PATH)


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
		func(_a: Area2D) -> void: _go_ch7(), CONNECT_ONE_SHOT)
	add_child(trig)


func _on_thief_cameo(area: Area2D) -> void:
	var p := area.get_parent()
	while p != null and not p.is_in_group(&"player"):
		p = p.get_parent()
	if p == null or GameState.get_flag(&"ch6_cameo_done", false):
		return
	GameState.set_flag(&"ch6_cameo_done")
	ThiefCameo.spawn(self, Vector2(980, FLOOR_Y - 14))


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

