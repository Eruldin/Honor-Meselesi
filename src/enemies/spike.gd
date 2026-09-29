class_name Spike
extends StaticBody2D
## Pogo yapilabilir diken: ustune inen DownAttack oyuncuyu sektirir
## (hurtbox.pogoable=true); temas eden oyuncu hasar alir.

@export var size: Vector2 = Vector2(24, 10)


func _ready() -> void:
	collision_layer = 1
	collision_mask = 0

	var col := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = size
	col.shape = rect
	add_child(col)

	var sprite := Sprite2D.new()
	sprite.texture = AssetLoader.placeholder_texture("hazard/spike", Vector2i(size))
	sprite.modulate = Color(0.85, 0.2, 0.3)
	add_child(sprite)

	# Hurtbox/hitbox govdeden 3px yukari tasar: oyuncu down-saldirisi
	# temas hasarindan once pogo'yu yakalar (yarissa vurus kazanir).
	var hurtbox := Hurtbox.new()
	hurtbox.pogoable = true
	hurtbox.collision_layer = 16
	hurtbox.collision_mask = 8
	var hb_col := CollisionShape2D.new()
	var hb_rect := RectangleShape2D.new()
	hb_rect.size = size + Vector2(0, 6)
	hb_col.shape = hb_rect
	hb_col.position = Vector2(0, -3)
	hurtbox.add_child(hb_col)
	add_child(hurtbox)

	var hitbox := Hitbox.new()
	hitbox.collision_layer = 32
	hitbox.collision_mask = 4  # player hurtbox
	var hx_col := CollisionShape2D.new()
	var hx_rect := RectangleShape2D.new()
	hx_rect.size = size + Vector2(0, 6)
	hx_col.shape = hx_rect
	hx_col.position = Vector2(0, -3)
	hitbox.add_child(hx_col)
	add_child(hitbox)
	hitbox.activate(DamageInfo.make(1, self, Vector2(0, -80), true, true))


## Hitbox vurabilmesi icin take_damage sarti; diken zarar gormez.
func take_damage(_info: DamageInfo) -> void:
	pass
