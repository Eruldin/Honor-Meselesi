class_name AmbientDrip
extends Node2D
## Magara/mahzen damlasi: rastgele araliklarla pozisyonel su damla sesi.
## Kaynak nokta her calmada biraz gezinir — tek noktadan mekanik
## tikirti yerine yasayan yanki.

@export var min_gap := 3.5
@export var max_gap := 7.5
@export var wander := 42.0

var _t := 0.0


func _ready() -> void:
	_t = randf_range(min_gap, max_gap)


func _process(delta: float) -> void:
	_t -= delta
	if _t > 0.0:
		return
	_t = randf_range(min_gap, max_gap)
	var pos := global_position + Vector2(
		randf_range(-wander, wander), randf_range(-10.0, 10.0))
	AudioManager.play_sfx(&"sfx/drip", pos,
		randf_range(-12.0, -8.0), randf_range(0.85, 1.15))
