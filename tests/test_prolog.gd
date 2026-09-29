extends GutTest
## M3 testleri: CutscenePlayer adim sirasi/skip, Pictogram yasam dongusu,
## CrtGame atlatma + glitch, Prolog akisi (auto_advance kapali).

const PROLOG_PATH := "res://src/levels/prolog/Prolog.tscn"
const PrologScript := preload("res://src/levels/prolog/prolog.gd")

var _prolog: Node2D


func after_each() -> void:
	GameState.reset()


func _make_prolog() -> Node2D:
	var p: Node2D = load(PROLOG_PATH).instantiate()
	p.set_script(PrologScript)
	p.auto_advance = false
	p.fast_mode = true
	add_child_autofree(p)
	return p


# --- CutscenePlayer ---

func test_cutscene_runs_steps_in_order() -> void:
	var order: Array[int] = []
	var cs := CutscenePlayer.new()
	add_child_autofree(cs)
	var done := [false]
	cs.finished.connect(func() -> void: done[0] = true)
	cs.play([
		{op = "call", fn = func() -> void: order.append(1)},
		{op = "call", fn = func() -> void: order.append(2)},
		{op = "flag", key = &"t_flag", value = "x"},
	], {})
	await wait_process_frames(5)
	assert_eq(order, [1, 2], "adimlar sirayla kosmali")
	assert_true(done[0], "finished yayilmali")
	assert_eq(GameState.get_flag(&"t_flag"), "x")


func test_cutscene_skip_calls_end_state() -> void:
	var cs := CutscenePlayer.new()
	add_child_autofree(cs)
	var end_hit := [false]
	var done := [false]
	cs.finished.connect(func() -> void: done[0] = true)
	cs.play([
		{op = "wait", t = 5.0},
		{op = "call", fn = func() -> void: end_hit[0] = true},
	], {}, func() -> void: end_hit[0] = true)
	await wait_process_frames(3)
	cs.request_skip()
	await wait_process_frames(2)
	assert_true(done[0], "skip sonrasi finished yayilmali")
	assert_true(end_hit[0], "end_state cagrilmali")
	assert_false(cs.playing)


func test_cutscene_walk_to_moves_node() -> void:
	var n := Node2D.new()
	add_child_autofree(n)
	n.global_position = Vector2(10, 50)
	var cs := CutscenePlayer.new()
	add_child_autofree(cs)
	var done := [false]
	cs.finished.connect(func() -> void: done[0] = true)
	cs.play([{op = "walk_to", node = "n", x = 60.0, speed = 500.0}], {"n": n})
	await wait_seconds(0.4)
	assert_true(done[0])
	assert_almost_eq(n.global_position.x, 60.0, 2.0)


# --- Pictogram ---

func test_pictogram_shows_and_frees() -> void:
	var host := Node2D.new()
	add_child_autofree(host)
	var p := Pictogram.show_on(host, &"hat", 0.1)
	assert_true(p.is_inside_tree())
	await wait_seconds(0.6)
	assert_false(is_instance_valid(p), "sure bitince yok olmali")


func test_pictogram_all_icons_draw() -> void:
	var host := Node2D.new()
	add_child_autofree(host)
	for icon in Pictogram.ICONS:
		var p := Pictogram.show_on(host, icon, 0.05)
		assert_not_null(p)
	await wait_seconds(0.4)


# --- CrtGame ---

func test_crt_game_dodge_counts() -> void:
	var g := CrtGame.new()
	g.input = AIInputSource.new()
	add_child_autofree(g)
	var spy: Array[int] = []
	g.obstacle_dodged.connect(func(c: int) -> void: spy.append(c))
	# Tek engel uret ve gecmesini bekle (hizla sola gider)
	g._spawn_obstacle()
	await wait_seconds(2.0)
	assert_gt(spy.size(), 0, "en az bir engel atlatilmali")


func test_crt_game_glitch_emits() -> void:
	var g := CrtGame.new()
	g.input = AIInputSource.new()
	add_child_autofree(g)
	var hit := [false]
	g.glitched.connect(func() -> void: hit[0] = true)
	g.glitch_out()
	await wait_seconds(1.0)
	assert_true(hit[0], "glitch_out sonrasi glitched yayilmali")


# --- Prolog akisi ---

func _wait_phase(p: Node2D, phase: StringName, timeout: float = 6.0) -> bool:
	var t := 0.0
	while p._phase != phase and t < timeout:
		await wait_seconds(0.1)
		t += 0.1
	return p._phase == phase


func test_prolog_play_to_cutscene_to_done() -> void:
	_prolog = _make_prolog()
	assert_true(await _wait_phase(_prolog, &"play"), "fade-in sonrasi oyun fazi")
	# Oyun fazini hizla bitir
	_prolog.crt_game.glitch_out()
	assert_true(await _wait_phase(_prolog, &"cutscene", 3.0))
	# Skip ile sona atla
	_prolog.cutscene.request_skip()
	await wait_process_frames(3)
	assert_eq(_prolog._phase, &"done")
	assert_true(GameState.get_flag(&"prolog_done"))
	assert_eq(GameState.current_chapter, &"ch1")
	assert_true(GameState.get_flag(&"hat_stolen"), "end_state flag'leri kurulmali")


func test_prolog_full_sequence_without_skip() -> void:
	_prolog = _make_prolog()
	assert_true(await _wait_phase(_prolog, &"play"))
	_prolog.crt_game.glitch_out()
	assert_true(await _wait_phase(_prolog, &"cutscene", 3.0))
	# Cutscene'i dogal sonuna kadar bekle (adimlar ~6s)
	var timeout := 12.0
	var t := 0.0
	while _prolog._phase != &"done" and t < timeout:
		await wait_seconds(0.25)
		t += 0.25
	assert_eq(_prolog._phase, &"done", "cutscene kendiliginden bitmeli")
	assert_eq(GameState.current_chapter, &"ch1")
