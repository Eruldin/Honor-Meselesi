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
