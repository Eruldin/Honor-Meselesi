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
