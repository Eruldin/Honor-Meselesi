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


func test_creature_hurtbox_takes_hitbox_damage() -> void:
	# Regresyon: can_be_hit() owner'da take_damage arar — creature'da
	# _on_hit_info diye adlandirildigi icin butun hitbox yolu olu idi.
	var c := GlitchCreature.new()
	c.set_input_source(AIInputSource.new())
	add_child_autofree(c)
	assert_true(c.hurtbox.can_be_hit(), "creature hurtbox can_be_hit")
	var hb := Hitbox.new()
	hb.collision_layer = 32
	hb.collision_mask = 4
	var col := CollisionShape2D.new()
	var r := RectangleShape2D.new()
	r.size = Vector2(20, 20)
	col.shape = r
	hb.add_child(col)
	hb.global_position = c.global_position
	add_child_autofree(hb)
	hb.activate(DamageInfo.make(1, null, Vector2.ZERO, true, true))
	await _frames(3)
	assert_lt(c.health.current, c.health.max_health, "hitbox yaratici hasar verir")


func test_creature_hit_iframes_and_blink() -> void:
	var c := GlitchCreature.new()
	var ai := AIInputSource.new()
	c.set_input_source(ai)
	add_child_autofree(c)
	await _frames(3)
	c.take_damage(DamageInfo.make(1, c))
	assert_gt(c._iframes, 0.0, "vurusta dokunulmazlik")
	# i-frame goz kirpmasi: 70ms'lik desen ~12 fizik karesinde en az bir
	# 0.55 penceresi yakalar — eski kod alpha'yi hic degistirmezdi.
	var min_a := 1.0
	for i in 12:
		await _frames(1)
		min_a = minf(min_a, c.sprite.modulate.a)
	assert_lt(min_a, 0.7, "i-frame goz kirpmasi alpha'yi dusurmeli")


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


func test_bolt_damages_samurai_boss() -> void:
	# Yaratik'in tek saldirisi aktif boss'a erismeli — hurtbox dusman
	# katmaninda, take_damage aktiflige bagli (BossBase).
	var b := SamuraiBoss.new()
	b.arena_left = -200
	b.arena_right = 200
	b.global_position = Vector2(60, 0)
	add_child_autofree(b)
	b.activate()
	await _frames(3)
	var bolt := GlitchBolt.new()
	bolt.vel = Vector2.ZERO
	bolt.global_position = b.global_position + Vector2(-4, -4)
	add_child_autofree(bolt)
	await _frames(10)
	assert_lt(b.health.current, b.health.max_health,
		"glitch tanesi boss'u yaralar")


func test_creature_dash_stops_at_wall() -> void:
	# Glitch dash fiziksel hareket — 26px'lik kayma duvar arkasina gecmemeli.
	var wall := StaticBody2D.new()
	wall.collision_layer = 1
	var wc := CollisionShape2D.new()
	var wr := RectangleShape2D.new()
	wr.size = Vector2(20, 60)
	wc.shape = wr
	wall.add_child(wc)
	wall.global_position = Vector2(50, 0)
	add_child_autofree(wall)
	var c := GlitchCreature.new()
	var ai := AIInputSource.new()
	c.set_input_source(ai)
	c.global_position = Vector2(0, 0)
	c.facing = 1
	add_child_autofree(c)
	await _frames(3)
	ai.tap(&"dash")
	await _frames(3)
	assert_lt(c.global_position.x, 40.0,
		"dash duvarin arkasina gecmemeliydi")


func test_bolt_dies_on_wall() -> void:
	# Glitch tanesi terrain govdesinde silinir — duvar arkasindan vurmaz.
	var wall := StaticBody2D.new()
	wall.collision_layer = 1
	var wc := CollisionShape2D.new()
	var wr := RectangleShape2D.new()
	wr.size = Vector2(12, 80)
	wc.shape = wr
	wall.add_child(wc)
	wall.position = Vector2(100, 0)
	add_child_autofree(wall)
	var bolt := GlitchBolt.new()
	bolt.vel = Vector2(150, 0)
	bolt.global_position = Vector2(60, 0)
	add_child_autofree(bolt)
	await _frames(20)
	assert_false(is_instance_valid(bolt), "glitch tanesi duvarla yok olmali")


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


func test_creature_cannot_air_hop() -> void:
	var c := GlitchCreature.new()
	var ai := AIInputSource.new()
	c.set_input_source(ai)
	add_child_autofree(c)
	await _frames(10)  # havada dusuyor
	ai.tap(&"jump")
	await _frames(10)  # buffer suresi gecer — hop olmaz
	assert_gt(c.velocity.y, -60.0, "havada hop yok — ucus kapatildi")


func test_creature_grounded_hop_with_buffer() -> void:
	add_child_autofree(_make_floor(Vector2(0, 0), Vector2(400, 20)))
	var c := GlitchCreature.new()
	var ai := AIInputSource.new()
	c.set_input_source(ai)
	c.global_position = Vector2(0, -30)
	add_child_autofree(c)
	await _frames(30)  # hafif yercekimi — yavas oturur
	assert_true(c.is_on_floor(), "kurulum: yaratik zeminde")
	ai.tap(&"jump")
	await _frames(2)
	assert_lt(c.velocity.y, -30.0, "zeminde hop ziplar (kisa serbest birakma ile bile)")


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


