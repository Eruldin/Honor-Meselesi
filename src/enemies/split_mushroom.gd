class_name SplitMushroom
extends EnemyBase
## Bolum 4 mantar: kesilince ikiye bolunur — iki kucuk mantar firlar.
## mini=true kucuk boy (bolunmez devam).

@export var mini := false

var _player: Node2D


func _init() -> void:
	max_hp = 2
	body_size = Vector2(14, 14)
	contact_damage = true


func _ready() -> void:
	if mini:
		max_hp = 1
		body_size = Vector2(9, 9)
	asset_key = &"mushroom_mini" if mini else &"mushroom"
	super._ready()
	if not using_real_sprite:
		sprite.modulate = Color(0.9, 0.4, 0.4)


func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	if is_staggered() or not health.is_alive():
		return
	if _player == null:
		_player = get_tree().get_first_node_in_group(&"player")
		return
	var dx: float = _player.global_position.x - global_position.x
	if absf(dx) < 130.0:
		velocity.x = signf(dx) * tuning.mushroom_speed


func _on_died() -> void:
	if not mini:
		for dir in [-1, 1]:
			var m := SplitMushroom.new()
			m.mini = true
			m.global_position = global_position + Vector2(dir * 8, -4)
			m.velocity = Vector2(dir * 60, -120)
			get_parent().call_deferred("add_child", m)
	super._on_died()
