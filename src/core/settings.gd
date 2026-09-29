extends Node
## Erisilebilirlik ayarlari (DEVIN_PLAN §4.6): efekt yogunlugu,
## ekran sarsintisi, flas. user://settings.json'a kaydedilir.

signal changed

const PATH := "user://settings.json"

var fx_intensity: float = 0.0      ## CRT/glitch — sadece senaryo anlarinda (glitch_pulse)
var shake_scale: float = 1.0       ## ekran sarsintisi carpani
var flash_scale: float = 1.0       ## flas/kivilcim parlakligi carpani


func _ready() -> void:
	load_settings()


func set_fx_intensity(v: float) -> void:
	fx_intensity = clampf(v, 0.0, 1.0)
	_commit()


func set_shake_scale(v: float) -> void:
	shake_scale = clampf(v, 0.0, 1.0)
	_commit()


func set_flash_scale(v: float) -> void:
	flash_scale = clampf(v, 0.0, 1.0)
	_commit()


func _commit() -> void:
	save_settings()
	changed.emit()


func save_settings() -> void:
	var f := FileAccess.open(PATH, FileAccess.WRITE)
	if f == null:
		return
	f.store_string(JSON.stringify({
		"fx_intensity": fx_intensity,
		"shake_scale": shake_scale,
		"flash_scale": flash_scale,
	}))


func load_settings() -> void:
	if not FileAccess.file_exists(PATH):
		return
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(PATH))
	if not data is Dictionary:
		return
	fx_intensity = float(data.get("fx_intensity", 1.0))
	shake_scale = float(data.get("shake_scale", 1.0))
	flash_scale = float(data.get("flash_scale", 1.0))
	changed.emit()
