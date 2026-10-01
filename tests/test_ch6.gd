extends GutTest
## M9 — Bolum 6: Parcalanmis Bellek.

var tuning: Tuning


func before_each() -> void:
	tuning = load("res://config/tuning.tres")
	GameState.reset()


func _frames(n: int) -> void:
	for i in n:
		await get_tree().physics_frame


func _make_samurai(pos := Vector2.ZERO) -> Samurai:
	var s := Samurai.new()
	s.global_position = pos
	add_child_autofree(s)
	return s


func test_flicker_platform_fades_and_returns() -> void:
	var f := FlickerPlatform.new()
	f.on_time = 0.5
	f.off_time = 0.3
	add_child_autofree(f)
	assert_eq(f.collision_layer, 1, "baslangicta saglam")
	await get_tree().create_timer(0.7).timeout
	assert_eq(f.collision_layer, 0, "unutulunca collision kapanir")
	await get_tree().create_timer(0.4).timeout
	assert_eq(f.collision_layer, 1, "geri gelir")


func test_amalgam_phase_and_attacks() -> void:
	var g := GlitchAmalgam.new()
	g.floor_y = 0.0
	g.global_position = Vector2(0, 0)
	var sam := _make_samurai(Vector2(30, 0))
	add_child_autofree(g)
	g.activate()
	await _frames(10)
	g.take_damage(DamageInfo.make(g.health.max_health / 2 + 1, sam))
	await _frames(5)
	assert_eq(g.phase, 2, "yari candan iki esik birden — faz 2")


func test_amalgam_defeat_signal() -> void:
	var g := GlitchAmalgam.new()
	var sam := _make_samurai()
	add_child_autofree(g)
	g.activate()
	watch_signals(g)
	g.take_damage(DamageInfo.make(999, sam))
	await _frames(2)
	assert_signal_emitted(g, "defeated")


func _unlock_forms(ids: Array[StringName]) -> void:
	for id in ids:
		GameState.unlock_form(id)


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


func test_amalgam_form_gated_phases() -> void:
	var g := GlitchAmalgam.new()
	g.floor_y = 0.0
	g.global_position = Vector2(0, 0)
	var ground := _make_floor(Vector2(15, 12), Vector2(120, 8))
	add_child_autofree(ground)
	var sam := _make_samurai(Vector2(30, 0))
	add_child_autofree(g)
	g.activate()
	_unlock_forms([&"robot", &"tavuk", &"golge"])
	await _frames(10)
	assert_true(sam.is_on_floor(), "kurulum: samurai zeminde")
	# P0 robot: samurai vurusu seker, robot girer
	g.take_damage(DamageInfo.make(2, sam))
	assert_eq(g.health.current, g.health.max_health, "faz 0 samurai vurusu seker")
	sam.equip_form(&"robot")
	sam.apply_pending_form()
	g.take_damage(DamageInfo.make(6, sam))
	assert_lt(g.health.current, g.health.max_health, "robot vurusu kirar")
	assert_eq(g.phase, 1, "75%% esigi — faz 1'e gecti")
	# P1 tavuk: baska form seker
	g.take_damage(DamageInfo.make(2, sam))
	assert_eq(g.health.current, 16, "faz 1 robot vurusu seker")
	sam.equip_form(&"tavuk")
	sam.apply_pending_form()
	g.take_damage(DamageInfo.make(6, sam))
	assert_eq(g.phase, 2, "50%% esigi — faz 2'ye gecti")
	# P2 golge
	g.take_damage(DamageInfo.make(2, sam))
	assert_eq(g.health.current, 10, "faz 2 tavuk vurusu seker")
	sam.equip_form(&"golge")
	sam.apply_pending_form()
	g.take_damage(DamageInfo.make(6, sam))
	assert_eq(g.phase, 3, "25%% esigi — faz 3'e gecti")
	# P3 piksel: yerdeki vurus seker (form ne olursa olsun)
	g.take_damage(DamageInfo.make(2, sam))
	assert_eq(g.health.current, 4, "faz 3 yerdeki golge vurusu seker")
	sam.global_position.y -= 60
	await _frames(2)
	assert_false(sam.is_on_floor(), "kurulum: samurai havada")
	g.take_damage(DamageInfo.make(2, sam))
	assert_eq(g.health.current, 2, "havadaki vurus girer — piksel sarti")


func test_amalgam_gate_opens_without_unlock() -> void:
	# Gerekli forma sahip degilse kapi kalkar (guvenlik agi)
	var g := GlitchAmalgam.new()
	var sam := _make_samurai()
	add_child_autofree(g)
	g.activate()
	g.take_damage(DamageInfo.make(2, sam))
	assert_lt(g.health.current, g.health.max_health,
		"robot kilitliyken samurai da hasar verir")


func test_weary_pose_only_in_ch6_rest() -> void:
	# M9: bellek dunyasi checkpoint'i — basini ellerine alma pozu
	if not AssetLoader.has_asset(&"prop/player_weary"):
		pending("player_weary yok (CI) — atlaniyor")
		return
	var sam := _make_samurai()
	await _frames(5)
	GameState.current_chapter = &"ch6"
	sam.sm.change_to(Samurai.S_REST, true)
	await _frames(2)
	assert_not_null(sam._weary, "ch6 rest'te yorgun poz sprite'i dogar")
	assert_true(sam._weary.visible, "yorgun poz gorunur")
	assert_true(sam._anims == null or not sam._anims.visible,
		"ayakta animasyon gizli")
	sam.sm.change_to(Samurai.S_IDLE, true)
	await _frames(2)
	assert_false(sam._weary.visible, "dinlenme bitince poz gizlenir")
	assert_true(sam._anims == null or sam._anims.visible or sam.sprite.visible,
		"normal gorsel geri gelir")


