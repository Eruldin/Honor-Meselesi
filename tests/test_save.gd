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
	InputMap.erase_action(&"test_bind_action")


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
