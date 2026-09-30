class_name PixelRain
extends Node2D
## Kizil Tulumlu Tiran ekran disi saldirisi: yukaridan dusen pikseller.

var _t := 0.0
var area_left := 0.0
var area_right := 0.0
var active := false


func _physics_process(delta: float) -> void:
	if not active:
		return
	_t -= delta
	if _t <= 0.0:
		_t = load("res://config/tuning.tres").pixel_rain_interval
		var px := PixelDrop.new()
		px.global_position = Vector2(randf_range(area_left, area_right), -24)
		add_child(px)


class PixelDrop:
	extends Area2D
	## Dusen tek piksel — hizli, kucuk, parry'lenebilir degil.
	var _vel := Vector2(0, 300)

	func _ready() -> void:
		collision_layer = 32
		collision_mask = 4
		var col := CollisionShape2D.new()
		var r := RectangleShape2D.new()
		r.size = Vector2(4, 4)
		col.shape = r
		add_child(col)
		var spr := Sprite2D.new()
		spr.texture = AssetLoader.texture(&"fx/pixel", Vector2i(4, 4))
		spr.modulate = Color(0.9, 0.9, 0.2)
		add_child(spr)
		area_entered.connect(_on_hit)

	func _physics_process(delta: float) -> void:
		position += _vel * delta
		if position.y > 400.0:
			queue_free()

	func _on_hit(a: Area2D) -> void:
		var tgt: Node = a.get_parent()
		if tgt != null and tgt.has_method("take_damage"):
			tgt.take_damage(DamageInfo.make(1, self, Vector2(0, 100), false, false))
		queue_free()
