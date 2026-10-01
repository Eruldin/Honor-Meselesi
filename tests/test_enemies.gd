extends GutTest
## Bolum sahneleri disinda dogrudan testi olmayan dusman siniflari:
## sozlesme denetimi (canli dogma, grup, varyasyon anahtari, cagri).


func _frames(n: int) -> void:
	for i in n:
		await get_tree().physics_frame


func test_summonling_joins_group_alive() -> void:
	var s := Summonling.new()
	add_child_autofree(s)
	assert_true(s.is_in_group(&"summonling"),
		"cagrilanlar Executioner cap sayimina girmeli")
	assert_true(s.health.is_alive())


func test_executioner_summons_below_half_hp() -> void:
	var sam := Samurai.new()
	add_child_autofree(sam)
	await _frames(2)  # player grubuna katilsin
	var e := Executioner.new()
	add_child_autofree(e)
	e.global_position = Vector2.ZERO
	sam.global_position = Vector2(60, 0)
	e.health.take(7)  # 12 -> 5 (%50 alti)
	e._summon_t = 0.01
	await _frames(3)
	await get_tree().create_timer(0.7, false).timeout  # _summon 0.55s await
	await _frames(2)
	assert_gt(get_tree().get_nodes_in_group(&"summonling").size(), 0,
		"yarim can altinda oyuncu yakinsa golemcik cagirir")


func test_soldier_variant_keys() -> void:
	var s2 := Soldier.new()
	s2.variant = 2
	add_child_autofree(s2)
	assert_eq(s2.asset_key, &"soldier2", "varyasyon 2 -> soldier2 bankasi")
	var s9 := Soldier.new()
	s9.variant = 9  # clamp: 4'u asamaz
	add_child_autofree(s9)
	assert_eq(s9.asset_key, &"soldier4", "variant 4'e kenetlenir")


func test_machine_guy_variant_keys() -> void:
	var m := MachineGuy.new()
	m.variant = 2
	add_child_autofree(m)
	assert_eq(m.asset_key, &"machine_guy_b", "varyasyon>1 -> machine_guy_b")


func test_hellcat_chases_nearby_player() -> void:
	var sam := Samurai.new()
	add_child_autofree(sam)
	await _frames(2)
	var h := Hellcat.new()
	add_child_autofree(h)
	h.global_position = Vector2.ZERO
	sam.global_position = Vector2(80, 0)  # aggro x1.2 menzili icinde
	await _frames(6)
	assert_gt(h.velocity.x, 0.0, "menzildeki oyuncuya kosar")


func test_simple_roster_instantiates_alive() -> void:
	for e in [Druid.new(), Eagle.new(), DummyEnemy.new(), FlyingSword.new()]:
		add_child_autofree(e)
		assert_true(e.health.is_alive(),
			"%s canli dogar" % e.get_class())


func test_boss_death_clears_boss_spawn_projectiles() -> void:
	# Regresyon: boss olurken havada kalan mermiler (boss_spawn grubu)
	# sahnede kaliyordu — zafer kesiginde samurai'yi vurabiliyorlardi.
	var b := BossBase.new()
	add_child_autofree(b)
	b.activate()
	var m := Node2D.new()
	m.add_to_group(&"boss_spawn")
	add_child_autofree(m)
	b.health.take(999)
	assert_true(m.is_queued_for_deletion() or not is_instance_valid(m),
		"boss olumunde boss_spawn uyeleri temizlenir")


func test_gargoyle_only_robot_breaks() -> void:
	# M8: gargoyle tas — samurai kesigi seker (clang), robot vurusu kirar.
	var g := Gargoyle.new()
	add_child_autofree(g)
	var sam := Samurai.new()
	add_child_autofree(sam)
	await _frames(2)
	g.take_damage(DamageInfo.make(2, sam))
	assert_eq(g.health.current, g.health.max_health,
		"samurai formu tasla seker — hasar yok")
	GameState.unlock_form(&"robot")
	sam.equip_form(&"robot")
	sam.apply_pending_form()
	g.take_damage(DamageInfo.make(2, sam))
	assert_lt(g.health.current, g.health.max_health,
		"robot vurusu tasa girer")
	assert_eq(int(g.collision_layer & 1), 1,
		"govde terrain katmaninda — gecit duvari")


func test_smoke_mage_wider_range_than_druid() -> void:
	var m := SmokeMage.new()
	add_child_autofree(m)
	var d := Druid.new()
	add_child_autofree(d)
	assert_gt(m.attack_range, d.attack_range,
		"duman buyucusu uzaktan patlatir — menzil druid'i asar")
	assert_true(m.is_in_group(&"enemies"))


func after_each() -> void:
	# Dusman-spawn mermi/fx get_parent() altina eklenir — test dugumunun
	# kayit-disiz cocuklari olarak autofree'ye dusmez; elle temizle.
	# _awaiter GUT'un kendi cocugu: onu serbest birakmak await'i kilitler.
	for c in get_children():
		if c == _awaiter:
			continue
		if is_instance_valid(c) and not c.is_queued_for_deletion():
			c.queue_free()
	await wait_process_frames(2)
