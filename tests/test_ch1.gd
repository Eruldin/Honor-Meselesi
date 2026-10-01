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


func test_staggered_villager_contact_disarmed() -> void:
	_flat_ground()
	var s := _make_samurai()
	s.global_position = Vector2(300, 240)
	var v := Villager.new()
	v.global_position = Vector2(400, 240)
	add_child_autofree(v)
	await wait_seconds(0.2)
	assert_true(v.contact_hitbox.monitoring, "temas hitbox'i silahli")
	v.on_parried()
	await wait_seconds(0.2)
	assert_true(v.is_staggered(), "parry'de sersemler")
	assert_false(v.contact_hitbox.monitoring,
		"sersemleme temas hasarini kapatir")
	await wait_seconds(1.4)
	assert_true(v.contact_hitbox.monitoring,
		"sersemleme bitince temas geri kurulur")


func test_dead_player_ignores_further_hits() -> void:
	# Regresyon: olu oyuncuya carpan ikinci bir vurus damage_dealt +
	# actor_died'i tekrar emit ediyordu (cift olum sirasi riski).
	_flat_ground()
	var s := _make_samurai()
	s.global_position = Vector2(300, 240)
	await wait_seconds(0.1)
	var deaths := [0]
	var tally := func(_a) -> void: deaths[0] += 1
	EventBus.actor_died.connect(tally)
	s.take_damage(DamageInfo.make(99, null, Vector2.ZERO, false, true))
	assert_false(s.health.is_alive(), "vurus oldurmeli")
	s.take_damage(DamageInfo.make(5, null, Vector2.ZERO, false, true))
	s.take_damage(DamageInfo.make(5, null, Vector2.ZERO, false, true))
	await wait_seconds(0.1)
	assert_eq(deaths[0], 1, "actor_died tek kez emit edilmeli")
	EventBus.actor_died.disconnect(tally)


func test_spike_rehits_after_exit() -> void:
	# Regresyon: hitbox tek kez aktive ediliyordu — oyuncu yalnizca bir
	# kez hasar aliyor, sonraki temaslar sonsuza dek zararsiz kaliyordu.
	_flat_ground()
	var s := _make_samurai()
	s.global_position = Vector2(300, 240)
	var sp := Spike.new()
	sp.global_position = Vector2(300, 252)
	add_child_autofree(sp)
	var hp0 := s.health.current
	await wait_seconds(0.2)  # temas -> ilk vurus
	assert_lt(s.health.current, hp0, "ilk temas vurmali")
	s.global_position = Vector2(600, 240)  # ayril -> hitbox yeniden kurulur
	await wait_seconds(1.0)  # i-frame suresi gecsin
	s.global_position = Vector2(300, 240)  # geri don -> yeniden temas
	await wait_seconds(0.3)
	assert_lt(s.health.current, hp0 - 1, "ikinci temas tekrar vurmali")


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


func test_guard_blocked_hit_shows_shield_pictogram() -> void:
	_flat_ground()
	var s := _make_samurai()
	s.global_position = Vector2(200, 240)
	var g := Guard.new()
	g.global_position = Vector2(340, 240)
	add_child_autofree(g)
	await wait_seconds(0.1)
	g.take_damage(DamageInfo.make(1, s))
	var found := false
	for c in g.get_children():
		if c is Pictogram:
			found = true
	assert_true(found, "bloklanan ilk vurus parry ipucu gosterir")


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


func test_loot_chest_opens_on_hitbox_hit() -> void:
	# Regresyon: hurtbox collision_layer set edilmiyordu — sandik
	# vurusla hic acilmiyordu (layer 1 vs hitbox mask 16).
	_flat_ground()
	var s := _make_samurai()
	s.global_position = Vector2(300, 240)
	s.health.take(2)
	var c := LootChest.new()
	c.chest_id = &"chest_test_ch1"
	c.global_position = Vector2(300, 240)
	add_child_autofree(c)
	await wait_seconds(0.1)
	var hb := Hitbox.new()
	hb.collision_layer = 8
	hb.collision_mask = 16
	var col := CollisionShape2D.new()
	var r := RectangleShape2D.new()
	r.size = Vector2(20, 20)
	col.shape = r
	hb.add_child(col)
	hb.global_position = c.global_position
	add_child_autofree(hb)
	hb.activate(DamageInfo.make(1, s))
	await wait_seconds(0.15)
	assert_true(GameState.get_flag(&"chest_chest_test_ch1"),
		"vurus sandigi acar")
	assert_eq(s.health.current, s.health.max_health, "tam iyilestirir")


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


func test_reflected_egg_explodes_on_fuse_end() -> void:
	# Regresyon: yansiyan yumurta fuse'i duruyordu — patronu iskalayan
	# yumurta duvara tirmanip sonsuza ucmadan patlamaliydi.
	_flat_ground()
	var egg := ExplodingEgg.new()
	egg.global_position = Vector2(500, 200)
	add_child_autofree(egg)
	var s := _make_samurai()
	egg.take_damage(DamageInfo.make(1, s))
	assert_eq(egg.state, ExplodingEgg.State.REFLECTED)
	egg._fuse = 0.05
	await wait_seconds(0.3)
	assert_false(is_instance_valid(egg), "fitil bitince yansiyan yumurta da patlar")


