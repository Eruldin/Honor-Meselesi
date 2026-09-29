class_name AshGuardian
extends BossBase
## Bolum 5 boss'u — Kul Muhafizi (big_demon sprite'lari).
## F1: yaklasir, telegraph -> SLAM (iki yone sok dalgasi).
## F2 (%50): hizlanir + oyuncunun ustunde KUL GEYSERI serisi acar
## (BloodSpike'in kule boyali hali).

enum GState { SLEEP, APPROACH, TELL, SLAM_RISE, SLAM_FALL, GEYSER, GAP }

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
	bstate = GState.APPROACH
	_t = tuning.guardian5_attack_gap * 1.4
	Pictogram.show_on(self, &"alarm", 1.0, Vector2(0, -34))


func on_phase_changed(_p: int) -> void:
	if anims != null:
		anims.modulate = Color(0.9, 0.55, 0.4)
	FX.glitch(0.6, 0.5)
	FX.shake(3.0, 0.4)


func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	if not active or not health.is_alive():
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

	match bstate:
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
		w.global_position = global_position + Vector2(d * 12, 8)
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
		_root().add_child(sp)
		# Kul rengi: uyari ve sivri kule boyanir (_ready cocuklari hazir)
		sp.get_node("warn").color = Color(0.7, 0.6, 0.45, 0.55)
		sp.get_node("spike").modulate = Color(0.55, 0.5, 0.45)


func _root() -> Node:
	return arena_root if arena_root != null else get_parent()
