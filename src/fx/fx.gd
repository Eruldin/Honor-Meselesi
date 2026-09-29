class_name FX
extends RefCounted
## Tek satirlik efekt API'si (DEVIN_PLAN §4.3). Fiziksel uygulama
## sahnedeki FxListener'a aittir — bu sadece sinyal yayar.


static func hitstop(duration: float) -> void:
	EventBus.hitstop_requested.emit(duration)


static func shake(strength: float, duration: float = 0.2) -> void:
	EventBus.screenshake_requested.emit(strength, duration)


static func spark(at_position: Vector2) -> void:
	EventBus.spark_emitted.emit(at_position)