func test_ch1_cleared_exit_portal_completes_chapter() -> void:
	# Regresyon: boss-oldu bayragi yazili ama gecis yarida kesilmis
	# (quit/crash/olum) — reload'da boss dogmaz; arena cikisindaki
	# portal tetigi bolumu tamamlar (soft-lock onlemi).
	GameState.set_flag(&"ch1_boss_dead")
	var scene: Node2D = load("res://src/levels/ch1/Ch1.tscn").instantiate()
	scene.auto_advance = false
	add_child_autofree(scene)
	await get_tree().physics_frame
	await get_tree().physics_frame
	assert_null(scene.boss, "olu boss dogmaz")
	var trig: Area2D = null
	var portal: Node2D = null
	for c in scene.get_children():
		if c is Area2D and c.collision_mask == 4 \
				and c.global_position.x > 5500.0:
			trig = c
		elif c is Node2D and c.get_class() == "Node2D" \
				and c.global_position.x > 5500.0:
			portal = c
	assert_not_null(trig, "cikis portal tetigi var")
	assert_not_null(portal, "cikis portal gorseli var")
	# Portal sahne dekorunun (z<=6) ustunde cizilir — karanlik sahnede
	# oyuncunun kacis kapisini gorebilmesi gorunurluk garantisi.
	assert_gt(portal.z_index, 0, "portal dekor katmaninin ustunde")
	var stub := Area2D.new()
	add_child_autofree(stub)
	trig.area_entered.emit(stub)
	assert_true(GameState.get_flag(&"ch1_done", false),
		"portal gecisi bolumu tamamlar")


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


func test_ch1_eagles_spawn_with_real_sprite() -> void:
	var ch1: Node2D = load(CH1_PATH).instantiate()
	ch1.auto_advance = false
	add_child_autofree(ch1)
	await wait_seconds(0.2)
	var eagles := 0
	for n in ch1.find_children("*", "Eagle", true, false):
		eagles += 1
		if AssetLoader.has_frames(&"enemy/eagle/idle"):
			assert_true(n.using_real_sprite, "kartal gercek sprite kullanir")
	assert_eq(eagles, 2, "iki dalgic kartal yerlesir")


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


func test_sleeping_cave_bat_wakes_on_approach() -> void:
	var sam := _make_samurai()
	sam.global_position = Vector2(600, 0)
	var bat := CaveBat.new()
	bat.sleeping_start = true
	bat.global_position = Vector2(0, 0)
	add_child_autofree(bat)
	await wait_seconds(0.2)
	assert_true(bat._asleep, "uzak oyuncuda uyku surer")
	assert_lt(bat.velocity.length(), 0.1, "uyuyan yarasa kipirdamaz")
	if AssetLoader.has_frames(&"enemy/bat/sleep"):
		assert_eq(bat.anims.animation, &"sleep", "uyku animi oynar")
	sam.global_position = Vector2(80, 20)
	await wait_seconds(0.5)
	assert_false(bat._asleep, "yaklasinca uyanir")
	if AssetLoader.has_frames(&"enemy/bat/sleep"):
		assert_ne(bat.anims.animation, &"sleep", "uyku animi birakilir")


func test_imp_hops_while_chasing() -> void:
	_flat_ground()
	var s := _make_samurai()
	s.global_position = Vector2(260, 240)
	var imp := ImpRed.new()
	imp.global_position = Vector2(350, 240)
	add_child_autofree(imp)
	var hopped := false
	for i in 60:
		await get_tree().physics_frame
		if imp.velocity.y < -40.0:
			hopped = true
			break
	assert_true(hopped, "fark eden imp arada hoplar")


func test_demon_axe_leap_attack() -> void:
	_flat_ground()
	var s := _make_samurai()
	s.global_position = Vector2(240, 240)
	var d := DemonAxe.new()
	d.global_position = Vector2(350, 240)
	add_child_autofree(d)
	var leapt := false
	for i in 90:
		await get_tree().physics_frame
		if d.velocity.y < -40.0:
			leapt = true
			break
	assert_true(leapt, "orta menzilde atilim sicrayisi yapar")


func test_crow_dive_uses_jump_anim() -> void:
	if not AssetLoader.has_frames(&"enemy/crow/jump"):
		pending("crow/jump yok (CI) — atlaniyor")
		return
	var sam := _make_samurai()
	sam.global_position = Vector2(40, -20)
	var crow := Crow.new()
	crow.global_position = Vector2(0, -50)
	add_child_autofree(crow)
	await wait_seconds(0.15)
	assert_true(crow.anims.sprite_frames.has_animation(&"jump"),
		"bankada jump animi var")
	sam.global_position = Vector2(60, -30)
	await wait_seconds(0.3)
	assert_eq(crow.anims.animation, &"jump", "dalista jump pozu oynar")


func test_death_mark_uses_last_ground_pos() -> void:
	# Regresyon: bosluk dususu olumunde golge marki olicen pozisyona
	# (havada/boslukta) yaziliyordu — erisilmez golge; artik son zemin.
	_flat_ground()
	var s := _make_samurai()
	s.global_position = Vector2(400, 240)
	await wait_seconds(0.2)  # zemine indi
	assert_true(s.is_on_floor(), "zemin temasi")
	var floor_x: float = s.global_position.x
	# Havada olunce mark son zemin olmali — global_position'i elle bosluga tasi.
	s.velocity.y = -300.0
	await get_tree().physics_frame
	await get_tree().physics_frame
	await get_tree().physics_frame
	await get_tree().physics_frame
	assert_false(s.is_on_floor(), "havada")
	GameState.mark_death(
		s.last_ground_pos if s.last_ground_pos != Vector2.ZERO
		else s.global_position)
	var mark: Vector2 = GameState.get_flag(&"death_mark_pos")
	assert_almost_eq(mark.x, floor_x, 8.0, "mark son zemin pozisyonunda")
	assert_lt(mark.y, 300.0, "mark boslukta degil")
