class_name CrackedGround
extends StaticBody2D
## Catlak zemin: Robot formu ustune basinca kirilir (DEVIN_PLAN M2
## kabul kriteri). Ustunde duran Area2D tetikleyici oyuncu govdesini
## (layer 2) dinler.

@export var size: Vector2 = Vector2(56, 6)

var broken := false
var _sprite: Sprite2D
var _col: CollisionShape2D


func _ready() -> void:
	collision_layer = 1
	collision_mask = 0

	_col = CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = size
	_col.shape = rect
	add_child(_col)

	_sprite = Sprite2D.new()
	_sprite.texture = AssetLoader.placeholder_texture("terrain/cracked", Vector2i(size))
	_sprite.modulate = Color(0.5, 0.42, 0.35)
	add_child(_sprite)

	var watcher := Area2D.new()
	watcher.collision_layer = 0
	watcher.collision_mask = 2  # oyuncu govdesi
	var w_col := CollisionShape2D.new()
	var w_rect := RectangleShape2D.new()
	w_rect.size = Vector2(size.x, 10)
	w_col.shape = w_rect
	w_col.position = Vector2(0, -size.y / 2.0 - 4.0)
	watcher.add_child(w_col)
	watcher.body_entered.connect(_on_body_entered)
	add_child(watcher)


func _on_body_entered(body: Node) -> void:
	if broken or not body is Samurai:
		return
	var sam := body as Samurai
	if sam.form != null and sam.form.can_break_ground:
		break_apart()


func break_apart() -> void:
	broken = true
	_col.set_deferred("disabled", true)
	FX.shake(2.0, 0.15)
	var tw := create_tween()
	tw.tween_property(_sprite, "scale", Vector2(1.0, 0.1), 0.18)
	tw.parallel().tween_property(_sprite, "modulate:a", 0.0, 0.25)
	tw.finished.connect(queue_free)
