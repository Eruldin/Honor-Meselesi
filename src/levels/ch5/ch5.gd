extends Node2D
## M8 — Bolum 5: Kul Diyari + Kul Muhafizi.
## Coken boyutlarin kuluna donusmus ovasi: moloz zemin, pasli variller,
## huysuz kovanlar ve dalis yapan yarasslar. Form odulu yok — bu bolumde
## yaratik'in pesine dusen samuray sadece atmosferle ve kalintilarla
## konusur. Arena -> Kul Muhafizi -> portal -> Bolum 6.

const CH6_PATH := "res://src/levels/ch6/Ch6.tscn"
const FLOOR_Y := 250.0
const LEVEL_W := 1700.0
const ARENA_X := 1290.0
const ARENA_L := 1300.0
const ARENA_R := 1600.0

@export var auto_advance := true

var _spawn_grace := false
var samurai: Samurai
var camera: ScreenShake
var _look_x := 0.0
var boss: AshGuardian
var _walls: Array[StaticBody2D] = []
var _boss_bar: Control
var _boss_bars: Dictionary
var _boss_root: Control
var _boss_started := false
var _boss_home := Vector2.ZERO
var _respawn_pending := false


func _ready() -> void:
	GameState.current_chapter = &"ch5"
	AudioManager.play_music(&"music/ch5")
	AudioManager.play_ambience(&"amb/wind")  # issiz kul ovasi
	_build_terrain()
	_build_entities()
	_build_fx()
	_build_hud()
	SceneRouter.fade_to(0.0, 0.45)
	EventBus.actor_died.connect(_on_actor_died)
	# M10: sakin/savas muzik katmani — yakin dusman combat temaya gecirir
	var md := MusicDirector.new()
	md.player = samurai
	md.calm_track = &"music/ch5"
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
	bg.color = Color(0.32, 0.28, 0.3)  # kul grisi-mor gokyuzu
	bg.size = Vector2(LEVEL_W, 270)
	add_child(bg)
	ParallaxBg.add(self, LEVEL_W, [
		{id = &"bg/ash_sky", scroll = 0.0, modulate = Color(0.8, 0.72, 0.68)},
		{id = &"bg/ash_far", scroll = 0.15, modulate = Color(0.72, 0.62, 0.58)},
		{id = &"bg/cemetery_far", scroll = 0.35, modulate = Color(0.6, 0.52, 0.52, 0.8)},
	])

	# Kul zemini — sakin kir yuzu (Garbage tileset cok gurultuluydu)
	_add_ground(Vector2(LEVEL_W / 2, FLOOR_Y + 10), Vector2(LEVEL_W, 24))
	_add_ground(Vector2(-6, 135), Vector2(12, 270))
	# Yikik yukseltiler
	_add_ground(Vector2(430, 196), Vector2(70, 10))
	_add_ground(Vector2(690, 178), Vector2(80, 10))
	_add_ground(Vector2(950, 196), Vector2(70, 10))
	_add_ground(Vector2(1120, 182), Vector2(64, 10))

	# Coken zemin kirigi (dusen parca — gerilim)
	for gx in [560.0, 1010.0]:
		var crack := CrackedGround.new()
		crack.global_position = Vector2(gx, FLOOR_Y - 6)
		add_child(crack)

	# Kalinti susleri: pasli variller, eski lastikler, kirilmis bank
	var prop_pos: Array = [
		[150, &"prop/barrel_rust"], [155, &"prop/barrel_rust"],
		[380, &"prop/tires"], [520, &"prop/barrel_rust"],
		[740, &"prop/bench"], [880, &"prop/tires"],
		[1080, &"prop/barrel_rust"], [1240, &"prop/bench"],
	]
	for pp in prop_pos:
		var s := Sprite2D.new()
		s.texture = AssetLoader.texture(pp[1], Vector2i(14, 14))
		s.global_position = Vector2(pp[0], FLOOR_Y - 9)
		add_child(s)

	# Buyuk harabe parcalari — kule icine yari gomulu yontma kalintilar
	var ruins: Array = [
		[300, &"prop/statue", Vector2i(24, 32), 4.0],
		[620, &"prop/deco_wall", Vector2i(44, 20), 5.0],
		[960, &"prop/statue", Vector2i(20, 28), 5.0],
	]
	for r in ruins:
		if not AssetLoader.has_asset(r[1]):
			continue
		var ru := Sprite2D.new()
		ru.texture = AssetLoader.texture(r[1], r[2])
		ru.modulate = Color(0.5, 0.46, 0.44)
		ru.global_position = Vector2(r[0],
			FLOOR_Y - float(r[2].y) / 2.0 + float(r[3]))
		add_child(ru)

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


## Kalp kristali — kalici +1 maks can (en yuksek yikik yukseltinin ustunde).
func _add_shard(x: float, y: float, id: StringName) -> void:
	var sh := HeartShard.new()
	sh.pickup_id = id
	sh.global_position = Vector2(x, y)
	add_child(sh)


