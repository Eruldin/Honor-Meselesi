extends GutTest
## M1 kabul testleri: hareket, coyote, buffer, kombo, parry penceresi,
## pogo, hasar/olum, dash. Gercek fizik frame'leriyle calisir.

var sam: Samurai
var ai: AIInputSource
var floor_body: StaticBody2D


func _make_floor(center: Vector2, size: Vector2) -> StaticBody2D:
	var body := StaticBody2D.new()
	body.collision_layer = 1
	body.collision_mask = 0
	var col := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = size
	col.shape = rect
	body.add_child(col)
	body.global_position = center
	return body


func _frames(n: int) -> void:
	for _i in n:
		await get_tree().physics_frame


func before_each() -> void:
	Engine.time_scale = 1.0
	floor_body = _make_floor(Vector2(0, 0), Vector2(400, 20))
	add_child_autofree(floor_body)
	sam = Samurai.new()
	ai = AIInputSource.new()
	sam.input = ai
	sam.global_position = Vector2(0, -30)
	add_child_autofree(sam)
	await _frames(14)  # yere otur (~10 frame dusus)
	assert_true(sam.is_on_floor(), "kurulum: samurai zeminde olmali")


func after_each() -> void:
	Engine.time_scale = 1.0
	GameState.soul = 0


# --- Hareket ---

func test_run_moves_right() -> void:
	var start_x := sam.global_position.x
	ai.axis(1.0)
	await _frames(15)
	assert_eq(sam.sm.current_name, Samurai.S_RUN)
	assert_gt(sam.velocity.x, 50.0)
	assert_gt(sam.global_position.x, start_x + 10.0)


func test_jump_leaves_ground() -> void:
	ai.tap(&"jump")
	await _frames(2)
	assert_lt(sam.velocity.y, 0.0, "ziplama yukari hiz vermeli")


func test_variable_jump_height() -> void:
	ai.hold(&"jump")
	await _frames(3)
	ai.release(&"jump")
	await _frames(2)
	var short_hop_vy_ended := sam.velocity.y
	assert_gt(short_hop_vy_ended, -140.0, "erken birakma ziplamayi kesmeli (cut)")


func test_coyote_time_allows_late_jump() -> void:
	floor_body.get_child(0).set_deferred("disabled", true)  # zemin kalkar
	await _frames(3)  # ~50ms < 90ms coyote
	ai.tap(&"jump")
	await _frames(2)
	assert_lt(sam.velocity.y, 0.0, "coyote penceresinde ziplamali")


func test_jump_buffer_fires_on_landing() -> void:
	floor_body.get_child(0).set_deferred("disabled", true)
	await _frames(2)
	ai.tap(&"jump")  # havadayken — buffer'a yazilir
	floor_body.get_child(0).set_deferred("disabled", false)
	var jumped := false
	for _i in 12:
		await get_tree().physics_frame
		if sam.velocity.y < 0.0:
			jumped = true
			break
	assert_true(jumped, "buffer: inince otomatik ziplamali")


func test_dash_speed_and_cooldown() -> void:
	ai.tap(&"dash")
	await _frames(3)
	assert_eq(sam.sm.current_name, Samurai.S_DASH)
	assert_almost_eq(absf(sam.velocity.x), sam.tuning.dash_speed, 5.0)
	await _frames(10)
	assert_ne(sam.sm.current_name, Samurai.S_DASH)
	assert_gt(sam.dash_cooldown, 0.0)


# --- Kombo ---

func test_combo_reaches_three_and_resets() -> void:
	ai.tap(&"attack")
	await _frames(2)
	assert_eq(sam.sm.current_name, Samurai.S_ATTACK)
	assert_eq(sam.combo_index, 1)
	ai.tap(&"attack")
	await _frames(22)  # saldiri suresi ~0.3s ~ 19 frame
	assert_eq(sam.combo_index, 2, "kuyruklu saldiri 2. vurusa gecmeli")
	ai.tap(&"attack")
	await _frames(22)
	assert_eq(sam.combo_index, 3)
	await _frames(24)
	assert_eq(sam.sm.current_name, Samurai.S_IDLE)
	assert_eq(sam.combo_index, 0)


func test_dash_cancels_attack_recovery() -> void:
	ai.tap(&"attack")
	await _frames(2)
	assert_eq(sam.sm.current_name, Samurai.S_ATTACK)
	await _frames(14)  # aktif pencere bitti (0.3*0.7=0.21s ~ 13 frame)
	ai.tap(&"dash")
	await _frames(2)
	assert_eq(sam.sm.current_name, Samurai.S_DASH,
		"toparlanma penceresi dash ile iptal edilir")


func test_dash_does_not_cancel_active_swing() -> void:
	ai.tap(&"attack")
	await _frames(4)   # hala aktif pencerede
	ai.tap(&"dash")
	await _frames(2)
	assert_eq(sam.sm.current_name, Samurai.S_ATTACK,
		"savrusun kendisi iptal edilemez")


# --- Parry ---

