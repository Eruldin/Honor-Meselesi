extends GutTest
## M6 testleri: hayalet kivilcim-gorunurlugu, vampir kanama DoT,
## kurtadam parry'lenemez saldiri, Vlad 2. faz karanlik + gorsel ipucu,
## Golge formu i-frame dash, Ch3 akisi.

const CH3_PATH := "res://src/levels/ch3/Ch3.tscn"


func after_each() -> void:
	GameState.reset()
	SaveSystem.wipe()


func _make_samurai() -> Samurai:
	var s := Samurai.new()
	add_child_autofree(s)
	return s


func _flat_ground() -> StaticBody2D:
	var g := StaticBody2D.new()
	g.collision_layer = 1
	var col := CollisionShape2D.new()
	var r := RectangleShape2D.new()
	r.size = Vector2(2000, 20)
	col.shape = r
	g.add_child(col)
	g.position = Vector2(500, 260)
	add_child_autofree(g)
	return g


# --- Hayalet ---

func test_ghost_hidden_until_spark() -> void:
	_flat_ground()
	var g := Ghost.new()
	g.global_position = Vector2(300, 240)
	add_child_autofree(g)
	await wait_seconds(0.1)
	var hp0 := g.health.current
	g.take_damage(DamageInfo.make(1, null))
	assert_eq(g.health.current, hp0, "gizli hayalet hasar almaz")
	EventBus.spark_emitted.emit(Vector2(300, 240))
	assert_true(g.revealed)
	g.take_damage(DamageInfo.make(1, null))
	assert_lt(g.health.current, hp0, "aciga cikinca vurulabilir")


# --- Vampir ---

func test_vampire_bleed_dot() -> void:
	_flat_ground()
	var s := _make_samurai()
	s.global_position = Vector2(300, 240)
	s.apply_bleed(3, 0.2)
	var hp0 := s.health.current
	await wait_seconds(0.75)
	assert_eq(s.health.current, hp0 - 3, "3 tick kanama = 3 hasar")


func test_vampire_strike_bleeds_unparried() -> void:
	_flat_ground()
	var s := _make_samurai()
	s.global_position = Vector2(300, 240)
	var v := Vampire.new()
	v.global_position = Vector2(290, 240)
	v._player = s
	add_child_autofree(v)
	await wait_seconds(0.05)
	v._strike()
	assert_gt(s.bleed_ticks, 0, "parry'siz isirik kanama birakir")


func test_vampire_strike_parried_no_bleed() -> void:
	# Regresyon: take_damage parry'de erken donuyordu ama apply_bleed
	# yine de uygulaniyordu — basarili parry kanamayi da engeller.
	_flat_ground()
	var s := _make_samurai()
	s.global_position = Vector2(300, 240)
	s.sm.change_to(Samurai.S_PARRY, true)
	var v := Vampire.new()
	v.global_position = Vector2(290, 240)
	v._player = s
	add_child_autofree(v)
	await wait_seconds(0.05)
	v._strike()
	assert_true(s.parry_succeeded, "vurus parry'lenir")
	assert_eq(s.bleed_ticks, 0, "parry'lenen isirik kanama birakmaz")


func test_vampire_strike_bleeds_after_old_parry() -> void:
	# Regresyon: parry_succeeded hic sifirlanmiyordu — eski parry izi
	# sonraki isiriklari parry'li saydiriyordu (kanama hic uygulanamazdi).
	_flat_ground()
	var s := _make_samurai()
	s.global_position = Vector2(300, 240)
	s.parry_succeeded = true   # cok onceki parry'den kalan bayrak
	var v := Vampire.new()
	v.global_position = Vector2(290, 240)
	v._player = s
	add_child_autofree(v)
	await wait_seconds(0.05)
	v._strike()
	assert_false(s.parry_succeeded, "bayrak vurusa ait sonuca sifirlanir")
	assert_gt(s.bleed_ticks, 0, "eski parry kanamayi engellemez")


# --- Kurtadam ---

func test_werewolf_attack_not_parryable() -> void:
	_flat_ground()
	var w := Werewolf.new()
	w.global_position = Vector2(340, 240)
	add_child_autofree(w)
	await wait_seconds(0.1)
	# LEAP hitbox'i olustur ve kontrol et
	w.leap_hitbox.activate(DamageInfo.make(1, w, Vector2.ZERO, false, false))
	assert_false(w.leap_hitbox.damage_info.parryable, "kurtadam saldirisi parry'lenemez")
	w.leap_hitbox.deactivate()


# --- Vlad ---

