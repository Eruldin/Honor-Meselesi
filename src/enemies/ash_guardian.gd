class_name AshGuardian
extends BossBase
## Bolum 5 boss'u — Kul Muhafizi (big_demon sprite'lari).
## F1: yaklasir, telegraph -> SLAM (iki yone sok dalgasi).
## F2 (%50): hizlanir + oyuncunun ustunde KUL GEYSERI serisi acar
## (BloodSpike'in kule boyali hali).

enum GState { SLEEP, SALUTE, APPROACH, TELL, SLAM_RISE, SLAM_FALL, GEYSER, GAP }
const BOW_ANGLE := 0.22

var bstate := GState.SLEEP
var _t := 0.0
var _player: Node2D
var facing := -1
var _atk_idx := 0
var arena_root: Node2D
var arena_left := 0.0
var arena_right := 0.0
var floor_y := 250.0


func _init() -> void:
	max_hp = 20
	body_size = Vector2(24, 26)
	contact_damage = true
	asset_key = &"ash_guardian"
	phase_thresholds = [0.5]


func _ready() -> void:
	super._ready()
	if not using_real_sprite:
		sprite.modulate = Color(0.6, 0.45, 0.4)
	else:
		# Kule bulanmis demon — kurşunimsi kizil
		sprite.modulate = Color(0.75, 0.6, 0.55)
		if anims != null:
			anims.modulate = Color(0.75, 0.6, 0.55)
	contact_hitbox.activate(DamageInfo.make(1, self, Vector2.ZERO, true, true))


func on_activated() -> void:
	# M8: saygi selami sinematigi — savas oncesi oyuncuya dogru vucut egimi.
	bstate = GState.SALUTE
	_t = tuning.guardian5_salute_dur
	_player = get_tree().get_first_node_in_group(&"player")
	if _player != null:
		facing = 1 if _player.global_position.x > global_position.x else -1
		sprite.flip_h = facing < 0
	_bow(true)


func _bow(on: bool) -> void:
	var r := BOW_ANGLE * facing if on else 0.0
	sprite.rotation = r
	if anims != null:
		anims.rotation = r


func on_reset() -> void:
	bstate = GState.SLEEP
	_t = 0.0
	_player = null
	_atk_idx = 0
	_bow(false)
	if using_real_sprite:
		sprite.modulate = Color(0.75, 0.6, 0.55)
		if anims != null:
			anims.modulate = Color(0.75, 0.6, 0.55)
	else:
		sprite.modulate = Color(0.6, 0.45, 0.4)


func on_phase_changed(_p: int) -> void:
	if anims != null:
		anims.modulate = Color(0.9, 0.55, 0.4)
	FX.glitch(0.6, 0.5)
	FX.shake(3.0, 0.4)


func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	if not active or not health.is_alive() or _parry_frozen(delta):
		return
	if _player == null:
		_player = get_tree().get_first_node_in_group(&"player")
		return
	var dx: float = _player.global_position.x - global_position.x
	facing = 1 if dx > 0 else -1
	sprite.flip_h = facing < 0
	_t -= delta
	var speed := tuning.guardian5_p2_speed if phase >= 1 else tuning.guardian5_speed
	var gap := tuning.guardian5_attack_gap_p2 if phase >= 1 else tuning.guardian5_attack_gap

	# M8 faz 2: alevli kilic — agiz bolgesinden yukselen kor tanecikleri.
	if phase >= 1:
		_ember_t -= delta
		if _ember_t <= 0.0:
			_ember_t = 0.14
			_spawn_ember()

	match bstate:
		GState.SALUTE:
			velocity.x = 0.0
			if _t <= 0.0:
				_bow(false)
				bstate = GState.APPROACH
				_t = tuning.guardian5_attack_gap * 1.4
				Pictogram.show_on(self, &"alarm", 1.0, Vector2(0, -34))
		GState.APPROACH:
			velocity.x = facing * speed
			if _t <= 0.0:
				_choose()
		GState.TELL:
			velocity.x = 0.0
			var c := Color(1.4, 1.15, 0.6)
			sprite.modulate = c
			if anims != null:
				anims.modulate = c
			if _t <= 0.0:
				# Yukari siplayip yere carpma
				bstate = GState.SLAM_RISE
				_t = 0.5
				sprite.modulate = Color(0.75, 0.6, 0.55)
				if anims != null:
					anims.modulate = Color(0.75, 0.6, 0.55)
		GState.SLAM_RISE:
			velocity.x = facing * 26.0
			velocity.y = -260.0
			if _t <= 0.0:
				bstate = GState.SLAM_FALL
				velocity.y = 60.0
		GState.SLAM_FALL:
			velocity.y = minf(velocity.y + 1600.0 * delta, 560.0)
			if is_on_floor():
				_land_slam()
				bstate = GState.GAP
				_t = gap
		GState.GEYSER:
			velocity.x = 0.0
			if _t <= 0.0:
				bstate = GState.GAP
				_t = gap
		GState.GAP:
			velocity.x = move_toward(velocity.x, 0.0, 600.0 * delta)
			if _t <= 0.0:
				bstate = GState.APPROACH
				_t = 1.6


