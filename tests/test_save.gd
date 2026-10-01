extends GutTest
## Kayit sistemi: chapter eslemesi, Vector2 flag roundtrip, devam etme.

const TitleScript := preload("res://src/ui/title.gd")


func before_each() -> void:
	GameState.reset()
	SaveSystem.wipe()


func after_each() -> void:
	GameState.reset()
	SaveSystem.wipe()


func test_save_roundtrip_preserves_chapter_and_vector_flags() -> void:
	GameState.current_chapter = &"ch5"
	GameState.checkpoint_id = &"ch5_ruins"
	GameState.unlock_form(&"tavuk")
	GameState.set_flag(&"respawn_pos", Vector2(123.5, 200.25))
	GameState.set_flag(&"boss_intro_done", true)
	assert_eq(SaveSystem.save_game(), OK)
	GameState.reset()
	assert_eq(SaveSystem.load_game(), OK)
	assert_eq(GameState.current_chapter, &"ch5")
	assert_eq(GameState.checkpoint_id, &"ch5_ruins")
	assert_true(GameState.unlocked_forms.has(&"tavuk"))
	var pos: Variant = GameState.get_flag(&"respawn_pos")
	assert_true(pos is Vector2, "respawn_pos Vector2 olarak geri yuklenmeli")
	assert_almost_eq(pos.x, 123.5, 0.01)
	assert_almost_eq(pos.y, 200.25, 0.01)
	assert_eq(GameState.get_flag(&"boss_intro_done"), true)


func test_continue_maps_chapter_to_scene() -> void:
	assert_eq(TitleScript.CHAPTER_SCENES[&"ch5"], "res://src/levels/ch5/Ch5.tscn")
	assert_eq(TitleScript.CHAPTER_SCENES[&"ch7"], "res://src/levels/ch7/Ch7.tscn")
	for ch in TitleScript.CHAPTER_SCENES:
		assert_true(ResourceLoader.exists(TitleScript.CHAPTER_SCENES[ch]),
			"sahne mevcut olmali: %s" % TitleScript.CHAPTER_SCENES[ch])


func test_load_without_save_fails_cleanly() -> void:
	assert_eq(SaveSystem.load_game(), ERR_FILE_NOT_FOUND)


func test_settings_volume_persists() -> void:
	var old_music := Settings.music_volume
	Settings.set_music_volume(0.4)
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(Settings.PATH))
	assert_almost_eq(float(data.get("music_volume", -1.0)), 0.4, 0.001)
	Settings.set_music_volume(old_music)


func test_flash_warning_ack_persists() -> void:
	# M11: isiga duyarlilik uyari onayi settings.json'da saklanir —
	# ikinci acilista tekrar sormaz.
	var old := Settings.seen_flash_warning
	Settings.seen_flash_warning = true
	Settings.save_settings()
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(Settings.PATH))
	assert_true(bool(data.get("seen_flash_warning", false)),
		"uyari onayi settings.json'a yazilir")
	Settings.seen_flash_warning = old
	Settings.save_settings()


func test_difficulty_persists_and_clamps() -> void:
	# M11 zorluk ayari: settings.json'da saklanir, 0-2 araligina kelepçeli.
	var old := Settings.difficulty
	Settings.set_difficulty(0)
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(Settings.PATH))
	assert_eq(int(data.get("difficulty", -1)), 0, "zorluk kaydedilir")
	Settings.set_difficulty(9)
	assert_eq(Settings.difficulty, 2, "ust sinir 2")
	assert_eq(Settings.difficulty_health_delta(), -1, "ZOR: -1 kalp")
	Settings.set_difficulty(0)
	assert_eq(Settings.difficulty_health_delta(), 1, "KOLAY: +1 kalp")
	Settings.set_difficulty(old)


