class_name Hellcat
extends EnemyBase
## Bolum 1 cehennem kedisi: hizli devriye; oyuncuyu gorunce hizlanir.
## Cehennem temali mezarlik bolgesi icin. Temas hasari.

@export var patrol_range := 90.0

var _home_x: float
var _dir := 1.0
var _player: Node2D


func _init() -> void:
	max_hp = 1
	body_size = Vector2(14, 10)
	asset_key = &"hellcat"
	contact_damage = true


func _ready() -> void:
	super._ready()
	_home_x = position.x


func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	if is_staggered() or not health.is_alive():
		return
	if _player == null:
		_player = get_tree().get_first_node_in_group(&"player")
		return
	var dx: float = _player.global_position.x - global_position.x
	# Oyuncu menzildeyse uzerine kos; degilse devriye gez
	if absf(dx) < tuning.villager_aggro_range * 1.2 \
			and absf(_player.global_position.y - global_position.y) < 50.0:
		velocity.x = signf(dx) * tuning.villager_speed * 1.7
		sprite.flip_h = dx < 0.0
	else:
		velocity.x = _dir * tuning.villager_speed * 1.1
		sprite.flip_h = _dir < 0.0
		if position.x > _home_x + patrol_range:
			_dir = -1.0
		elif position.x < _home_x - patrol_range:
			_dir = 1.0
