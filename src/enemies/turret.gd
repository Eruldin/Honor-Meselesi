class_name Turret
extends EnemyBase
## Parry testi icin sabit kule: duzenli araliklarla parryable mermi atar.

@export var fire_interval: float = 1.8
@export var projectile_speed: float = 110.0
@export var fire_direction: int = -1

var _fire_timer: float = 0.0


func _init() -> void:
	max_hp = 4
	body_size = Vector2(14, 20)


func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	if is_staggered():
		return
	_fire_timer -= delta
	if _fire_timer <= 0.0:
		_fire_timer = fire_interval
		_fire()


func _fire() -> void:
	var p := Projectile.new()
	p.direction = fire_direction
	p.speed = projectile_speed
	p.global_position = global_position + Vector2(fire_direction * 10.0, -4.0)
	get_parent().add_child(p)