func test_binding_persists_across_load() -> void:
	# Kaydedilen rebind restart'ta InputMap'e geri uygulanmali.
	var old_binds: Dictionary = Settings.bind_overrides.duplicate(true)
	Settings.bind_overrides = {}
	InputMap.add_action(&"test_bind_action")
	InputMap.action_erase_events(&"test_bind_action")
	var ev := InputEventKey.new()
	ev.physical_keycode = KEY_G
	InputMap.action_add_event(&"test_bind_action", ev)
	Settings.set_binding(&"test_bind_action")
	# Simule edilen restart: event silinir, load geri yukler
	InputMap.action_erase_events(&"test_bind_action")
	Settings.load_settings()
	var restored := InputMap.action_get_events(&"test_bind_action")
	var found := false
	for e in restored:
		if e is InputEventKey and e.physical_keycode == KEY_G:
			found = true
	assert_true(found, "kaydedilen tusa atama restart'ta geri yuklenir")
	Settings.bind_overrides = old_binds
	Settings.save_settings()  # test kaydini diskten de temizle
	InputMap.erase_action(&"test_bind_action")


func test_rebind_steals_conflicting_key() -> void:
	# Regresyon: mouse/joypad yollari eski binding'i silmiyordu ve ayni
	# tus iki aksiyonda kalabiliyordu; ayrica calinan aksiyonun yeni
	# hali kaydedilmiyordu — restart'ta cakisma geri donerdi.
	var old_binds: Dictionary = Settings.bind_overrides.duplicate(true)
	var saved: Dictionary = {}
	for a in SettingsMenu.REBINDABLE:
		saved[a] = InputMap.action_get_events(a).duplicate()
	Settings.bind_overrides = {}
	var ev := InputEventKey.new()
	ev.physical_keycode = KEY_G
	InputMap.action_erase_events(&"jump")
	InputMap.action_add_event(&"jump", ev)
	var menu := SettingsMenu.new()
	add_child_autofree(menu)
	menu._rebinding = &"attack"
	menu._apply_rebind(ev)
	assert_eq(InputMap.action_get_events(&"jump").size(), 0,
		"tus kaynaktan calinir")
	assert_eq(InputMap.action_get_events(&"attack").size(), 1,
		"tus hedefe atanir")
	assert_true(Settings.bind_overrides.has(&"jump"),
		"calinan aksiyonun bos hali de kaydedilir")
	for a in saved:
		InputMap.action_erase_events(a)
		for e in saved[a]:
			InputMap.action_add_event(a, e)
	Settings.bind_overrides = old_binds
	Settings.save_settings()


func test_save_emits_game_saved_signal() -> void:
	# HUD kayit isareti bu sinyali dinler — basarili kayitta tetiklenmeli.
	watch_signals(EventBus)
	assert_eq(SaveSystem.save_game(), OK)
	assert_signal_emitted(EventBus, "game_saved")


func test_death_mark_cycle() -> void:
	GameState.current_chapter = &"ch3"
	GameState.soul = 7
	GameState.mark_death(Vector2(300, 200))
	assert_eq(GameState.soul, 0, "olum ruhu golgede kalir")
	assert_true(GameState.has_death_mark())
	var pos: Variant = GameState.get_flag(&"death_mark_pos")
	assert_true(pos is Vector2)
	assert_almost_eq(pos.x, 300.0, 0.01)
	var recovered := GameState.clear_death_mark()
	assert_eq(recovered, 7)
	assert_eq(GameState.soul, 7, "golge vurulunca ruh geri doner")
	assert_false(GameState.has_death_mark())


func test_death_mark_only_in_same_chapter() -> void:
	GameState.current_chapter = &"ch3"
	GameState.soul = 5
	GameState.mark_death(Vector2(100, 100))
	GameState.current_chapter = &"ch4"
	assert_false(GameState.has_death_mark(),
		"baska bolumdeki olum izi bu bolumde golge dogurmaz")


func test_death_mark_survives_save_load() -> void:
	GameState.current_chapter = &"ch3"
	GameState.soul = 9
	GameState.mark_death(Vector2(150.5, 210.25))
	assert_eq(SaveSystem.save_game(), OK)
	GameState.reset()
	GameState.current_chapter = &"ch3"
	assert_eq(SaveSystem.load_game(), OK)
	assert_true(GameState.has_death_mark(), "olum izi kayit sonrasi korunur")
	assert_eq(GameState.clear_death_mark(), 9)