func _spawn_projectile_toward_player() -> Projectile:
	var p := Projectile.new()
	p.direction = -1
	p.speed = 110.0
	p.global_position = sam.global_position + Vector2(70, -2)
	add_child_autofree(p)
	return p


func test_parry_in_window_deflects() -> void:
	watch_signals(EventBus)
	var p := _spawn_projectile_toward_player()
	var parried := false
	for _i in 60:
		await get_tree().physics_frame
		if is_instance_valid(p) and absf(p.global_position.x - sam.global_position.x) < 20.0:
			ai.tap(&"parry")
			for _j in 6:
				await get_tree().physics_frame
			parried = true
			break
	assert_true(parried, "test: mermi menzile giremedi")
	if is_instance_valid(p):
		assert_true(p.reflected, "parry mermiyi geri cevirmeli")
	assert_eq(sam.health.current, sam.health.max_health, "parry'de hasar yok")
	assert_signal_emitted(EventBus, "parry_succeeded")
	assert_signal_emitted(EventBus, "hitstop_requested")


func test_parry_too_early_takes_damage() -> void:
	var p := _spawn_projectile_toward_player()
	ai.tap(&"parry")  # mermi 70px otede — pencere dolmadan carpar
	for _i in 60:
		await get_tree().physics_frame
		if sam.health.current < sam.health.max_health:
			break
	assert_lt(sam.health.current, sam.health.max_health,
		"pencere disi parry hasar yemeli")


func test_parry_whiff_locks_recovery() -> void:
	ai.tap(&"parry")
	await _frames(2)
	assert_eq(sam.sm.current_name, Samurai.S_PARRY)
	await _frames(10)  # pencere (7f) gecti, recovery (21f) suruyor
	assert_eq(sam.sm.current_name, Samurai.S_PARRY, "recovery boyunca kilitli")
	ai.tap(&"attack")
	await _frames(2)
	assert_eq(sam.sm.current_name, Samurai.S_PARRY, "recovery'de saldiri yok")
	await _frames(20)
	assert_ne(sam.sm.current_name, Samurai.S_PARRY, "recovery bitince serbest")


# --- Pogo ---

func test_pogo_bounces_off_spike() -> void:
	var spike := Spike.new()
	spike.global_position = Vector2(sam.global_position.x, -5.0)  # zeminde
	add_child_autofree(spike)
	sam.global_position = Vector2(spike.global_position.x, -60.0)
	await _frames(2)  # dusus basladi
	ai.hold(&"move_down")
	ai.tap(&"attack")
	var bounced := false
	for _i in 40:
		await get_tree().physics_frame
		if sam.velocity.y < -50.0:
			bounced = true
			break
	ai.release(&"move_down")
	assert_true(bounced, "pogoable hedefe inilince yukari sekmeli")
	assert_eq(sam.health.current, sam.health.max_health, "pogo'da hasar yok")


# --- Hasar / Olum ---

func test_damage_to_death() -> void:
	watch_signals(EventBus)
	var src: Node2D = add_child_autofree(Node2D.new())
	for i in sam.tuning.max_health:
		sam.invuln_timer = 0.0
		sam.take_damage(DamageInfo.make(1, src))
		if i < sam.tuning.max_health - 1:
			assert_eq(sam.sm.current_name, Samurai.S_HURT)
	assert_eq(sam.sm.current_name, Samurai.S_DEAD)
	assert_eq(sam.health.current, 0)
	assert_signal_emitted(EventBus, "actor_died")


func test_invuln_blocks_repeat_hits() -> void:
	var src: Node2D = add_child_autofree(Node2D.new())
	sam.take_damage(DamageInfo.make(1, src))
	sam.take_damage(DamageInfo.make(1, src))  # invuln icerisinde
	assert_eq(sam.health.current, sam.tuning.max_health - 1)


# --- Ruh odaklamasi (focus heal) ---

func test_focus_heal_spends_soul_and_heals() -> void:
	var src: Node2D = add_child_autofree(Node2D.new())
	sam.invuln_timer = 0.0
	sam.take_damage(DamageInfo.make(1, src))
	GameState.soul = 6
	ai.tap(&"focus")
	await _frames(2)
	assert_eq(GameState.soul, 0, "6 ruh harcanmali")
	assert_eq(sam.health.current, sam.tuning.max_health, "1 kalp iyilesmeli")


func test_focus_fails_without_soul() -> void:
	var src: Node2D = add_child_autofree(Node2D.new())
	sam.invuln_timer = 0.0
	sam.take_damage(DamageInfo.make(1, src))
	GameState.soul = 5
	ai.tap(&"focus")
	await _frames(2)
	assert_eq(GameState.soul, 5, "ruh yetmezse harcanmaz")
	assert_eq(sam.health.current, sam.tuning.max_health - 1)


func test_focus_noop_at_full_health() -> void:
	GameState.soul = 12
	ai.tap(&"focus")
	await _frames(2)
	assert_eq(GameState.soul, 12, "tam canda ruh korunur")
