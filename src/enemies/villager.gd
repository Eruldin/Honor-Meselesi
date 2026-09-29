class_name Villager
extends EnemyBase
## Bolum 1 ofkeli koylu: oyuncuyu gordugunde kosar, temas hasari verir.
## Zayif (2 can) — kalabalik hissi icin.

@export var speed_override: float = 0.0

var _player: Node2D


func _init() -> void:
	max_hp = 2
	body_size = Vector2(12, 16)
	contact_damage = true
	asset_key = &"villager"


func _ready() -> void:
	super._ready()
	if not using_real_sprite:
		sprite.modulate = Color(0.85, 0.55, 0.4)


func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	if is_staggered() or not health.is_alive():
		return
	if _player == null:
		_player = get_tree().get_first_node_in_group(&"player")
		return
	var dx: float = _player.global_position.x - global_position.x
	var range: float = tuning.villager_aggro_range
	if absf(dx) < range:
		var sp: float = speed_override if speed_override > 0.0 else tuning.villager_speed
		velocity.x = signf(dx) * sp
	else:
		velocity.x = move_toward(velocity.x, 0.0, 400.0 * delta)
