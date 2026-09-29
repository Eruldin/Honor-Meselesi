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