func test_corrupt_save_fields_recover() -> void:
	# save.json plaintext — elle bozulan/kusurlu turler oyuna crash degil
	# guvenli varsayilan uretmeli.
	var f := FileAccess.open(SaveSystem.SAVE_PATH, FileAccess.WRITE)
	f.store_string(JSON.stringify({
		"version": 1,
		"chapter": "ch2",
		"flags": "bozuk",
		"unlocked_forms": 42,
		"soul": "degil",
	}))
	f.close()
	assert_eq(SaveSystem.load_game(), OK)
	assert_eq(GameState.current_chapter, &"ch2")
	assert_true(GameState.unlocked_forms.has(&"samurai"),
		"bozuk form listesi samurai'a doner")
	assert_eq(GameState.flags.size(), 0, "bozuk flags sozlugu yutulur")


func test_corrupt_save_flag_vector_recover() -> void:
	# Bozuk __v2 flag'i (dizi degil) Dictionary olarak saklanir — cokmez.
	var f := FileAccess.open(SaveSystem.SAVE_PATH, FileAccess.WRITE)
	f.store_string(JSON.stringify({
		"version": 1,
		"flags": {"respawn_pos": {"__v2": "nan"}},
	}))
	f.close()
	assert_eq(SaveSystem.load_game(), OK)
	var pos: Variant = GameState.get_flag(&"respawn_pos")
	assert_true(pos is Dictionary, "bozuk Vector2 girdisi ham kalir — crash yok")


func test_locked_current_form_falls_back() -> void:
	# Save'de current_form golge ama kilitli formlar sadece samurai —
	# oyuncu hic acmadigi forma dogamaz; samurai'a dusurulur.
	var f := FileAccess.open(SaveSystem.SAVE_PATH, FileAccess.WRITE)
	f.store_string(JSON.stringify({
		"version": 1,
		"current_form": "golge",
		"unlocked_forms": ["samurai"],
	}))
	f.close()
	assert_eq(SaveSystem.load_game(), OK)
	assert_eq(GameState.current_form, &"samurai",
		"kilitli olmayan forma dogus engellenir")


func test_out_of_range_save_fields_clamp() -> void:
	# Elle sisirilmis save: ruh ust sinira, negatif can bonusu sifira iner.
	var f := FileAccess.open(SaveSystem.SAVE_PATH, FileAccess.WRITE)
	f.store_string(JSON.stringify({
		"version": 1,
		"soul": 999,
		"hp_bonus": -5,
	}))
	f.close()
	assert_eq(SaveSystem.load_game(), OK)
	assert_eq(GameState.soul, GameState.SOUL_MAX, "ruh ust sinira kelepçeli")
	assert_eq(GameState.max_health_bonus, 0, "negatif hp_bonus sifirlanir")


func test_out_of_range_settings_clamp_on_load() -> void:
	# settings.json plaintext — elle sisirilmis degerler load'da setter
	# kelepçeleriyle sinirlanir (9x glitch puls, dev pencere yok).
	var saved_fx := Settings.fx_intensity
	var saved_win := Settings.window_scale
	var saved_music := Settings.music_volume
	var f := FileAccess.open(Settings.PATH, FileAccess.WRITE)
	f.store_string(JSON.stringify({
		"fx_intensity": 9.0,
		"shake_scale": -2.0,
		"music_volume": 4.0,
		"window_scale": 50,
	}))
	f.close()
	Settings.load_settings()
	assert_eq(Settings.fx_intensity, 1.0, "fx ust sinir 1")
	assert_eq(Settings.shake_scale, 0.0, "sarsinti alt sinir 0")
	assert_eq(Settings.music_volume, 1.0, "muzik ust sinir 1")
	assert_eq(Settings.window_scale, 6, "pencere ust sinir 6")
	Settings.fx_intensity = saved_fx
	Settings.window_scale = saved_win
	Settings.music_volume = saved_music
	Settings.save_settings()


func test_garbage_save_json_fails_cleanly() -> void:
	# Gecerli JSON ama Dictionary degil — devam etmeye calismak parse hatasi
	# uretir, title _on_new_game'e duser.
	var f := FileAccess.open(SaveSystem.SAVE_PATH, FileAccess.WRITE)
	f.store_string("[1, 2, 3]")
	f.close()
	assert_eq(SaveSystem.load_game(), ERR_PARSE_ERROR)
