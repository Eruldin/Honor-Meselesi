extends GutTest
## M9 — Bolum 6: Parcalanmis Bellek.

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


func test_flicker_platform_fades_and_returns() -> void:
	var f := FlickerPlatform.new()
	f.on_time = 0.5
	f.off_time = 0.3
	add_child_autofree(f)
	assert_eq(f.collision_layer, 1, "baslangicta saglam")
	await get_tree().create_timer(0.7).timeout
	assert_eq(f.collision_layer, 0, "unutulunca collision kapanir")
	await get_tree().create_timer(0.4).timeout
	assert_eq(f.collision_layer, 1, "geri gelir")


func test_amalgam_phase_and_attacks() -> void:
	var g := GlitchAmalgam.new()
	g.floor_y = 0.0
	g.global_position = Vector2(0, 0)
	var sam := _make_samurai(Vector2(30, 0))
	add_child_autofree(g)
	g.activate()
	await _frames(10)
	g.take_damage(DamageInfo.make(g.health.max_health / 2 + 1, sam))
	await _frames(5)
	assert_eq(g.phase, 1, "yari candan sonra faz 2")


func test_amalgam_defeat_signal() -> void:
	var g := GlitchAmalgam.new()
	var sam := _make_samurai()
	add_child_autofree(g)
	g.activate()
	watch_signals(g)
	g.take_damage(DamageInfo.make(999, sam))
	await _frames(2)
	assert_signal_emitted(g, "defeated")


func test_ch6_scene_builds() -> void:
	var scene: Node2D = load("res://src/levels/ch6/Ch6.tscn").instantiate()
	scene.auto_advance = false
	add_child_autofree(scene)
	await _frames(10)
	assert_not_null(scene.samurai)
	assert_not_null(scene.boss)
	assert_eq(GameState.current_chapter, &"ch6")


func test_ch6_cleared_exit_portal_completes_chapter() -> void:
	# Regresyon: boss-oldu bayragi yazili ama gecis yarida kesilmis
	# (quit/crash/olum) — reload'da boss dogmaz; arena cikisindaki
	# portal tetigi bolumu tamamlar (soft-lock onlemi).
	GameState.set_flag(&"ch6_boss_dead")
	var scene: Node2D = load("res://src/levels/ch6/Ch6.tscn").instantiate()
	scene.auto_advance = false
	add_child_autofree(scene)
	await _frames(10)
	assert_null(scene.boss, "olu boss dogmaz")
	var trig: Area2D = null
	for c in scene.get_children():
		if c is Area2D and c.collision_mask == 4 \
				and c.global_position.x > 1500.0:
			trig = c
	assert_not_null(trig, "cikis portal tetigi var")
	var stub := Area2D.new()
	add_child_autofree(stub)
	trig.area_entered.emit(stub)
	assert_true(GameState.get_flag(&"ch6_done", false),
		"portal gecisi bolumu tamamlar")


func test_boss_bar_hidden_on_defeat() -> void:
	# Regresyon: boss olurken _boss_root acik kaliyordu — bos bar
	# temizlenen arenada ekrana yapismis duruyordu.
	var scene: Node2D = load("res://src/levels/ch6/Ch6.tscn").instantiate()
	scene.auto_advance = false
	add_child_autofree(scene)
	await _frames(5)
	scene._boss_root.visible = true   # savas ortasi taklidi
	scene._on_boss_defeated()
	assert_false(scene._boss_root.visible,
		"boss olumunde boss bar gizlenir")