func _choose() -> void:
	var pick := _atk_idx % 3 if phase >= 1 else _atk_idx % 2
	_atk_idx += 1
	match pick:
		0:
			bstate = GState.TELL
			_t = tuning.guardian5_telegraph
		1:
			bstate = GState.TELL
			_t = tuning.guardian5_telegraph
		_:  # geyser (faz 2)
			_cast_geysers()
			bstate = GState.GEYSER
			_t = tuning.ash_geyser_delay + 0.8


func _land_slam() -> void:
	FX.shake(3.5, 0.35)
	AudioManager.play_sfx(&"sfx/explosion", global_position)
	for d in [-1, 1]:
		var w := Shockwave.new()
		w.direction = d
		# M8: bolum bazli hasar carpani — agir darbe ~%%70 can
		w.damage = tuning.chapter_damage(&"ch5", tuning.guardian5_slam_damage)
		w.global_position = global_position + Vector2(d * 12, 8)
		w.add_to_group(&"boss_spawn")
		_root().add_child(w)


## Oyuncu cevresinde 3-5 kul geysir'i belirler (BloodSpike kule boyali).
func _cast_geysers() -> void:
	var n := 5 if phase >= 1 else 3
	for i in n:
		var sp := BloodSpike.new()
		sp.name = "AshGeyser"
		sp.global_position = Vector2(
			clampf(_player.global_position.x + (i - n / 2) * 34.0,
				arena_left + 12.0, arena_right - 12.0),
			floor_y)
		sp.telegraph = tuning.ash_geyser_delay
		sp.add_to_group(&"boss_spawn")
		_root().add_child(sp)
		# Kul rengi: uyari ve sivri kule boyanir (_ready cocuklari hazir)
		sp.get_node("warn").color = Color(0.7, 0.6, 0.45, 0.55)
		sp.get_node("spike").modulate = Color(0.55, 0.5, 0.45)


var _ember_t := 0.0

## M8 faz 2 alevli kilic: spark dokusunun kor tonunda tanecigi agiz
## hizasindan yukselip soner — WeatherFx ile ayni kendi-kendini
## temizleyen desen.
func _spawn_ember() -> void:
	if not AssetLoader.has_asset(&"fx/spark"):
		return
	var e := Sprite2D.new()
	e.name = &"guardian_ember"
	e.texture = AssetLoader.texture(&"fx/spark", Vector2i(4, 4))
	e.modulate = Color(1.0, 0.55, 0.25, 0.9)
	e.global_position = global_position + Vector2(facing * 9.0, -20.0)
	e.z_index = 6
	_root().add_child(e)
	var tw := e.create_tween()
	tw.tween_property(e, "global_position",
		e.global_position + Vector2(facing * randf_range(2.0, 10.0),
			-randf_range(8.0, 18.0)), 0.5)
	tw.parallel().tween_property(e, "modulate:a", 0.0, 0.5)
	tw.finished.connect(e.queue_free)


func _root() -> Node:
	return arena_root if arena_root != null else get_parent()
