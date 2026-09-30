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


## PostFX glitch kanalini gecici olarak acar (prolog sinematikleri, boss girisleri).
## Gorsel pulse'a beyaz gurultu burst'u eslik eder — sessiz glitch yok.
static func glitch(strength: float, duration: float = 0.6) -> void:
	EventBus.glitch_requested.emit(strength, duration)
	var db := lerpf(-14.0, -4.0, clampf(strength, 0.0, 1.5) / 1.5)
	AudioManager.play_sfx(&"sfx/glitch", null, db, randf_range(0.9, 1.15))
