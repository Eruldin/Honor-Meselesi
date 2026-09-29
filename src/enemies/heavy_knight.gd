class_name HeavyKnight
extends EnemyBase
## Bolum 1 agir sovalye: yavas, sert temas hasari (2). Ilk sovalye
## oldurulunce gecici Sovalye formunu dusurur (DEVIN_PLAN M4/form tablosu).

## Oldurunce bu form acilir ("" = dusurmez).
@export var grants_form: StringName = &""
## Oldurunce oyuncuya otomatik takilsin mi.
@export var auto_equip := true

var _player: Node2D


func _init() -> void:
	max_hp = 6
	body_size = Vector2(18, 24)
	contact_damage = true
	asset_key = &"heavy_knight"


func _ready() -> void:
	super._ready()
	if not using_real_sprite:
		sprite.modulate = Color(0.6, 0.6, 0.75)
	# Agir temas = 2 hasar
	contact_hitbox.activate(DamageInfo.make(2, self, Vector2.ZERO, true, true))


func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	if is_staggered() or not health.is_alive():
		return
	if _player == null:
		_player = get_tree().get_first_node_in_group(&"player")
		return
	var dx: float = _player.global_position.x - global_position.x
	if absf(dx) < 140.0:
		velocity.x = signf(dx) * tuning.knight_speed


func _on_died() -> void:
	if grants_form != &"":
		GameState.unlock_form(grants_form)
		if auto_equip:
			var p := get_tree().get_first_node_in_group(&"player")
			if p != null and p.has_method("equip_form"):
				p.equip_form(grants_form)
	super._on_died()
