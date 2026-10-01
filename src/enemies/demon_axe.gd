class_name DemonAxe
extends Villager
## Imp Axe Demon (SanctumPixel): gecit bolgesi orta-agirlik dusmani —
## koyluden daha dayanikli ve buyuk. Orta menzilden sicrayip ustune gelir.

var _leap_t := 1.0
var _leaping := false
var _leap_dir := 0.0


func _init() -> void:
	super._init()
	max_hp = 5
	body_size = Vector2(18, 20)
	asset_key = &"demon_axe"
	speed_override = 34.0


func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	if is_staggered() or not health.is_alive() or not _noticed \
			or _player == null:
		return
	if _leaping:
		if is_on_floor():
			_leaping = false
		else:
			velocity.x = _leap_dir * 95.0  # havada koylu hizi ezmesin
	_leap_t -= delta
	if is_on_floor() and _leap_t <= 0.0:
		var dx: float = _player.global_position.x - global_position.x
		var dy: float = _player.global_position.y - global_position.y
		if absf(dx) > 55.0 and absf(dx) < 150.0 and absf(dy) < 24.0:
			_leap_t = 2.6
			_leaping = true
			_leap_dir = signf(dx)
			velocity.y = -155.0
			velocity.x = _leap_dir * 95.0
			play_anim(&"jump", 0.6)
