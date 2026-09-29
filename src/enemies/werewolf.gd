class_name Werewolf
extends EnemyBase
## Bolum 3 kurtadam: duvarlara tutunur, duvarlar arasi ziplayarak
## oyuncuya atilir. Saldiri PARRY'LENEMEZ — kirmizi goz telegraph
## (DEVIN_PLAN M6: gorsel zorunlu telegraph).

enum WState { CLING, TELEGRAPH, LEAP, RECOVER }

var wstate := WState.CLING
var _t := 0.0
var _player: Node2D
var leap_hitbox: Hitbox


func _init() -> void:
	max_hp = 3
	body_size = Vector2(16, 18)


func _ready() -> void:
	super._ready()
	sprite.modulate = Color(0.5, 0.35, 0.3)
	leap_hitbox = Hitbox.new()
	leap_hitbox.collision_layer = 32
	leap_hitbox.collision_mask = 4
	var col := CollisionShape2D.new()
	var r := RectangleShape2D.new()
	r.size = body_size + Vector2(4, 4)
	col.shape = r
	leap_hitbox.add_child(col)
	add_child(leap_hitbox)
	leap_hitbox.deactivate()
	_t = 1.0


func _physics_process(delta: float) -> void:
	# Yercekimi: sadece LEAP/RECOVER'da (duvarda tutunurken yok)
	if wstate in [WState.LEAP, WState.RECOVER]:
		velocity.y = minf(velocity.y + 800.0 * delta, 320.0)
	else:
		velocity.y = 0.0
	stagger_timer = maxf(stagger_timer - delta, 0.0)
	move_and_slide()
	if not health.is_alive() or is_staggered():
		return
	if _player == null:
		_player = get_tree().get_first_node_in_group(&"player")
		return
	_t -= delta
	match wstate:
		WState.CLING:
			velocity.x = 0.0
			if _t <= 0.0 and absf(_player.global_position.x - global_position.x) < 200.0:
				wstate = WState.TELEGRAPH
				_t = tuning.werewolf_telegraph
				sprite.modulate = Color(1.3, 0.3, 0.3)  # kirmizi goz telegraph
		WState.TELEGRAPH:
			if _t <= 0.0:
				wstate = WState.LEAP
				sprite.modulate = Color(0.5, 0.35, 0.3)
				# Oyuncuya dogru atil — PARRY'LENEMEZ vurus
				var dir: Vector2 = (_player.global_position - global_position).normalized()
				velocity = dir * tuning.werewolf_jump_speed
				leap_hitbox.activate(DamageInfo.make(1, self,
					Vector2(dir.x * 160, -40), false, false))
		WState.LEAP:
			if is_on_floor() or is_on_wall():
				leap_hitbox.deactivate()
				wstate = WState.RECOVER
				_t = 0.9
		WState.RECOVER:
			velocity.x = move_toward(velocity.x, 0.0, 500.0 * delta)
			if _t <= 0.0:
				wstate = WState.CLING
				_t = 1.2
