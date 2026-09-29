class_name Vampire
extends EnemyBase
## Bolum 3 vampir: oyuncunun yanina isinlanir, isirir (kanama DoT
## birakir), sonra uzaklasir (DEVIN_PLAN M6).

enum VState { IDLE, BLINK_IN, STRIKE, BLINK_OUT }

var vstate := VState.IDLE
var _t := 0.0
var _player: Node2D


func _init() -> void:
	max_hp = 3
	body_size = Vector2(13, 18)


func _ready() -> void:
	super._ready()
	sprite.modulate = Color(0.7, 0.3, 0.5)
	_t = tuning.vampire_blink_cd * 0.5


func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	if not health.is_alive() or is_staggered():
		return
	if _player == null:
		_player = get_tree().get_first_node_in_group(&"player")
		return
	_t -= delta
	match vstate:
		VState.IDLE:
			velocity.x = 0.0
			if _t <= 0.0:
				vstate = VState.BLINK_IN
				sprite.modulate.a = 0.25
				_t = 0.3
		VState.BLINK_IN:
			if _t <= 0.0:
				# Oyuncunun arkasina isinlan
				var dir := -signf(_player.velocity.x) if absf(_player.velocity.x) > 1.0 else -1.0
				global_position = _player.global_position + Vector2(dir * 24.0, 0)
				sprite.modulate.a = 1.0
				vstate = VState.STRIKE
				_t = 0.45
		VState.STRIKE:
			if _t <= 0.0:
				_strike()
				vstate = VState.BLINK_OUT
				_t = 0.4
		VState.BLINK_OUT:
			if _t <= 0.0:
				global_position.x += signf(global_position.x - _player.global_position.x) * 80.0
				sprite.modulate.a = 1.0
				vstate = VState.IDLE
				_t = tuning.vampire_blink_cd


func _strike() -> void:
	var dx: float = _player.global_position.x - global_position.x
	if absf(dx) < 30.0 and _player.has_method("apply_bleed"):
		_player.take_damage(DamageInfo.make(0, self, Vector2.ZERO, true, false))
		_player.apply_bleed(tuning.vampire_bleed_ticks, tuning.vampire_bleed_interval)
		Pictogram.show_on(_player, &"alarm", 0.8, Vector2(0, -30))