func test_vlad_phase2_darkness_and_eyes() -> void:
	var b := CountVlad.new()
	add_child_autofree(b)
	b.activate()
	b.take_damage(DamageInfo.make(9, null))  # 16 -> 7 (%44)
	assert_eq(b.phase, 1)
	assert_not_null(b.darkness, "faz 2 karanlik ortu kurulmali")
	assert_eq(b.eyes.z_index, 10, "gozler karanligin ustunde (gorsel ipucu)")
	# Regresyon: karanlik CanvasLayer'deydi — dunya dugumu z_index'i
	# asamaz, gozler karanlikta kayboluyordu. Artik ikisi de dunya
	# dugumu; gozler karanligin ustunde cizilir.
	assert_eq(b.darkness.get_parent(), b,
		"karanlik Vlad'in cocugu — CanvasLayer degil (gozleri ezmez)")
	assert_gt(b.eyes.z_index, b.darkness.z_index,
		"ayni ebeveyn altinda goz z'i karanlik z'inden buyuk")
	# Regresyon: kan kazigi z=0'daydi — faz 2'de uyarici isaret + kazik
	# %82 karanligin altinda boguluyor, parry penceresi okunamaz oluyordu.
	var s := BloodSpike.new()
	add_child_autofree(s)
	assert_gt(s.z_index, b.darkness.z_index,
		"kazik telegraph'i karanlik ortusunun ustunde kalmali")
	# Ayni aile: balonlar z=0 host cocugu — portal (z=7) ya da karanlik
	# (z=5) altinda kalan ikon gorunmez olurdu.
	var p := Pictogram.show_on(b, &"alarm")
	assert_gt(p.z_index, b.darkness.z_index,
		"piktogram balonu dunya ortulerinin ustunde kalmali")
	# Ters yonlu sozlesme: ambiyans havasi (mezarlik sisi) karanligin
	# ALTINDA kalmali — yoksa "karanlik" fazda soluk sis parlar.
	assert_lt(WeatherFx.PARTICLE_Z, b.darkness.z_index,
		"ambiyans parcaciklar karanlik ortusuyle birlikte kararir")


func test_blood_spike_telegraph_then_hit() -> void:
	var s := BloodSpike.new()
	s.global_position = Vector2(300, 240)
	add_child_autofree(s)
	assert_false(s.hitbox.monitoring, "telegraph sirasinda hitbox kapali")
	var t: Tuning = load("res://config/tuning.tres")
	await wait_seconds(t.blood_spike_delay + 0.15)
	assert_true(s.hitbox.monitoring or not is_instance_valid(s),
		"kazik firlamis olmali")


# --- Golge formu ---

func test_golge_dash_iframes() -> void:
	var s := _make_samurai()
	GameState.unlock_form(&"golge")
	s.equip_form(&"golge")
	await wait_seconds(0.6)
	assert_eq(s.form.id, &"golge")
	assert_true(s.form.dash_iframes, "golge dash'i i-frame tasir")


# --- Mezar iskeleti ---

func test_skeleton_rises_when_player_near() -> void:
	_flat_ground()
	var s := _make_samurai()
	s.global_position = Vector2(1000, 240)   # rise_range disi
	var sk := CryptSkeleton.new()
	sk.global_position = Vector2(400, 241)
	add_child_autofree(sk)
	await wait_seconds(0.15)
	assert_false(sk._risen, "uzak oyuncu — iskelet gomulu kalir")
	assert_false(sk.hurtbox.monitoring, "gomulu iskelet vurulamaz")
	s.global_position = Vector2(380, 240)    # rise_range (70) icine
	await wait_seconds(1.2)
	assert_true(sk._risen, "yakin oyuncuda iskelet yukselir")
	assert_true(sk.hurtbox.monitoring, "yukselen iskelet vurulabilir")


# --- Ch3 akisi ---

func test_ch3_flow_boss_to_ch4_golge() -> void:
	var ch3: Node2D = load(CH3_PATH).instantiate()
	ch3.auto_advance = false
	add_child_autofree(ch3)
	await wait_seconds(0.2)
	ch3._on_arena_entered(ch3.samurai.hurtbox)
	await wait_seconds(1.4)   # intro ~1.15s sonra boss aktif olur
	assert_true(ch3.boss.active)
	# Kesik sirasinda sahneyi kirpan kalan adds testi: boss olumunde
	# tum canli dusmanlar sersemler.
	var bat := CaveBat.new()
	bat.global_position = ch3.samurai.global_position + Vector2(0, -20)
	ch3.add_child(bat)
	ch3.boss.health.take(99)
	assert_gt(bat.stagger_timer, 0.0,
		"boss olumunde kalan adds sersemler")
	assert_has(GameState.unlocked_forms, &"golge", "Vlad olumu Golge acar")
	await wait_seconds(0.3)
	for child in ch3.get_children():
		if child is CutscenePlayer and child.playing:
			child.request_skip()
	await wait_seconds(0.3)
	assert_eq(GameState.current_chapter, &"ch4")


func test_ghost_dim_cue_reaches_visible() -> void:
	_flat_ground()
	var g := Ghost.new()
	g.global_position = Vector2(300, 240)
	add_child_autofree(g)
	# CI'da gercek sheet'ler yok — cue hangi gorsel yuzeye gidiyorsa orada dogrula
	var vis: CanvasItem = g.anims if g.anims != null else g.sprite
	assert_lt(vis.modulate.a, 0.5, "soluk hayalet karartilmis gorunmeli")
	g.reveal()
	assert_gt(vis.modulate.a, 0.9, "aciga cikan hayalet parlak gorunmeli")


func test_werewolf_telegraph_tints_anims() -> void:
	_flat_ground()
	var s := _make_samurai()
	s.global_position = Vector2(300, 240)
	var w := Werewolf.new()
	w.global_position = Vector2(350, 240)
	add_child_autofree(w)
	await wait_seconds(0.1)  # _player cozumlesin
	var vis: CanvasItem = w.anims if w.anims != null else w.sprite
	w._t = 0.0
	w._physics_process(0.016)
	assert_eq(w.wstate, Werewolf.WState.TELEGRAPH)
	assert_gt(vis.modulate.r, 1.0,
		"kirmizi goz telegraphi gorunur gorselde de gorunmeli")
