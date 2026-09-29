class_name Health
extends Node
## Basit can bileseni. damage/death mantigi burada;
## invulnerable penceresi sahip tarafinda yonetilir.

signal damaged(amount: int, remaining: int)
signal died
signal healed(amount: int, current: int)

@export var max_health: int = 5

var current: int:
	get: return _current
var _current: int = 0


func _ready() -> void:
	_current = max_health


func take(amount: int) -> void:
	if _current <= 0:
		return
	_current = maxi(_current - amount, 0)
	damaged.emit(amount, _current)
	if _current <= 0:
		died.emit()


func heal(amount: int) -> void:
	_current = mini(_current + amount, max_health)
	healed.emit(amount, _current)


func reset() -> void:
	_current = max_health


func is_alive() -> bool:
	return _current > 0
