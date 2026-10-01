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
		"sting bitince bolge muzigi geri gelir")
	assert_eq(AudioManager._sting_resume, &"",
		"resume tek seferlik")
	AudioManager.stop_music()
