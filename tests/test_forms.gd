extends GutTest
## M2 kabul testleri: FormData degisimi, tavuk tunel+suzulus,
## robot catlak-zemin kirma, ayar kaliciligi.

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
	GameState.reset()
	floor_body = _make_floor(Vector2(0, 0), Vector2(400, 20))
	add_child_autofree(floor_body)
	sam = Samurai.new()
	ai = AIInputSource.new()
	sam.input = ai
	sam.global_position = Vector2(0, -30)
	add_child_autofree(sam)
	await _frames(14)


func after_each() -> void:
	Engine.time_scale = 1.0
	Settings.set_fx_intensity(1.0)
	# _awaiter GUT'un kendi cocugu — serbest birakma; diger kayit-disiz
	# cocuklari (dusman mermi/fx'i test dugumune ekler) elle temizle.
	for c in get_children():
		if c == _awaiter:
			continue
		if is_instance_valid(c) and not c.is_queued_for_deletion():
			c.queue_free()
	await wait_process_frames(2)  # queue_free bosaltsin


# --- Form gecisi ---

func test_cycle_form_transforms_and_resizes() -> void:
	GameState.unlock_form(&"tavuk")
	assert_eq(sam.form.id, &"samurai")
	ai.tap(&"form_next")
	await _frames(2)
	assert_eq(sam.sm.current_name, Samurai.S_TRANSFORM)
	await _frames(30)  # transform ~0.4s
	assert_eq(sam.form.id, &"tavuk")
	var cap := sam.col.shape as CapsuleShape2D
	assert_eq(cap.height, 10.0, "tavuk hitbox'i kuculmeli")
	assert_eq(GameState.current_form, &"tavuk")


func test_cycle_form_locked_form_skipped() -> void:
	# robot kilitli: sadece samurai+tavuk donmeli
	GameState.unlock_form(&"tavuk")
	ai.tap(&"form_next")
	await _frames(30)
	assert_eq(sam.form.id, &"tavuk")
	ai.tap(&"form_next")  # robot kilitli -> samurai'ye sarilmali
	await _frames(30)
	assert_eq(sam.form.id, &"samurai")


# --- Tavuk: suzulus + dar tunel ---

func test_chicken_glide_caps_fall_speed() -> void:
	GameState.unlock_form(&"tavuk")
	sam.apply_form_data(FormLibrary.get_form(&"tavuk"))
	sam.global_position = Vector2(0, -120)  # yuksekten dus
	ai.hold(&"jump")
	await _frames(45)  # yeterince dussun
	assert_gt(sam.velocity.y, 0.0, "dusuyor olmali")
	assert_lte(sam.velocity.y, sam.form.glide_fall_speed + 1.0,
		"suzulus dususu sinirlamali")
	ai.release(&"jump")


func test_samurai_blocked_chicken_fits_tunnel() -> void:
	# Tunel: tavan alti -25, zemin ustu -10 -> 15px gecit
	var ceiling := _make_floor(Vector2(170, -32), Vector2(90, 14))
	add_child_autofree(ceiling)
	ai.axis(1.0)
	await _frames(60)
	assert_lt(sam.global_position.x, 130.0,
		"samuray 15px gecide sigmamali")
	# Tavuga donusup gec
	GameState.unlock_form(&"tavuk")
	sam.apply_form_data(FormLibrary.get_form(&"tavuk"))
	await _frames(140)
	assert_gt(sam.global_position.x, 215.0, "tavuk tunelden gecebilmeli")
	ai.axis(0.0)


# --- Robot: catlak zemin ---

func test_robot_breaks_cracked_ground() -> void:
	var ground := CrackedGround.new()
	ground.global_position = Vector2(40, -13)
	add_child_autofree(ground)
	# Once samurai: kirmamali
	sam.global_position = Vector2(40, -60)
	await _frames(25)
	assert_true(is_instance_valid(ground))
	assert_false(ground.broken, "samurai kiramaz")
	# Robot formu: kirar
	sam.apply_form_data(FormLibrary.get_form(&"robot"))
	sam.global_position = Vector2(40, -60)
	await _frames(25)
	assert_true(ground.broken or not is_instance_valid(ground),
		"robot catlak zemini kirmali")


# --- Ayar kaliciligi ---

func test_sovalye_expiry_waits_out_of_cutscene() -> void:
	# Gecici form suresi cutscene/olum sirasinda dolarsa transformi erteler —
	# cutscene ortasinda oyuncu kontrolu acilmamali.
	GameState.unlock_form(&"sovalye")
	sam.equip_form(&"sovalye")
	await _frames(30)
	assert_eq(sam.form.id, &"sovalye")
	sam.sm.change_to(Samurai.S_CUTSCENE, true)
	sam.form_time_left = 0.01
	await _frames(10)
	assert_eq(sam.sm.current_name, Samurai.S_CUTSCENE,
		"cutscene sirasinda expiry transforma zorlamamali")
	sam.sm.change_to(Samurai.S_IDLE, true)
	await _frames(40)
	assert_eq(sam.form.id, &"samurai", "cutscene bitince expiry transform uygulamali")


func test_sovalye_form_id_not_knight() -> void:
	# Regresyon: adim-sesi dali '&"knight"' aradi ama form id '&"sovalye"' —
	# zirhli adim sesi hic calmiyordu. Kaynakta yanlis id kalmasin.
	var src := FileAccess.get_file_as_string("res://src/player/samurai.gd")
	assert_false(src.contains('&"knight"'),
		'form id "&"knight" gecersiz — dogru id: &"sovalye"')
	var f := FormLibrary.get_form(&"sovalye")
	assert_not_null(f, "sovalye formu kayitli olmali")


func test_settings_roundtrip() -> void:
	Settings.set_fx_intensity(0.35)
	Settings.set_shake_scale(0.5)
	Settings.fx_intensity = 0.9  # bellekte degistir
	var err_file := FileAccess.open("user://settings.json", FileAccess.READ)
	assert_not_null(err_file)
	Settings.load_settings()
	assert_almost_eq(Settings.fx_intensity, 0.35, 0.01)
	assert_almost_eq(Settings.shake_scale, 0.5, 0.01)
