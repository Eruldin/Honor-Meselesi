class_name RedTyrant
extends BossBase
## Bolum 4 boss'u — Kizil Tulumlu Tiran.
## F1: yaklasma + yer kaldirma (pound) + YERCEKIMI CEVIRME.
## F2 (can <= %50): ekstra ekran-disi PIKSEL YAGMURU + daha hizli.
## Olum -> "GAME OVER" retro yazisi (seviye HUD'i cizer) + Piksel Sicramasi
## kalici yetenegi (GameState flag: cift ziplama + blok kirma).

enum State { SLEEP, APPROACH, TELL, POUND_RISE, POUND_FALL, RAIN, GAP }

var bstate := State.SLEEP
var _t := 0.0
var _player: Node2D
var facing := -1
var _atk_idx := 0
var _flip_timer := 0.0
var _rain: PixelRain
var arena_root: Node2D
var arena_left := 0.0
var arena_right := 0.0


func _init() -> void:
	max_hp = 18
	body_size = Vector2(16, 22)
	contact_damage = true
	asset_key = &"tyrant"
	phase_thresholds = [0.5]


func _ready() -> void:
	super._ready()
	if not using_real_sprite:
		sprite.modulate = Color(0.85, 0.2, 0.2)
	contact_hitbox.activate(DamageInfo.make(1, self, Vector2.ZERO, true, true))
	_rain = PixelRain.new()
	if get_parent() != null:
		get_parent().add_child(_rain)


func _exit_tree() -> void:
	_restore_gravity()
	if is_instance_valid(_rain):
		_rain.queue_free()


func on_activated() -> void:
	bstate = State.APPROACH
	_t = tuning.tyrant_attack_gap * 1.2
	_rain.area_left = arena_left
	_rain.area_right = arena_right
	Pictogram.show_on(self, &"alarm", 1.0, Vector2(0, -26))


func on_phase_changed(_p: int) -> void:
	sprite.modulate = Color(0.95, 0.35, 0.1)
	FX.glitch(0.8, 0.7)
	FX.shake(3.0, 0.4)


func _restore_gravity() -> void:
	if _player != null and is_instance_valid(_player) \
			and _player.has_method("set_gravity_flipped"):
		_player.set_gravity_flipped(false)
	_flip_timer = 0.0


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
	var speed := tuning.tyrant_p2_speed if phase >= 1 else tuning.tyrant_speed
	var gap := tuning.tyrant_attack_gap_p2 if phase >= 1 else tuning.tyrant_attack_gap

	if _flip_timer > 0.0:
		_flip_timer -= delta
		if _flip_timer <= 0.0:
			_restore_gravity()

	match bstate:
		State.APPROACH:
			velocity.x = facing * speed
			if _t <= 0.0:
				_choose()
		State.TELL:
			velocity.x = 0.0
			sprite.modulate = Color(1.3, 1.3, 0.4)  # sarartma telegraph
			if _t <= 0.0:
				_do_attack()
		State.POUND_RISE:
			velocity.x = 0.0
			velocity.y = -tuning.tyrant_pound_rise
			if _t <= 0.0:
				bstate = State.POUND_FALL
				velocity.y = 0.0
		State.POUND_FALL:
			velocity.y = minf(velocity.y + 1400.0 * delta, 500.0)
			if is_on_floor():
				_land_pound()
				bstate = State.GAP
				_t = gap
		State.RAIN:
			velocity.x = 0.0
			if _t <= 0.0:
				_rain.active = false
				bstate = State.GAP
				_t = gap
		State.GAP:
			velocity.x = move_toward(velocity.x, 0.0, 700.0 * delta)
			if _t <= 0.0:
				bstate = State.APPROACH
				_t = 1.4


func _choose() -> void:
	var pick := _atk_idx % 3 if phase >= 1 else _atk_idx % 2
	_atk_idx += 1
	match pick:
		0:  # pound
			bstate = State.TELL
			_t = tuning.tyrant_telegraph
		1:  # gravity flip
			_start_flip()
		_:  # rain (faz 2)
			bstate = State.RAIN
			_t = 2.2
			_rain.active = true
			FX.glitch(0.5, 0.4)


func _do_attack() -> void:
	# TELL sonrasi tek gercek saldiri: pound
	sprite.modulate = Color(0.85, 0.2, 0.2) if phase == 0 else Color(0.95, 0.35, 0.1)
	bstate = State.POUND_RISE
	_t = 0.45


func _land_pound() -> void:
	FX.shake(3.5, 0.35)
	for d in [-1, 1]:
		var w := Shockwave.new()
		w.direction = d
		w.global_position = global_position + Vector2(d * 10, 8)
		_root().add_child(w)


func _start_flip() -> void:
	# Oyuncunun yercekimini belirli sure terse cevir (arena mekanigi).
	if _player.has_method("set_gravity_flipped"):
		_player.set_gravity_flipped(true)
		_flip_timer = tuning.gravity_flip_time
		FX.glitch(0.6, 0.4)
	bstate = State.GAP
	_t = tuning.tyrant_attack_gap


func _root() -> Node:
	return arena_root if arena_root != null else get_parent()


func _on_died() -> void:
	_restore_gravity()
	GameState.set_flag(&"piksel_sicramasi", true)
	super._on_died()
