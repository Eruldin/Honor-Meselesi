extends GutTest
## M8 — Bolum 5: Kul Diyari.

var tuning: Tuning


func before_each() -> void:
	tuning = load("res://config/tuning.tres")
	GameState.reset()


func _frames(n: int) -> void:
	for i in n:
		await get_tree().physics_frame


func _make_samurai(pos := Vector2.ZERO) -> Samurai:
	var s := Samurai.new()
	s.global_position = pos
	add_child_autofree(s)
	return s


func test_husk_approaches_and_swipes() -> void:
	var sam := _make_samurai(Vector2(0, 0))
	var h := AshHusk.new()
	h.global_position = Vector2(40, 0)
	add_child_autofree(h)
	# yakinlastirana kadar bekle
	for i in 90:
		await get_tree().physics_frame
		if h.hstate == AshHusk.HState.SWIPE:
			break
	assert_eq(h.hstate, AshHusk.HState.SWIPE, "husk menzilde savrulus yapar")
	assert_not_null(h._swipe_hitbox)


func test_bat_flies_and_dives() -> void:
	var sam := _make_samurai(Vector2(0, 0))
	var b := AshBat.new()
	b.global_position = Vector2(30, -40)
	add_child_autofree(b)
	await _frames(30)
	assert_true(absf(b.velocity.length()) > 0.1, "bat hareket eder")


func test_bat_dive_ends_without_wall_hit() -> void:
	var sam := _make_samurai(Vector2(30, 10))
	var b := AshBat.new()
	b.global_position = Vector2(0, 0)
	add_child_autofree(b)
	for i in 90:
		await get_tree().physics_frame
		if b._diving:
			break
	assert_true(b._diving, "bat menzilde dalisa girer")
	# Oyuncuyu cok uzaga al — dalis duvara degil, sureye vurur.
	sam.global_position = Vector2(5000, 0)
	await _frames(90)  # 1.5s > 1.2s dalis suresi
	assert_false(b._diving, "dalis duvarsiz da 1.2s sonra biter")


func test_turret_stops_firing_when_dead() -> void:
	var t := Turret.new()
	t.fire_interval = 0.1
	add_child_autofree(t)
	await _frames(4)
	t.take_damage(DamageInfo.make(99, null))
	var before := _projectile_count()
	await _frames(15)  # ates araliginin cok ustu
	assert_eq(_projectile_count(), before, "olu kule mermi atmaz")


func _projectile_count() -> int:
	var n := 0
	for c in get_children():
		if c is Projectile:
			n += 1
	return n


func test_guardian_phase_and_geyser() -> void:
	var g := AshGuardian.new()
	g.floor_y = 0.0
	g.global_position = Vector2(0, 0)
	var sam := _make_samurai(Vector2(20, 0))
	add_child_autofree(g)
	g.activate()
	await _frames(10)
	# F2'ye dusur -> geyser secenegi acilir
	g.take_damage(DamageInfo.make(g.health.max_health / 2 + 1, sam))
	await _frames(5)
	assert_eq(g.phase, 1, "yari candan sonra faz 2")
	for i in 300:
		await get_tree().physics_frame
		if g.bstate == AshGuardian.GState.GEYSER or g.bstate == AshGuardian.GState.TELL:
			break
	assert_true(g.bstate in [AshGuardian.GState.TELL, AshGuardian.GState.GEYSER,
		AshGuardian.GState.SLAM_RISE, AshGuardian.GState.GAP, AshGuardian.GState.APPROACH])


func test_guardian_parry_freezes_behavior() -> void:
	var g := AshGuardian.new()
	g.floor_y = 0.0
	var sam := _make_samurai(Vector2(20, 0))
	add_child_autofree(g)
	g.activate()
	await _frames(4)
	g.on_parried()
	assert_true(g.is_staggered(), "parry sersemletmeye girer")
	var t0: float = g._t
	await _frames(12)
	assert_eq(g._t, t0, "parry penceresinde durum saati donar")


func test_guardian_defeat_fires_signal() -> void:
	var g := AshGuardian.new()
	var sam := _make_samurai()
	add_child_autofree(g)
	g.activate()
	watch_signals(g)
	g.take_damage(DamageInfo.make(999, sam))
	await _frames(2)
	assert_signal_emitted(g, "defeated")


func test_ch5_scene_builds() -> void:
	var scene: Node2D = load("res://src/levels/ch5/Ch5.tscn").instantiate()
	scene.auto_advance = false
	add_child_autofree(scene)
	await _frames(10)
	assert_not_null(scene.samurai)
	assert_not_null(scene.boss)
	assert_eq(GameState.current_chapter, &"ch5")


func test_ash_knight_mirrors_player_attacks() -> void:
	var sam := _make_samurai(Vector2(0, 0))
	var k := AshKnight.new()
	k.global_position = Vector2(22, 0)
	add_child_autofree(k)
	# Dusman katmanlari: govde 64, hurtbox 16 (player 8 maskesiyle vurulur)
	assert_eq(k.collision_layer, 64)
	assert_eq(k.hurtbox.collision_layer, 16)
	assert_eq(k.attack_hitbox.collision_mask, 4,
		"saldiri hitbox'i oyuncu hurtbox'ini hedefler")
	var saw_attack := false
	for i in 120:
		await get_tree().physics_frame
		if k.sm.current_name in [Samurai.S_ATTACK, Samurai.S_AIR_ATTACK]:
			saw_attack = true
			break
	assert_true(saw_attack, "ayna sovalye menzilde saldirir")


func test_ash_knight_idles_during_cutscene() -> void:
	# Regresyon: hedef kesik-sahnedeyken ayna hala kovalayip savruluyordu —
	# hasar yok ama sinema sirasinda vucut hareket eder.
	var sam := _make_samurai(Vector2(0, 0))
	var k := AshKnight.new()
	k.global_position = Vector2(22, 0)
	add_child_autofree(k)
	sam.sm.change_to(Samurai.S_CUTSCENE, true)
	for i in 90:
		await get_tree().physics_frame
		if k.sm.current_name in [Samurai.S_ATTACK, Samurai.S_AIR_ATTACK,
				Samurai.S_DOWN_ATTACK, Samurai.S_UP_ATTACK]:
			break
	assert_false(k.sm.current_name in [Samurai.S_ATTACK, Samurai.S_AIR_ATTACK,
			Samurai.S_DOWN_ATTACK, Samurai.S_UP_ATTACK],
		"cutscene'deki hedefe saldiri yok")


func test_ash_knight_takes_player_damage_and_dies() -> void:
	var k := AshKnight.new()
	k.global_position = Vector2(0, 0)
	add_child_autofree(k)
	await _frames(5)
	watch_signals(EventBus)
	k.take_damage(DamageInfo.make(999, null))
	await _frames(2)
	assert_eq(k.sm.current_name, Samurai.S_DEAD, "kul sovalye olur")
	assert_signal_emitted(EventBus, "actor_died")
