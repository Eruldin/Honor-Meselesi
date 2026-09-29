class_name DroneEnemy
extends EnemyBase
## Bolum 2 ucus dusmani: zeminden yuksekte sine ile suzulur, asagiya
## parrylenebilir mermi atar. Pogo ya da Tavuk formu ile ulasilir.

var _player: Node2D
var _fire_timer := 0.0
var _hover_t := 0.0
var _base_y := 0.0


func _init() -> void:
	max_hp = 1
	body_size = Vector2(14, 10)


func _ready() -> void:
	super._ready()
	sprite.modulate = Color(0.9, 0.5, 0.95)
	_base_y = position.y


func _physics_process(delta: float) -> void:
	# Yercekimini atla: super cagirilmaz — ucan dusman.
	stagger_timer = maxf(stagger_timer - delta, 0.0)
	move_and_slide()
	if not health.is_alive() or is_staggered():
		return
	_hover_t += delta
	position.y = _base_y + sin(_hover_t * 2.4) * 5.0
	_fire_timer -= delta
	if _fire_timer <= 0.0:
		_fire_timer = tuning.drone_fire_interval
		_fire_down()


func _fire_down() -> void:
	var p := Projectile.new()
	p.vertical = true
	p.global_position = global_position + Vector2(0, 8)
	get_parent().add_child(p)