func test_weary_pose_off_in_other_chapters() -> void:
	var sam := _make_samurai()
	await _frames(5)
	GameState.current_chapter = &"ch1"
	sam.sm.change_to(Samurai.S_REST, true)
	await _frames(2)
	assert_true(sam._weary == null or not sam._weary.visible,
		"ch1'de yorgun poz yok — normal interact animi")


func test_katana_inspect_follows_weary_in_ch6() -> void:
	# M9: yorgunluktan ~1.6s sonra katananin catlagina bakma pozu
	if not AssetLoader.has_asset(&"prop/player_katana_inspect"):
		pending("player_katana_inspect yok (CI) — atlaniyor")
		return
	var sam := _make_samurai()
	await _frames(5)
	GameState.current_chapter = &"ch6"
	sam.sm.change_to(Samurai.S_REST, true)
	await _frames(2)
	assert_true(sam._weary.visible, "once yorgun poz")
	await _frames(105)
	assert_true(sam._katana_inspect != null and sam._katana_inspect.visible,
		"~1.6s sonra katana-inceleme pozuna gecer")
	assert_false(sam._weary.visible, "yorgun poz kapanir")
	sam.sm.change_to(Samurai.S_IDLE, true)
	await _frames(2)
	assert_false(sam._katana_inspect.visible, "cikista poz gizlenir")
	assert_true(sam._anims == null or sam._anims.visible or sam.sprite.visible,
		"normal gorsel geri gelir")


func test_ch6_scene_builds() -> void:
	var scene: Node2D = load("res://src/levels/ch6/Ch6.tscn").instantiate()
	scene.auto_advance = false
	add_child_autofree(scene)
	await _frames(10)
	assert_not_null(scene.samurai)
	assert_not_null(scene.boss)
	assert_eq(GameState.current_chapter, &"ch6")


func test_ch6_cleared_exit_portal_completes_chapter() -> void:
	# Regresyon: boss-oldu bayragi yazili ama gecis yarida kesilmis
	# (quit/crash/olum) — reload'da boss dogmaz; arena cikisindaki
	# portal tetigi bolumu tamamlar (soft-lock onlemi).
	GameState.set_flag(&"ch6_boss_dead")
	var scene: Node2D = load("res://src/levels/ch6/Ch6.tscn").instantiate()
	scene.auto_advance = false
	add_child_autofree(scene)
	await _frames(10)
	assert_null(scene.boss, "olu boss dogmaz")
	var trig: Area2D = null
	for c in scene.get_children():
		if c is Area2D and c.collision_mask == 4 \
				and c.global_position.x > 1500.0:
			trig = c
	assert_not_null(trig, "cikis portal tetigi var")
	var stub := Area2D.new()
	add_child_autofree(stub)
	trig.area_entered.emit(stub)
	assert_true(GameState.get_flag(&"ch6_done", false),
		"portal gecisi bolumu tamamlar")


func test_boss_bar_hidden_on_defeat() -> void:
	# Regresyon: boss olurken _boss_root acik kaliyordu — bos bar
	# temizlenen arenada ekrana yapismis duruyordu.
	var scene: Node2D = load("res://src/levels/ch6/Ch6.tscn").instantiate()
	scene.auto_advance = false
	add_child_autofree(scene)
	await _frames(5)
	scene._boss_root.visible = true   # savas ortasi taklidi
	scene._on_boss_defeated()
	assert_false(scene._boss_root.visible,
		"boss olumunde boss bar gizlenir")


func test_boss_defeat_survives_scene_free_during_wait() -> void:
	# Regresyon: SceneTreeTimer sahne free'sinden bagimsiz yasar — BASLIGA
	# DON yarisi devam kodunu freed node uzerinde calistiriyordu.
	var scene: Node2D = load("res://src/levels/ch6/Ch6.tscn").instantiate()
	scene.auto_advance = false
	add_child(scene)
	await _frames(3)
	scene._on_boss_defeated()
	await get_tree().create_timer(0.2).timeout
	scene.free()
	await get_tree().create_timer(1.8).timeout
	assert_true(true, "free yarisi beklemeyi sessizce keser — hata yok")


func test_memory_chimera_mixed_components() -> void:
	var c := MemoryChimera.new()
	c.global_position = Vector2(0, 0)
	add_child_autofree(c)
	_make_samurai(Vector2(80, 0))
	await _frames(5)
	# bilesen karisimi: ustte gezen drone parcasi var
	assert_true(is_instance_valid(c._drone_bit), "melez drone bileseni")
	assert_gt(c.health.max_health, 4,
		"melez can bilesenlerin toplami gibi (husk 4)")
	# spit bileseni: yakinda ara ara glitch tukurusu atar
	c._spit_t = 0.05
	await _frames(8)
	var found := false
	for n in get_children():
		if n is Projectile:
			found = true
	assert_true(found, "melez spit bileseni mermi atar")
