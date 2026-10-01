extends GutTest
## M4 testleri: Bolum 1 dusmanlari (koylu/muhafiz/sovalye), dinlenme
## noktasi + kayit, BossBase faz sistemi, Lord Cluck + yumurta yansitma,
## Ch1 arena tetigi ve boss->Tavuk formu akisi.

const CH1_PATH := "res://src/levels/ch1/Ch1.tscn"


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


# --- Dusmanlar ---

func test_villager_approaches_player() -> void:
	_flat_ground()
	var s := _make_samurai()
	s.global_position = Vector2(300, 240)
	var v := Villager.new()
	v.global_position = Vector2(400, 240)
	add_child_autofree(v)
	await wait_seconds(0.8)
	assert_lt(v.global_position.x, 400.0, "koylu oyuncuya yaklasmali")


func test_guard_blocks_frontal_damage() -> void:
	_flat_ground()
	var s := _make_samurai()
	s.global_position = Vector2(300, 240)
	var g := Guard.new()
	g.global_position = Vector2(340, 240)
	add_child_autofree(g)
	# Oyuncu uzakta: guard APPROACH'ta kalir (telegraph'a gecmez)
	s.global_position = Vector2(200, 240)
	await wait_seconds(0.1)
	var hp_before := g.health.current
	# Onden vurus: guard sola bakiyor, kaynak solda
	var soul_before: int = GameState.soul
	g.take_damage(DamageInfo.make(1, s))
	assert_eq(g.health.current, hp_before, "onden vurus bloklanmali")
	assert_eq(GameState.soul, soul_before, "bloklanan vurus ruh vermemeli")
	# Arkadan: kaynagi saga tasiyinca hasar gecmeli
	s.global_position = Vector2(480, 240)
	g.gstate = Guard.GState.APPROACH
	g.take_damage(DamageInfo.make(1, s))
	assert_lt(g.health.current, hp_before, "arkadan vurus hasar vermeli")


func test_heavy_knight_drops_sovalye_form() -> void:
	_flat_ground()
	var s := _make_samurai()
	s.global_position = Vector2(300, 240)
	var k := HeavyKnight.new()
	k.grants_form = &"sovalye"
	k.global_position = Vector2(340, 240)
	add_child_autofree(k)
	await wait_seconds(0.1)
	k.health.take(6)
	await wait_seconds(0.1)
	assert_has(GameState.unlocked_forms, &"sovalye", "form acilmali")
	await wait_seconds(0.7)  # transform suresi
	assert_eq(s.form.id, &"sovalye", "otomatik takilmali")


func test_sovalye_form_expires_back_to_samurai() -> void:
	var s := _make_samurai()
	GameState.unlock_form(&"sovalye")
	s.equip_form(&"sovalye")
	await wait_seconds(0.6)
	assert_eq(s.form.id, &"sovalye")
	s.form_time_left = 0.05
	await wait_seconds(0.8)
	assert_eq(s.form.id, &"samurai", "sure dolunca samuraya donmeli")
	assert_false(GameState.unlocked_forms.has(&"sovalye"), "gecici form kilit listesinden silinmeli")


# --- Dinlenme noktasi ---

func test_rest_point_saves_and_heals() -> void:
	_flat_ground()
	var s := _make_samurai()
	s.global_position = Vector2(300, 240)
	s.health.take(2)
	GameState.soul = 3
	var r := RestPoint.new()
	r.checkpoint_id = &"cp_test_ch1"
	r.global_position = Vector2(300, 240)
	add_child_autofree(r)
	await wait_seconds(0.15)
	assert_eq(GameState.checkpoint_id, &"cp_test_ch1")
	assert_eq(s.health.current, s.health.max_health, "tam can")
	assert_eq(GameState.soul, GameState.SOUL_MAX, "dinlenme ruhu da doldurur")
	assert_true(SaveSystem.has_save(), "kayit dosyasi yazilmali")
	assert_true(GameState.get_flag(&"respawn_pos") is Vector2)