func _add_ground(center: Vector2, size: Vector2, tex_id := StringName()) -> void:
	var body := StaticBody2D.new()
	body.collision_layer = 1
	var col := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = size
	col.shape = rect
	body.add_child(col)
	var sprite := Sprite2D.new()
	if tex_id != &"" and AssetLoader.has_asset(tex_id):
		sprite.texture = AssetLoader.tiled_texture(tex_id, Vector2i(size))
	else:
		sprite.texture = AssetLoader.tiled_texture(&"terrain/ch5_ground", Vector2i(size))
		sprite.modulate = Color(0.42, 0.38, 0.36)
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

	_add_shard(690, 146, &"ch5_ridge")

	# Kul kovanlari — surunen balta zombileri
	for hx in [330.0, 640.0, 900.0, 1160.0]:
		var h := AshHusk.new()
		h.global_position = Vector2(hx, FLOOR_Y - 12)
		add_child(h)
	# Kul yarasslari — yukseklik cesitli
	for bp in [Vector2(480, 160), Vector2(820, 150), Vector2(1090, 155)]:
		var b := AshBat.new()
		b.global_position = bp
		add_child(b)
	# Harabe savas kalintisi: yaklasana kalan tek kule — sola parry'lenebilir mermi
	var tur := Turret.new()
	tur.fire_interval = 2.2
	tur.global_position = Vector2(1010, FLOOR_Y - 10)
	add_child(tur)
	# Kul sovalyeleri — oyuncuyu taklit eden ayna dusmanlar (parry yapar)
	for kx in [870.0, 1180.0]:
		var k := AshKnight.new()
		k.global_position = Vector2(kx, FLOOR_Y - 12)
		add_child(k)

	var rest := RestPoint.new()
	rest.checkpoint_id = &"ch5_ruins"
	rest.global_position = Vector2(1230, FLOOR_Y - 12)
	add_child(rest)

	if not GameState.get_flag(&"ch5_boss_dead", false):
		boss = AshGuardian.new()
		boss.name = "KulMuhafizi"
		boss.arena_root = self
		boss.arena_left = ARENA_L
		boss.arena_right = ARENA_R
		boss.floor_y = FLOOR_Y
		boss.global_position = Vector2(1500, FLOOR_Y - 16)
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
	elif not GameState.get_flag(&"ch5_done", false):
		# Boss olmus ama bolum-gecisi hic oynanmamis (quit/crash/olum):
		# odul yazili, epilog yok — arena cikisina portal dogur.
		_make_cleared_exit(&"fx/portal_dark")

	# Hirsiz cameo — boyutlar arasi kacis goruntusu, tek seferlik
	var cameo_trig := Area2D.new()
	cameo_trig.collision_layer = 0
	cameo_trig.collision_mask = 4
	var cc := CollisionShape2D.new()
	var cr := RectangleShape2D.new()
	cr.size = Vector2(30, 80)
	cc.shape = cr
	cameo_trig.add_child(cc)
	cameo_trig.global_position = Vector2(700, FLOOR_Y - 40)
	cameo_trig.area_entered.connect(_on_thief_cameo, CONNECT_ONE_SHOT)
	add_child(cameo_trig)

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

	# Yanmis topraklar: havada suzulen kul + arada yukselen koz
	var weather := WeatherFx.new()
	add_child(weather)
	weather.setup(camera, [{x0 = 0.0, x1 = LEVEL_W, kind = "ash"}])


func _build_hud() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	layer.add_child(HudPlayer.make(samurai))
	var boss_bar := HudBars.make(160, 6, Color(0.7, 0.5, 0.4), true)
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
	FX.glitch(0.55, 0.6)
	AudioManager.play_music(&"music/ch5_boss")
	BossIntro.play(boss)
	_boss_root.visible = true
	_boss_bar.size.x = 160.0
	await get_tree().create_timer(1.15).timeout
	if is_instance_valid(boss) and boss.health.is_alive() and _boss_started:
		boss.activate()


func _on_boss_defeated() -> void:
	GameState.set_flag(&"ch5_boss_dead")
	SaveSystem.save_game()
	await SceneRouter.fade_to(1.0, 0.7)
	await get_tree().create_timer(0.3, true).timeout
	var portal := PortalFx.make(Vector2(38, 62), &"fx/portal_dark")
	portal.global_position = Vector2(ARENA_R - 30, FLOOR_Y - 34)
	add_child(portal)
	AudioManager.play_music(&"music/victory")

	samurai.sm.change_to(Samurai.S_CUTSCENE, true)
	var cutscene := CutscenePlayer.new()
	add_child(cutscene)
	cutscene.play([
		{op = "glitch", strength = 0.8, dur = 0.9},
		{op = "wait", t = 0.4},
		{op = "walk_to", node = "samurai", x = portal.global_position.x - 8, speed = 120.0},
		{op = "call", fn = func() -> void:
			samurai.create_tween().tween_property(samurai, "modulate:a", 0.0, 0.25)},
		{op = "wait", t = 0.3},
	], {"samurai": samurai, "portal": portal},
	func() -> void:
		samurai.global_position = portal.global_position)
	cutscene.finished.connect(_go_ch6, CONNECT_ONE_SHOT)


func _go_ch6() -> void:
	GameState.set_flag(&"ch5_done")
	GameState.current_chapter = &"ch6"
	SaveSystem.save_game()
	if auto_advance:
		EventBus.scene_change_requested.emit(CH6_PATH)


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
		func(_a: Area2D) -> void: _go_ch6(), CONNECT_ONE_SHOT)
	add_child(trig)


func _on_thief_cameo(area: Area2D) -> void:
	var p := area.get_parent()
	while p != null and not p.is_in_group(&"player"):
		p = p.get_parent()
	if p == null or GameState.get_flag(&"ch5_cameo_done", false):
		return
	GameState.set_flag(&"ch5_cameo_done")
	ThiefCameo.spawn(self, Vector2(730, FLOOR_Y - 14))


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

