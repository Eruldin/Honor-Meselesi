extends GutTest
## M0 smoke testleri: autoload'lar ayakta mi, AssetLoader placeholder'a
## dusuyor mu, proje import edilmis mi.


func test_event_bus_alive() -> void:
	assert_not_null(EventBus, "EventBus autoload yuklenmeli")


func test_game_state_defaults() -> void:
	assert_eq(GameState.current_chapter, &"prolog")
	assert_has(GameState.unlocked_forms, &"samurai")


func test_asset_loader_fallback_no_manifest_entry() -> void:
	var tex := AssetLoader.texture(&"does/not/exist")
	assert_not_null(tex, "Bilinmeyen asset icin placeholder uretilmeli")
	assert_is(tex, ImageTexture)


func test_asset_loader_deterministic_color() -> void:
	var a := AssetLoader.placeholder_texture("npc/koylu", Vector2i(8, 8))
	var b := AssetLoader.placeholder_texture("npc/koylu", Vector2i(8, 8))
	assert_same(a, b, "Placeholder cache ayni instance donmeli")


func test_settings_menu_pauses_world() -> void:
	var menu: SettingsMenu = add_child_autofree(SettingsMenu.new())
	menu.toggle()
	assert_true(get_tree().paused, "Ayarlar acikken dunya durmali")
	menu.toggle()
	assert_false(get_tree().paused, "Kapaninca devam etmeli")


func test_settings_menu_free_releases_pause() -> void:
	# Regresyon: acik menu sahne free'siyle yok olursa paused siziyor,
	# yeni sahnede dunya donmus kaliyordu (soft-lock goruntusu).
	var menu: SettingsMenu = SettingsMenu.new()
	add_child(menu)
	menu.toggle()
	assert_true(get_tree().paused, "menu dunyayi durdurur")
	menu.queue_free()
	await get_tree().process_frame
	await get_tree().process_frame
	assert_false(get_tree().paused, "menu yok olunca pause birakilir")


func test_slowmo_short_request_does_not_clip_longer() -> void:
	var fx: FxListener = add_child_autofree(FxListener.new())
	Engine.time_scale = 1.0
	# Not: gercek-zaman timer'lar — wait_seconds() time_scale'e takilip kalir.
	fx._slow_time(0.22, 0.55)   # kill-beat
	await get_tree().create_timer(0.05, true, false, true).timeout
	fx._slow_time(0.001, 0.05)  # ust uste binen kisa hitstop
	assert_almost_eq(Engine.time_scale, 0.001, 0.0001, "en dusuk scale aktif")
	await get_tree().create_timer(0.12, true, false, true).timeout
	assert_almost_eq(Engine.time_scale, 0.22, 0.0001,
		"kisa istek bitince uzun kill-beat surmeli — erken 1.0'a donmemeli")
	await get_tree().create_timer(0.5, true, false, true).timeout
	assert_eq(Engine.time_scale, 1.0, "tum istekler bitince normale doner")
	Engine.time_scale = 1.0


func test_fx_free_resets_time_scale() -> void:
	# Regresyon: aktif slow-mo istegi acikken FxListener free'lenirse
	# Engine.time_scale dusuk siziyor — yeni sahne agir cekimde kaliyordu.
	var fx: FxListener = FxListener.new()
	add_child(fx)
	fx._slow_time(0.22, 0.55)
	assert_almost_eq(Engine.time_scale, 0.22, 0.0001, "slow-mo aktif")
	fx.queue_free()
	await get_tree().process_frame
	await get_tree().process_frame
	assert_eq(Engine.time_scale, 1.0, "sahne free'si time_scale'i birakir")
	Engine.time_scale = 1.0


func test_save_roundtrip() -> void:
	GameState.set_flag(&"test_flag", 42)
	GameState.checkpoint_id = &"cp_test"
	var err := SaveSystem.save_game()
	assert_eq(err, OK)
	GameState.reset()
	assert_eq(GameState.checkpoint_id, &"")
	err = SaveSystem.load_game()
	assert_eq(err, OK)
	assert_eq(GameState.checkpoint_id, &"cp_test")
	assert_eq(GameState.get_flag(&"test_flag"), 42.0)
	SaveSystem.wipe()
	GameState.reset()

