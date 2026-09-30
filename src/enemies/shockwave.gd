class_name Shockwave
extends Node2D
## Lord Cluck yer-sarsma dalgasi: zeminde yatay kayan dusuk hitbox.
## Parry'lenebilir (kirmizi degil) — plan M4.

@export var direction: int = 1

var hitbox: Hitbox
var _travelled := 0.0
var _tuning: Tuning


func _ready() -> void:
	_tuning = load("res://config/tuning.tres")
	var sprite := Sprite2D.new()
	sprite.texture = AssetLoader.texture(&"fx/shockwave", Vector2i(8, 6))
	sprite.modulate = Color(0.9, 0.7, 0.3)
	add_child(sprite)

	hitbox = Hitbox.new()
	hitbox.collision_layer = 32
	hitbox.collision_mask = 4
	var col := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(8, 8)
	col.shape = rect
	hitbox.add_child(col)
	add_child(hitbox)
	hitbox.activate(DamageInfo.make(1, self, Vector2(direction * 100, -60), true, true))


func _physics_process(delta: float) -> void:
	var t := _tuning
	var step := t.shockwave_speed * delta
	position.x += direction * step
	_travelled += step
	if _travelled >= t.shockwave_range:
		queue_free()
