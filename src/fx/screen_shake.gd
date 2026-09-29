class_name ScreenShake
extends Camera2D
## Kameraya baglanir; FxListener/EventBus uzerinden tetiklenir.
## Erişilebilirlik: intensity ayar menusunden carpan alacak (M2).

var _strength: float = 0.0
var _time_left: float = 0.0
var _duration: float = 0.0


func shake(strength: float, duration: float) -> void:
	_strength = maxf(_strength, strength)
	_time_left = duration
	_duration = maxf(_duration, duration)


func _process(delta: float) -> void:
	if _time_left <= 0.0:
		offset = Vector2.ZERO
		return
	_time_left -= delta
	var falloff := _time_left / _duration if _duration > 0.0 else 0.0
	offset = Vector2(randf_range(-1, 1), randf_range(-1, 1)) * _strength * falloff
	if _time_left <= 0.0:
		_strength = 0.0
		offset = Vector2.ZERO