func test_ch7_finished_game_returns_to_prolog() -> void:
	# Regresyon: final+epilog tamamlandiktan sonra Continue bos
	# arenada kaliyordu — tamamlanmis oyun Prolog'a doner (Ouroboros).
	GameState.set_flag(&"ch7_boss_dead")
	GameState.set_flag(&"ouroboros_done", true)
	var scene: Node2D = load("res://src/levels/ch7/Ch7.tscn").instantiate()
	# Emit'in SceneRouter'a ulasmasi GUT sahnesini swap eder — dinleyiciyi
	# test boyunca kes, sonra geri bagla.
	EventBus.scene_change_requested.disconnect(SceneRouter.change_scene)
	var got := [""]
	EventBus.scene_change_requested.connect(
		func(p: String) -> void: got[0] = p, CONNECT_ONE_SHOT)
	add_child_autofree(scene)
	await _frames(6)
	assert_eq(got[0], "res://src/levels/prolog/Prolog.tscn",
		"tamamlanmis oyun Prolog'a doner")
	EventBus.scene_change_requested.connect(SceneRouter.change_scene)


func test_creature_frozen_halts_input_but_falls() -> void:
	# Regresyon: Ouroboros sinemasi boyunca yaratik girdi okumaya devam
	# ediyordu — oyuncu son kesikte bolt atip sinemayi bozabiliyordu.
	add_child_autofree(_make_floor(Vector2(0, 0), Vector2(400, 20)))
	var c := GlitchCreature.new()
	var ai := AIInputSource.new()
	c.set_input_source(ai)
	c.global_position = Vector2(0, -40)
	add_child_autofree(c)
	await _frames(3)
	c.frozen = true
	ai.axis(1.0)
	ai.tap(&"attack")
	var x0 := c.global_position.x
	await _frames(15)
	assert_lt(absf(c.global_position.x - x0), 1.0,
		"frozen yaratik yurumez")
	await _frames(40)
	assert_true(c.is_on_floor(), "yercekimi surer — yere oturur")
	var found := false
	for n in get_children():
		if n is GlitchBolt:
			found = true
	assert_false(found, "frozen yaratik bolt atmaz")


func test_ch7_boss_defeat_freezes_creature() -> void:
	var scene: Node2D = load("res://src/levels/ch7/Ch7.tscn").instantiate()
	scene.auto_advance = false
	add_child_autofree(scene)
	await _frames(6)
	scene._on_boss_defeated()
	assert_true(scene.creature.frozen, "final kesigi girdiyi dondurur")


func test_ch7_boss_dead_rebuilds_epilogue() -> void:
	# Regresyon: boss-oldu bayragi yazili ama epilog yarida kesilmis
	# (quit/crash) — reload'da jenerik zinciri yeniden kurulur.
	GameState.set_flag(&"ch7_boss_dead")
	var scene: Node2D = load("res://src/levels/ch7/Ch7.tscn").instantiate()
	EventBus.scene_change_requested.disconnect(SceneRouter.change_scene)
	add_child_autofree(scene)
	await _frames(4)
	var credits_before := 0
	for c in scene.get_children():
		if c is Credits:
			credits_before += 1
	assert_eq(credits_before, 0, "jenerik kart once gelir")
	await get_tree().create_timer(2.6, true, false, true).timeout
	var found := false
	for n in scene.get_children():
		if n is CanvasLayer:
			for c in n.get_children():
				if c is Label and c.text == "15 YIL SONRA...":
					found = true
	assert_true(found, "epilog karti yeniden gosterilir")
	EventBus.scene_change_requested.connect(SceneRouter.change_scene)


func test_samurai_boss_sprite_flips_with_facing() -> void:
	# Facing hesaplaniyor ama sprite'a hic uygulanmiyordu — final boss
	# savrulus yonune gore gorsel donmuyordu.
	var b := SamuraiBoss.new()
	b.arena_left = -200
	b.arena_right = 200
	b.global_position = Vector2(0, 0)
	var c := GlitchCreature.new()
	c.global_position = Vector2(-40, 0)
	add_child_autofree(b)
	add_child_autofree(c)
	b.activate()
	await _frames(4)
	assert_eq(b.facing, -1, "oyuncu solda -> facing -1")
	assert_true(b.sprite.flip_h, "sola bakan boss sprite ters doner")
	c.global_position = Vector2(40, 0)
	await _frames(4)
	assert_eq(b.facing, 1, "oyuncu sagda -> facing 1")
	assert_false(b.sprite.flip_h, "saga bakan boss sprite duz durur")


func test_samurai_boss_clamped_to_arena() -> void:
	# arena_left/right ch7'de ataniyor ama hic uygulanmiyordu — boss
	# dash/approach ile arena sinirini asabiliyordu.
	var b := SamuraiBoss.new()
	b.arena_left = 10
	b.arena_right = 50
	b.global_position = Vector2(120, 0)
	var c := GlitchCreature.new()
	c.global_position = Vector2(200, 0)
	add_child_autofree(b)
	add_child_autofree(c)
	b.activate()
	await _frames(4)
	assert_lte(b.global_position.x, 50.0, "arena disina cikamaz")


func test_ch7_choice_skipped_on_reload() -> void:
	# Zorunlu secim bir kez sorulur — olum sonrasi reload'da
	# (ch7_choice_done flag'i) ekran gelmez, boss dogrudan uyanir.
	GameState.set_flag(&"ch7_choice_done")
	var scene: Node2D = load("res://src/levels/ch7/Ch7.tscn").instantiate()
	scene.auto_advance = false
	add_child_autofree(scene)
	await _frames(6)
	assert_true(scene._choice.is_empty(), "secim ekrani bir daha gosterilmez")
	assert_true(scene.boss.active, "boss dogrudan aktif — HK retry")