func test_music_director_combat_layer() -> void:
	var sam := Samurai.new()
	add_child_autofree(sam)
	var md := MusicDirector.new()
	md.player = sam
	md.calm_track = &"music/ch5"
	add_child_autofree(md)
	AudioManager.play_music(&"music/ch5")
	var e := CryptSkeleton.new()
	e.global_position = Vector2(60, 0)
	add_child_autofree(e)
	await get_tree().process_frame  # enemies grubuna katilsin
	md._process(0.5)               # tick — tehdit yakin
	assert_eq(AudioManager._current_music, &"music/combat",
		"yakin dusman combat katmanina gecirir")
	e.queue_free()
	await get_tree().process_frame
	for i in 10:                  # leave_delay 2.5s / 0.35 tick ~ 8 adim
		md._process(0.5)
	assert_eq(AudioManager._current_music, &"music/ch5",
		"tehdit bitince sakin parcaya doner")
	AudioManager.stop_music()


func test_victory_sting_resumes_zone_music() -> void:
	# Regresyon: victory fanfari loop=true ile sonsuz caliyordu —
	# manifest "loop": false ve bitis sinyali onceki bolgeye dondurur.
	assert_eq(AssetLoader.entry(&"music/victory").get("loop"), false,
		"victory tek-calar isaretli")
	AudioManager._current_music = &"music/victory"
	AudioManager._sting_resume = &"music/ch1"
	AudioManager._on_music_finished()
	assert_eq(AudioManager._current_music, &"music/ch1",
		"sting bitince boss muzigi degil bolge muzigi doner")
	assert_eq(AudioManager._sting_resume, &"",
		"resume tek seferlik")
	AudioManager.stop_music()


func test_slider_drag_survives_settings_rebuild() -> void:
	# Regresyon: Settings.changed -> _rebuild_tab slider'i free ederdi;
	# surukleme ilk adimda kopar, tutacak elden duserdi.
	var menu: SettingsMenu = add_child_autofree(SettingsMenu.new())
	menu.toggle()  # grafik sekmesi acik, sliderlar kurulu
	var slider: HSlider = null
	for row in menu._content.get_children():
		for c in row.get_children():
			if c is HSlider:
				slider = c
				break
		if slider != null:
			break
	assert_not_null(slider, "grafik sekmesinde HSlider kurulu olmali")
	slider.drag_started.emit()
	Settings.set_fx_intensity(Settings.fx_intensity)  # changed emit eder
	await get_tree().process_frame
	await get_tree().process_frame
	assert_true(is_instance_valid(slider),
		"surukleme sirasinda rebuild slider'i free etmemeli")
	slider.drag_ended.emit(true)
	await get_tree().process_frame
	await get_tree().process_frame
	assert_false(is_instance_valid(slider),
		"drag bitince rebuild son degeri senkronlar")
	menu.toggle()


func test_cutscene_survives_free_during_wait_step() -> void:
	# Regresyon: kesik beklemesi SceneTreeTimer'a bagli — sahne free'sinde
	# resume _advance icinde freed 'playing' uyesini okuyordu.
	var holder := Node2D.new()
	add_child(holder)
	var cs := CutscenePlayer.new()
	holder.add_child(cs)
	cs.play([{op = "wait", t = 0.8}, {op = "call",
		fn = func() -> void: pass}], {})
	await get_tree().create_timer(0.2).timeout
	holder.free()
	await get_tree().create_timer(0.9).timeout
	assert_true(true, "free sirasinda bekleyen kesik temiz cikis — hata yok")


func test_fx_slowmo_survives_listener_free() -> void:
	# Regresyon: slow-mo beklemesi SceneTreeTimer'a bagli — listener free'si
	# sonrasi _ts_reqs erase freed uye erisimiydi.
	var fl := FxListener.new()
	add_child(fl)
	fl._slow_time(0.5, 0.6)
	await get_tree().create_timer(0.2).timeout
	fl.free()
	await get_tree().create_timer(0.6).timeout
	assert_true(true, "free yarisi slow-mo beklemesini sessizce keser")


func test_all_scene_paths_exist() -> void:
	# Kontrat: kodda gecen tum res://*.tscn yollari diskte var olmali —
	# yanlis yazilmis sahne yolu run-time'a kadar sessiz kalir.
	var seen: Dictionary = {}
	var dir := DirAccess.open("res://src")
	if dir == null:
		pending("src dir yok")
		return
	var stack: Array[String] = ["res://src", "res://tools"]
	while not stack.is_empty():
		var dpath: String = stack.pop_back()
		var d := DirAccess.open(dpath)
		if d == null:
			continue
		d.list_dir_begin()
		var name := d.get_next()
		while name != "":
			if d.current_is_dir() and name != "." and name != "..":
				stack.append(dpath + "/" + name)
			elif name.ends_with(".gd"):
				var src := FileAccess.get_file_as_string(dpath + "/" + name)
				var re := RegEx.create_from_string(r"res://[A-Za-z0-9_./-]+\.tscn")
				for m in re.search_all(src):
					seen[m.get_string()] = true
			name = d.get_next()
		d.list_dir_end()
	assert_gt(seen.size(), 5, "en az 6 sahne yolu kodda gecmeli")
	for path in seen.keys():
		assert_true(ResourceLoader.exists(path), "sahne yolu var olmali: " + path)


