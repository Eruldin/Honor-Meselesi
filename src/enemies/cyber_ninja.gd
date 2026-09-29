class_name CyberNinja
extends EnemyBase
## Bolum 2 siber-hirsiz: cok hizli; TEK vuruslari isinarak atlatir
## (hasar yok) — sadece kombo zincirinin 3. vurusu (combo_index>=3)
## ya da kombo sirasindaki ardisik vurus onu yakalar (DEVIN_PLAN M5).

var _player: Node2D
var _blink_cd := 0.0


func _init() -> void:
	max_hp = 3
	body_size = Vector2(12, 16)
	contact_damage = true


func _ready() -> void:
	super._ready()
	sprite.modulate = Color(0.3, 0.9, 1.0)


func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	if is_staggered() or not health.is_alive():
		return
	_blink_cd = maxf(_blink_cd - delta, 0.0)
	if _player == null:
		_player = get_tree().get_first_node_in_group(&"player")
		return
	var dx: float = _player.global_position.x - global_position.x
	if absf(dx) < 120.0 and absf(dx) > 20.0:
		velocity.x = signf(dx) * tuning.ninja_speed
	else:
		velocity.x = 0.0


## Tek vurus = isinlanip atlati; ancak kombo zincirindeki darbe gecer.
func take_damage(info: DamageInfo) -> void:
	var chained := false
	if info.source != null and "combo_index" in info.source:
		chained = info.source.combo_index >= 3
	if chained or is_staggered():
		super.take_damage(info)
		return
	if _blink_cd <= 0.0:
		_blink_cd = 0.6
		var dir := -signi(int(signf(
			info.source.global_position.x - global_position.x))) \
			if info.source != null else -1
		sprite.modulate = Color(0.3, 0.9, 1.0, 0.3)
		global_position.x += dir * tuning.ninja_blink_dist
		var tw := create_tween()
		tw.tween_property(sprite, "modulate:a", 1.0, 0.15)
