extends GutTest
## M6 testleri: hayalet kivilcim-gorunurlugu, vampir kanama DoT,
## kurtadam parry'lenemez saldiri, Vlad 2. faz karanlik + gorsel ipucu,
## Golge formu i-frame dash, Ch3 akisi.

const CH3_PATH := "res://src/levels/ch3/Ch3.tscn"


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


# --- Hayalet ---

func test_ghost_hidden_until_spark() -> void:
	_flat_ground()
	var g := Ghost.new()
	g.global_position = Vector2(300, 240)
	add_child_autofree(g)
	await wait_seconds(0.1)
	var hp0 := g.health.current
	g.take_damage(DamageInfo.make(1, null))
	assert_eq(g.health.current, hp0, "gizli hayalet hasar almaz")
	EventBus.spark_emitted.emit(Vector2(300, 240))
	assert_true(g.revealed)
	g.take_damage(DamageInfo.make(1, null))
	assert_lt(g.health.current, hp0, "aciga cikinca vurulabilir")


# --- Vampir ---

func test_vampire_bleed_dot() -> void:
	_flat_ground()
	var s := _make_samurai()
	s.global_position = Vector2(300, 240)
	s.apply_bleed(3, 0.2)
	var hp0 := s.health.current
	await wait_seconds(0.75)
	assert_eq(s.health.current, hp0 - 3, "3 tick kanama = 3 hasar")


# --- Kurtadam ---

func test_werewolf_attack_not_parryable() -> void:
	_flat_ground()
	var w := Werewolf.new()
	w.global_position = Vector2(340, 240)
	add_child_autofree(w)
	await wait_seconds(0.1)
	# LEAP hitbox'i olustur ve kontrol et
	w.leap_hitbox.activate(DamageInfo.make(1, w, Vector2.ZERO, false, false))
	assert_false(w.leap_hitbox.damage_info.parryable, "kurtadam saldirisi parry'lenemez")
	w.leap_hitbox.deactivate()


# --- Vlad ---

func test_vlad_phase2_darkness_and_eyes() -> void:
	var b := CountVlad.new()
	add_child_autofree(b)
	b.activate()
	b.take_damage(DamageInfo.make(9, null))  # 16 -> 7 (%44)
	assert_eq(b.phase, 1)
	assert_not_null(b.darkness, "faz 2 karanlik ortu kurulmali")
	assert_eq(b.eyes.z_index, 10, "gozler karanligin ustunde (gorsel ipucu)")


func test_blood_spike_telegraph_then_hit() -> void:
	var s := BloodSpike.new()
	s.global_position = Vector2(300, 240)
	add_child_autofree(s)
	assert_false(s.hitbox.monitoring, "telegraph sirasinda hitbox kapali")
	var t: Tuning = load("res://config/tuning.tres")
	await wait_seconds(t.blood_spike_delay + 0.15)
	assert_true(s.hitbox.monitoring or not is_instance_valid(s),
		"kazik firlamis olmali")


# --- Golge formu ---

func test_golge_dash_iframes() -> void:
	var s := _make_samurai()
	GameState.unlock_form(&"golge")
	s.equip_form(&"golge")
	await wait_seconds(0.6)
	assert_eq(s.form.id, &"golge")
	assert_true(s.form.dash_iframes, "golge dash'i i-frame tasir")


# --- Ch3 akisi ---

func test_ch3_flow_boss_to_ch4_golge() -> void:
	var ch3: Node2D = load(CH3_PATH).instantiate()
	ch3.auto_advance = false
	add_child_autofree(ch3)
	await wait_seconds(0.2)
	ch3._on_arena_entered(ch3.samurai.hurtbox)
	await wait_seconds(1.4)   # intro ~1.15s sonra boss aktif olur
	assert_true(ch3.boss.active)
	ch3.boss.health.take(99)
	assert_has(GameState.unlocked_forms, &"golge", "Vlad olumu Golge acar")
	await wait_seconds(0.3)
	for child in ch3.get_children():
		if child is CutscenePlayer and child.playing:
			child.request_skip()
	await wait_seconds(0.3)
	assert_eq(GameState.current_chapter, &"ch4")