func test_all_load_preload_paths_exist() -> void:
	# Kontrat: load("res://...")/preload("res://...") literal yollari diskte
	# var olmali — load() silinen dosyada null doner ve sessizce kirilir.
	var seen: Dictionary = {}
	var stack: Array[String] = ["res://src", "res://tools"]
	var re := RegEx.create_from_string(r'(?:pre)?load\("(res://[^"]+)"\)')
	while not stack.is_empty():
		var dpath: String = stack.pop_back()
		var d := DirAccess.open(dpath)
		if d == null:
			continue
		d.list_dir_begin()
		var name := d.get_next()
		while name != "":
			if d.current_is_dir() and name != "." and name != "..":
				stack.append(dpath + "/" + name)
			elif name.ends_with(".gd"):
				var src := FileAccess.get_file_as_string(dpath + "/" + name)
				for m in re.search_all(src):
					seen[m.get_string(1)] = true
			name = d.get_next()
		d.list_dir_end()
	assert_gt(seen.size(), 3, "en az 4 load/preload yolu gecmeli")
	for path in seen.keys():
		assert_true(FileAccess.file_exists(path),
			"load/preload hedefi yok: " + path)


func test_main_scene_exists() -> void:
	var main: String = ProjectSettings.get_setting("application/run/main_scene", "")
	assert_true(ResourceLoader.exists(main), "main_scene var olmali: " + main)


func test_all_audio_ids_in_manifest() -> void:
	# Kontrat: kodda literal gecen sfx/music/amb id'leri manifest'te var
	# olmali — yazim hatasi sessizce isitilmez cue uretir (or. sfx/whoosh).
	var f := FileAccess.open("res://assets_manifest.json", FileAccess.READ)
	if f == null:
		pending("manifest yok (CI)")
		return
	var man: Dictionary = JSON.parse_string(f.get_as_text())
	var keys: Dictionary = man.get("assets", man)
	var seen: Dictionary = {}
	var stack: Array[String] = ["res://src", "res://tools"]
	while not stack.is_empty():
		var dpath: String = stack.pop_back()
		var d := DirAccess.open(dpath)
		if d == null:
			continue
		d.list_dir_begin()
		var name := d.get_next()
		while name != "":
			if d.current_is_dir() and name != "." and name != "..":
				stack.append(dpath + "/" + name)
			elif name.ends_with(".gd"):
				var src := FileAccess.get_file_as_string(dpath + "/" + name)
				var re := RegEx.create_from_string(
					r'&"(sfx|music|amb)/[A-Za-z0-9_/.-]+"')
				for m in re.search_all(src):
					var id := (m.get_string() as String).trim_prefix("&\"").trim_suffix("\"")
					seen[id] = true
			name = d.get_next()
		d.list_dir_end()
	assert_gt(seen.size(), 30, "en az 30 ses id'si kodda gecmeli")
	for id in seen.keys():
		assert_true(keys.has(id), "manifest'te olmayan ses id'si: " + id)


func test_all_ext_resource_paths_exist() -> void:
	# Kontrat: .tscn/.tres icindeki ext_resource path="res://..." referanslari
	# diskte var olmali — kaynak dosyasi silinirse sahne sessizce bozulur.
	var seen: Dictionary = {}
	var stack: Array[String] = ["res://src", "res://tools", "res://config"]
	var re := RegEx.create_from_string(r'path="(res://[^"]+)"')
	while not stack.is_empty():
		var dpath: String = stack.pop_back()
		var d := DirAccess.open(dpath)
		if d == null:
			continue
		d.list_dir_begin()
		var name := d.get_next()
		while name != "":
			if d.current_is_dir() and name != "." and name != "..":
				stack.append(dpath + "/" + name)
			elif name.ends_with(".tscn") or name.ends_with(".tres"):
				var src := FileAccess.get_file_as_string(dpath + "/" + name)
				for m in re.search_all(src):
					seen[m.get_string(1)] = true
			name = d.get_next()
		d.list_dir_end()
	assert_gt(seen.size(), 5, "en az 6 ext_resource yolu gecmeli")
	for path in seen.keys():
		var fs_path := (path as String).trim_prefix("res://")
		assert_true(FileAccess.file_exists(path),
			"ext_resource hedefi yok: " + path + " (" + fs_path + ")")
