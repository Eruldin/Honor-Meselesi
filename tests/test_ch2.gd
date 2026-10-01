extends GutTest
## M5 testleri: siber-hirsiz kombo kurali, ucus drone, terminal+lazer
## bulmacasi, dev koruma arka pili, Unit-0 zirh kirma (parry),
## fuze gudumu ve Ch2 akisi.

const CH2_PATH := "res://src/levels/ch2/Ch2.tscn"


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


# --- Siber-hirsiz ---

func test_ninja_dodges_single_hits_combo3_lands() -> void:
	_flat_ground()
	var s := _make_samurai()
	s.global_position = Vector2(300, 240)
	var n := CyberNinja.new()
	n.global_position = Vector2(340, 240)
	add_child_autofree(n)
	await wait_seconds(0.1)
	var x0 := n.global_position.x
	var hp0 := n.health.current
	s.combo_index = 1  # tek vurus gibi
	n.take_damage(DamageInfo.make(1, s))
	assert_eq(n.health.current, hp0, "tek vurus atlatilmali")
	assert_ne(n.global_position.x, x0, "isinlanmali")
	s.combo_index = 3  # kombo zinciri sonu
	n.take_damage(DamageInfo.make(1, s))
	assert_lt(n.health.current, hp0, "3. kombo vurusu gecmeli")


# --- Ucus drone ---

func test_drone_fires_vertical_projectile() -> void:
	var d := DroneEnemy.new()
	d.global_position = Vector2(300, 180)
	add_child_autofree(d)
	d.tuning.drone_fire_interval = 0.05
	var projs: Array = []
	await wait_seconds(0.3)
	for c in get_children():
		if c is Projectile:
			projs.append(c)
	assert_gt(projs.size(), 0, "drone mermi atmali")


# --- Terminal + lazer ---

func test_terminal_requires_drone_and_opens_gate() -> void:
	var term := HackTerminal.new()
	term.gate_id = &"t_gate"
	add_child_autofree(term)
	await wait_seconds(0.05)  # grup kaydi
	var gate := LaserGate.new()
	gate.gate_id = &"t_gate"
	add_child_autofree(gate)
	var s := _make_samurai()
	await wait_seconds(0.1)
	term._check(s.hurtbox)
	term._process(0.5)  # samurai formu hackleyemez
	assert_false(gate.open, "samurai hack yapamaz")
	GameState.unlock_form(&"drone")
	s.equip_form(&"drone")
	await wait_seconds(0.6)
	assert_eq(s.form.id, &"drone")
	term._check(s.hurtbox)
	for i in 30:
		term._process(0.1)
	assert_true(gate.open, "drone hackleyince kapi acilmali")


# --- Dev koruma ---

func test_guardian_blocks_all_but_battery() -> void:
	_flat_ground()
	var s := _make_samurai()
	var g := Guardian.new()
	g.global_position = Vector2(400, 230)
	add_child_autofree(g)
	await wait_seconds(0.1)
	var hp0 := g.health.current
	g.take_damage(DamageInfo.make(2, s))
	assert_eq(g.health.current, hp0, "govde vurusu bloklanmali")
	g.battery.take_damage(DamageInfo.make(2, s))
	assert_lt(g.health.current, hp0, "pil vurusu hasar vermeli")


# --- Unit-0 ---

func test_unit0_armor_blocks_until_parried() -> void:
	var b := Unit0.new()
	add_child_autofree(b)
	b.activate()
	var hp0 := b.health.current
	b.take_damage(DamageInfo.make(3, null))
	assert_eq(b.health.current, hp0, "zirhli: 0 hasar")
	b.on_parried()  # oyuncu yumrugu parry'ledi
	assert_true(b.armor_broken)
	b.take_damage(DamageInfo.make(3, null))
	assert_lt(b.health.current, hp0, "zirh kirik: hasar gecmeli")


func test_unit0_missile_parry_reflects() -> void:
	var m := HomingMissile.new()
	add_child_autofree(m)
	m._vel = Vector2(50, 0)
	m.on_parried()
	assert_eq(m.hitbox.collision_mask, 16, "geriye donen fuze dusmana vurur")


func test_unit0_phase2_punch_keeps_phase_color() -> void:
	var s := _make_samurai()
	s.global_position = Vector2(500, 240)
	var b := Unit0.new()
	b.global_position = Vector2(560, 240)
	add_child_autofree(b)
	b.activate()
	b.on_parried()
	# cani yarinin altina indir → faz 1 (kirmizi modulate)
	b.take_damage(DamageInfo.make(9, null))
	assert_eq(b.phase, 1)
	b.armor_broken = false  # armor timer beklemeyiz
	b.bstate = Unit0.State.PUNCH_TELL
	b._t = 0.01
	await wait_seconds(0.1)
	assert_eq(b.bstate, Unit0.State.PUNCH, "tell sonrasi punch baslar")
	assert_eq(b.sprite.modulate, Color(0.9, 0.5, 0.5),
		"faz 2 punch'i faz-0 rengine dondurmemeli")


func test_unit0_defeated_signal() -> void:
	var b := Unit0.new()
	add_child_autofree(b)
	var dead := [false]
	b.defeated.connect(func() -> void: dead[0] = true)
	b.activate()
	b.on_parried()
	b.take_damage(DamageInfo.make(99, null))
	assert_true(dead[0])


# --- Ch2 akisi ---

func test_ch2_flow_grants_drone_and_boss_to_ch3() -> void:
	var ch2: Node2D = load(CH2_PATH).instantiate()
	ch2.auto_advance = false
	add_child_autofree(ch2)
	await wait_seconds(0.2)
	assert_has(GameState.unlocked_forms, &"drone", "bolum drone formu verir")
	assert_not_null(ch2.boss)
	ch2._on_arena_entered(ch2.samurai.hurtbox)
	await wait_seconds(1.4)   # intro ~1.15s sonra boss aktif olur
	assert_true(ch2.boss.active)
	ch2.boss.armor_broken = true
	ch2.boss.take_damage(DamageInfo.make(99, ch2.samurai))
	assert_has(GameState.unlocked_forms, &"robot", "Unit-0 olumu Robot acar")
	await wait_seconds(0.3)
	for child in ch2.get_children():
		if child is CutscenePlayer and child.playing:
			child.request_skip()
	await wait_seconds(0.3)
	assert_eq(GameState.current_chapter, &"ch3")
