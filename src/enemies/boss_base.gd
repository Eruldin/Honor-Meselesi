class_name BossBase
extends EnemyBase
## Boss tabani (DEVIN_PLAN M4: faz sistemi burada kurulur).
## phase_thresholds: can yuzdesi esikleri; her esik asilinca phase++ ve
## phase_changed/on_phase_changed calisir. active=false iken hasar almaz
## (arena tetiklenmeden once "uyku").

signal phase_changed(new_phase: int)
signal defeated

## HP yuzdesi esikleri (or. [0.5] -> 2 faz).
@export var phase_thresholds: Array[float] = [0.5]
## Arena tetiklendi mi — tetiklenmeden hasar almaz, davranmaz.
var active := false
var phase := 0


func activate() -> void:
	active = true
	on_activated()


func on_activated() -> void:
	pass


func on_phase_changed(_new_phase: int) -> void:
	pass


func take_damage(info: DamageInfo) -> void:
	if not active or not health.is_alive():
		return
	super.take_damage(info)
	var frac := float(health.current) / maxf(health.max_health, 1)
	while phase < phase_thresholds.size() and frac <= phase_thresholds[phase]:
		phase += 1
		phase_changed.emit(phase)
		on_phase_changed(phase)


func _on_died() -> void:
	defeated.emit()
	super._on_died()
