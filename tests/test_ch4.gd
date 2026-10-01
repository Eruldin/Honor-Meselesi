extends GutTest
## M7 testleri: mantar bolunmesi, kaplumbaga->kabuk, kirilabilir blok,
## Tiran yercekimi cevirme + piksel yagmuru, Piksel Sicramasi kalici
## yetenegi (cift ziplama), Ch4 akisi.

const CH4_PATH := "res://src/levels/ch4/Ch4.tscn"


func after_each() -> void:
	GameState.reset()
	SaveSystem.wipe()


func _make_samurai() -> Samurai:
	var s := Samurai.new()
	add_child_autofree(s)
	return s


func _flat_ground() -> StaticBody2D:
	var g := StaticBody2D.new()
	g.collision_layer = 1
	var col := CollisionShape2D.new()
	var r := RectangleShape2D.new()
	r.size = Vector2(2000, 20)
	col.shape = r
	g.add_child(col)
	g.position = Vector2(500, 260)
	add_child_autofree(g)
	return g


# --- Mantar ---

func test_mushroom_splits_into_minis() -> void:
	_flat_ground()
	var m := SplitMushroom.new()
	m.global_position = Vector2(300, 240)
	add_child_autofree(m)
	await wait_seconds(0.1)
	m.take_damage(DamageInfo.make(99, null))
	await wait_seconds(0.2)
	var minis := 0
	for c in get_children():
		if c is SplitMushroom and c.mini:
			minis += 1
	assert_eq(minis, 2, "kesilen mantar iki mini mantar firlatmali")


# --- Kaplumbaga ---

func test_turtle_becomes_bouncing_shell() -> void:
	_flat_ground()
	var t := Turtle.new()
	t.global_position = Vector2(300, 240)
	add_child_autofree(t)
	await wait_seconds(0.1)
	t.take_damage(DamageInfo.make(1, null))
	assert_true(t.shelled, "ilk vurus kabuga donusturur")
	await wait_seconds(0.2)
	var found := false
	for c in get_children():
		if c is Turtle.TurtleShell:
			found = true
	assert_true(found, "sekme yapan kabuk sahnede olmali")


# --- Kirilabilir blok ---

func test_breakable_block_breaks_on_hit() -> void:
	var b := BreakableBlock.new()
	b.global_position = Vector2(300, 200)
	add_child_autofree(b)
	b.take_damage(DamageInfo.make(1, null))
	await wait_seconds(0.3)
	assert_false(is_instance_valid(b), "blok vurulunca kirilmali")


# --- Tiran: yercekimi cevirme ---

func test_tyrant_gravity_flip_and_restore() -> void:
	_flat_ground()
	var s := _make_samurai()
	s.global_position = Vector2(300, 240)
	var b := RedTyrant.new()
	b.global_position = Vector2(400, 240)
	add_child_autofree(b)
	b.activate()
	await wait_seconds(0.2)  # _player cozumlesin
	b._start_flip()
	assert_true(s.gravity_flipped, "yercekimi terse cevrilmeli")
	assert_eq(s.up_direction, Vector2.DOWN)
	b._flip_timer = 0.05
	await wait_seconds(0.2)
	assert_false(s.gravity_flipped, "sure bitince yercekimi normale doner")
	assert_eq(s.up_direction, Vector2.UP)


func test_tyrant_pixel_rain_phase2() -> void:
	var b := RedTyrant.new()
	add_child_autofree(b)
	b.activate()
	b.take_damage(DamageInfo.make(10, null))  # 18 -> 8 (%44) faz 2
	assert_eq(b.phase, 1)
	# Faz 2'de saldiri secimine rain dahil
	var seen_rain := false
	b._atk_idx = 2  # 2 % 3 == 2 -> rain
	b._choose()
	assert_true(b._rain.active or b.bstate == RedTyrant.State.RAIN,
		"faz 2'de piksel yagmuru secilebilmeli")


# --- Piksel Sicramasi (kalici yetenek) ---

func test_pixel_jump_flag_grants_air_jump() -> void:
	var s := _make_samurai()
	await wait_seconds(0.1)
	s.coyote_timer = 0.0
	s.jumps_used = 0
	s.jump_buffer_timer = 0.1
	assert_false(s.try_jump(), "flag yokken havada ekstra ziplama yok")
	GameState.set_flag(&"piksel_sicramasi", true)
	s.jumps_used = 0
	s.jump_buffer_timer = 0.1
	assert_true(s.try_jump(), "flag ile 1 hava ziplamasi kazanilir")


func test_tyrant_death_grants_pixel_jump() -> void:
	_flat_ground()
	var s := _make_samurai()
	s.global_position = Vector2(300, 240)
	s.set_gravity_flipped(true)
	var b := RedTyrant.new()
	b.global_position = Vector2(400, 240)
	add_child_autofree(b)
	b.activate()
	await wait_seconds(0.2)
	b.health.take(99)
	assert_true(bool(GameState.get_flag(&"piksel_sicramasi")),
		"Tiran olumu Piksel Sicramasi verir")
	assert_false(s.gravity_flipped, "olumde yercekimi normale doner")


# --- Ch4 akisi ---

func test_ch4_flow_boss_to_ch5() -> void:
	var ch4: Node2D = load(CH4_PATH).instantiate()
	ch4.auto_advance = false
	add_child_autofree(ch4)
	await wait_seconds(0.2)
	ch4._on_arena_entered(ch4.samurai.hurtbox)
	await wait_seconds(1.4)   # intro ~1.15s sonra boss aktif olur
	assert_true(ch4.boss.active)
	ch4.boss.health.take(99)
	assert_true(bool(GameState.get_flag(&"piksel_sicramasi")))
	assert_true(ch4._gameover.visible, "GAME OVER bandi gosterilmeli")
	await wait_seconds(2.0)  # GAME OVER 1.6s + cutscene baslangici
	for child in ch4.get_children():
		if child is CutscenePlayer and child.playing:
			child.request_skip()
	await wait_seconds(0.3)
	assert_eq(GameState.current_chapter, &"ch5")


func test_fire_flower_pops_and_spits() -> void:
	var ff := FireFlower.new()
	ff.global_position = Vector2(100, 200)
	add_child_autofree(ff)
	var t: Tuning = load("res://config/tuning.tres")
	# pop: interval*0.6 + disarida 0.5s sonra _spit
	await wait_seconds(t.flower_interval * 0.6 + 0.7)
	var found := false
	for c in ff.get_parent().get_children():
		if c is Projectile:
			found = true
	assert_true(found, "cicek disari cikip ates topu tukurur")
	if AssetLoader.has_frames(&"enemy/flower/attack"):
		assert_not_null(ff._asp, "attack animi sprite'i kurulur")


func test_tyrant_cues_tint_visible() -> void:
	var b := RedTyrant.new()
	b.global_position = Vector2(400, 240)
	add_child_autofree(b)
	# CI'da gercek sheet'ler yok — cue hangi gorsel yuzeye gidiyorsa orada dogrula
	var vis: CanvasItem = b.anims if b.anims != null else b.sprite
	b.on_phase_changed(1)
	assert_lt(vis.modulate.b, 0.2, "faz 2 gorunur gorsel de turuncuya donmeli")
	var s := _make_samurai()
	s.global_position = Vector2(300, 240)
	b.activate()
	await wait_seconds(0.2)
	b._atk_idx = 0
	b._choose()
	b._physics_process(0.016)
	b._physics_process(0.016)
	assert_eq(b.bstate, RedTyrant.State.TELL)
	assert_gt(vis.modulate.r, 1.0,
		"sarartma telegraph gorunur gorselde de gorunmeli")
