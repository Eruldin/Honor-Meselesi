class_name BreakableBlock
extends StaticBody2D
## Bolum 4 kirilabilir blok: oyuncu vurusu (ya da Piksel Sicramasi
## yetenegi) ile kirilir; kirilinca kalinti birakmaz.

@export var size := Vector2(16, 16)


func _ready() -> void:
	collision_layer = 1
	collision_mask = 0
	var col := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = size
	col.shape = rect
	add_child(col)
	var sprite := Sprite2D.new()
	sprite.texture = AssetLoader.texture(&"terrain/block", Vector2i(size))
	sprite.modulate = Color(0.8, 0.55, 0.3)
	add_child(sprite)

	var hurtbox := Hurtbox.new()
	hurtbox.collision_layer = 16
	hurtbox.collision_mask = 8
	hurtbox.pogoable = false
	var hb := CollisionShape2D.new()
	var hr := RectangleShape2D.new()
	hr.size = size
	hb.shape = hr
	hurtbox.add_child(hb)
	add_child(hurtbox)


func take_damage(_info: DamageInfo) -> void:
	FX.shake(0.8, 0.1)
	var tw := create_tween()
	tw.tween_property(self, "scale", Vector2(1.3, 0.4), 0.08)
	tw.parallel().tween_property(self, "modulate:a", 0.0, 0.08)
	tw.finished.connect(queue_free)
