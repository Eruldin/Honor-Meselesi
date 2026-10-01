extends GutTest
## M10 — Bolum 7: Bosluk + perspektif kaymasi + Ouroboros.


func before_each() -> void:
	GameState.reset()


func _frames(n: int) -> void:
	for i in n:
		await get_tree().physics_frame


func test_glitch_creature_moves_and_shoots() -> void:
	var c := GlitchCreature.new()
	var ai := AIInputSource.new()
	c.set_input_source(ai)
	add_child_autofree(c)
	ai.axis(1.0)
	await _frames(20)
	assert_gt(c.global_position.x, 0.0, "yaratik saga ilerler")
	ai.tap(&"attack")
	await _frames(3)
	var bolts := get_tree().get_nodes_in_group(&"")  # bolt sahnede
	var found := false
	for n in get_children():
		if n is GlitchBolt:
			found = true
	assert_true(found, "glitch tanesi firlatilir")


func test_samurai_boss_slash_and_parry() -> void:
	var b := SamuraiBoss.new()
	b.arena_left = -200
	b.arena_right = 200
	b.global_position = Vector2(50, 0)
	var c := GlitchCreature.new()
	c.global_position = Vector2(20, 0)
	add_child_autofree(b)
	add_child_autofree(c)
	b.activate()
	await _frames(40)
	assert_true(b.bstate != SamuraiBoss.BState.SLEEP, "boss uyanir")
	watch_signals(b)
	b.take_damage(DamageInfo.make(999, c))
	await _frames(2)
	assert_signal_emitted(b, "defeated")


func test_ch7_scene_builds_fight() -> void:
	var scene: Node2D = load("res://src/levels/ch7/Ch7.tscn").instantiate()
	scene.auto_advance = false  # intro cutscene'i atla, dogrudan savas
	add_child_autofree(scene)
	await _frames(10)
	assert_not_null(scene.creature, "yaratik oyuncu var")
	assert_not_null(scene.boss, "samurai boss var")
	assert_eq(GameState.current_chapter, &"ch7")


func test_creature_inverted_controls() -> void:
	var c := GlitchCreature.new()
	var ai := AIInputSource.new()
	c.set_input_source(ai)
	add_child_autofree(c)
	c.controls_inverted = true
	ai.axis(1.0)  # saga basiliyor ama ters doner — yaratik sola kayar
	await _frames(20)
	assert_lt(c.global_position.x, 0.0, "ters kontrolde saga tusa sola gider")


func test_ch7_forced_choice_glitches_to_fight() -> void:
	var scene: Node2D = load("res://src/levels/ch7/Ch7.tscn").instantiate()
	scene.auto_advance = false
	add_child_autofree(scene)
	await _frames(10)
	assert_false(scene.boss.active, "boss secim oncesi uyur")
	scene._choice.idx = 0  # imlec SAPKAYI VER ustunde
	await _frames(25)      # >0.35s ustunde durma
	assert_eq(scene._choice.idx, 1, "buton glitchlenir, imlec SAVAS'a kayar")
	scene._choice_decide()
	assert_true(scene.boss.active, "secimden sonra boss aktif")


func test_ch7_meta_assault_inverts_then_restores() -> void:
	var scene: Node2D = load("res://src/levels/ch7/Ch7.tscn").instantiate()
	scene.auto_advance = false
	add_child_autofree(scene)
	await _frames(10)
	scene._choice_decide()  # zorunlu secimi gec — boss aktif
	await _frames(2)
	# Boss'u %55'in altina indir — meta saldiri tetiklenir
	scene.boss.health.take(int(scene.boss.health.max_health * 0.5))
	await _frames(3)
	assert_true(scene._meta_done, "meta saldiri tetiklendi")
	# Telegraph ~0.8s sonra kontrol tersine doner
	await get_tree().create_timer(1.0).timeout
	assert_true(scene.creature.controls_inverted, "kontroller ters dondu")
	# ~5.5s pencere + acilma tween'i: bitince kontrol eski haline doner
	await get_tree().create_timer(6.0).timeout
	assert_false(scene.creature.controls_inverted, "pencere bitince kontrol duzelir")


func test_ch7_heart_spear_steals_last_heart() -> void:
	var scene: Node2D = load("res://src/levels/ch7/Ch7.tscn").instantiate()
	scene.auto_advance = false
	add_child_autofree(scene)
	await _frames(10)
	scene._choice_decide()
	await _frames(2)
	# Boss'u %30'un altina indir — meta mizrak tetiklenir
	scene.boss.health.take(int(scene.boss.health.max_health * 0.75))
	await _frames(3)
	assert_true(scene._spear_done, "kalp mizragi tetiklendi")
	var idx: int = scene.creature.health.current - 1
	if idx < scene._hud._hearts.size():
		assert_false(scene._hud._hearts[idx].visible,
			"son dolu kalp HUD'dan sokuldu")
	var found := false
	for n in scene.get_children():
		if n is HeartSpear:
			found = true
	assert_true(found, "mizrak sahnede")


func test_ch7_epilogue_shows_fifteen_years_card() -> void:
	var scene: Node2D = load("res://src/levels/ch7/Ch7.tscn").instantiate()
	scene.auto_advance = false
	add_child_autofree(scene)
	await _frames(5)
	scene._finish()  # async — kart 1s sonra belirir
	await get_tree().create_timer(1.4, true, false, true).timeout
	var found := false
	for n in scene.get_children():
		if n is CanvasLayer:
			for c in n.get_children():
				if c is Label and c.text == "15 YIL SONRA...":
					found = true
	assert_true(found, "epilog '15 YIL SONRA...' kartini gosterir")


func test_credits_feeds_from_credits_md() -> void:
	var c := Credits.new()
	add_child_autofree(c)
	await get_tree().process_frame
	await get_tree().process_frame
	assert_gt(c._scroll.get_child_count(), 10,
		"CREDITS.md paket satirlari jenerige donustu")
	watch_signals(c)
	c._finish()
	assert_signal_emitted(c, "finished")