func test_checkpoint_respawn_grants_spawn_grace() -> void:
	# Olum respawn'i checkpoint'ten dogar — kisa dokunulmazlik verilir
	# (spawn uzerinde duran dusman ani hasar veremesin).
	GameState.set_flag(&"respawn_ch", &"ch1")
	GameState.set_flag(&"respawn_pos", Vector2(500, 200))
	var ch1: Node2D = load(CH1_PATH).instantiate()
	ch1.auto_advance = false
	add_child_autofree(ch1)
	await wait_seconds(0.15)
	assert_gt(ch1.samurai.invuln_timer, 0.0,
		"checkpoint respawn'inda spawn grace")
	assert_almost_eq(ch1.samurai.global_position.x, 500.0, 0.5,
		"checkpoint x pozisyonunda dogar")


# --- BossBase / Lord Cluck ---

func test_boss_phase_threshold() -> void:
	var b := LordCluck.new()
	add_child_autofree(b)
	var phases: Array[int] = []
	b.phase_changed.connect(func(p: int) -> void: phases.append(p))
	# Aktif degilken hasar almaz
	b.take_damage(DamageInfo.make(5, null))
	assert_eq(b.health.current, b.health.max_health)
	b.activate()
	b.take_damage(DamageInfo.make(8, null))  # 14 -> 6 (%43 < %50)
	assert_eq(phases, [1], "faz 1'e gecmali")


func test_boss_defeated_signal() -> void:
	var b := LordCluck.new()
	add_child_autofree(b)
	var dead := [false]
	b.defeated.connect(func() -> void: dead[0] = true)
	b.activate()
	b.take_damage(DamageInfo.make(99, null))
	assert_true(dead[0])


func test_egg_reflect_flies_to_boss() -> void:
	_flat_ground()
	var b := LordCluck.new()
	b.global_position = Vector2(400, 240)
	add_child_autofree(b)
	var egg := ExplodingEgg.new()
	egg.boss = b
	egg.global_position = Vector2(500, 200)
	add_child_autofree(egg)
	var s := _make_samurai()
	egg.take_damage(DamageInfo.make(1, s))
	assert_eq(egg.state, ExplodingEgg.State.REFLECTED)
	assert_eq(egg.hitbox.collision_mask, 16, "yansiyan yumurta dusman katmanina vurur")
	await wait_seconds(0.5)
	assert_lt(egg.global_position.x, 500.0, "patrona (sola) ucmali")


func test_egg_explodes_on_fuse() -> void:
	_flat_ground()
	var egg := ExplodingEgg.new()
	egg.global_position = Vector2(300, 200)
	add_child_autofree(egg)
	await wait_seconds(0.6)
	assert_eq(egg.state, ExplodingEgg.State.FUSED, "yere inince fuse baslar")
	egg._fuse = 0.05
	await wait_seconds(0.4)
	assert_false(is_instance_valid(egg), "patlayip yok olmali")


# --- Ch1 akisi ---

func test_ch1_scene_builds_and_arena_triggers() -> void:
	var ch1: Node2D = load(CH1_PATH).instantiate()
	ch1.auto_advance = false
	add_child_autofree(ch1)
	await wait_seconds(0.2)
	assert_not_null(ch1.boss)
	assert_false(ch1.boss.active)
	# Tetigi elle cagir (oyuncu hurtbox'i ile)
	ch1._on_arena_entered(ch1.samurai.hurtbox)
	await wait_seconds(1.4)   # intro ~1.15s sonra boss aktif olur
	assert_true(ch1.boss.active, "arena girince boss aktif")
	assert_true(ch1._boss_started)


func test_ch1_boss_death_flows_to_ch2() -> void:
	var ch1: Node2D = load(CH1_PATH).instantiate()
	ch1.auto_advance = false
	add_child_autofree(ch1)
	await wait_seconds(0.2)
	var spy := [""]
	EventBus.scene_change_requested.connect(func(p: String) -> void: spy[0] = p)
	ch1._on_arena_entered(ch1.samurai.hurtbox)
	ch1.boss.health.take(99)
	assert_true(GameState.unlocked_forms.has(&"tavuk"), "boss olumu Tavuk formu acmali")
	# cutscene oynar — skip ile sona atla
	await wait_seconds(0.3)
	for child in ch1.get_children():
		if child is CutscenePlayer and child.playing:
			child.request_skip()
	await wait_seconds(0.3)
	assert_eq(GameState.current_chapter, &"ch2")
	assert_eq(spy[0], "", "auto_advance=false iken sahne degismez")
