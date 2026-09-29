extends Node
## Erisilebilirlik ayarlari (DEVIN_PLAN §4.6): efekt yogunlugu,
## ekran sarsintisi, flas. user://settings.json'a kaydedilir.

signal changed

const PATH := "user://settings.json"

var fx_intensity: float = 0.0      ## CRT/glitch — sadece senaryo anlarinda (glitch_pulse)
var shake_scale: float = 1.0       ## ekran sarsintisi carpani
var flash_scale: float = 1.0       ## flas/kivilcim parlakligi carpani
var music_volume: float = 1.0      ## muzik bus seviyesi (0-1)
var sfx_volume: float = 1.0        ## sfx bus seviyesi (0-1)


func _apply_bus_volume() -> void:
	for spec in [[&"Music", music_volume], [&"SFX", sfx_volume]]:
		var idx := AudioServer.get_bus_index(spec[0])
		if idx >= 0:
			AudioServer.set_bus_volume_db(idx, linear_to_db(maxf(spec[1], 0.001)) if spec[1] > 0.0 else -80.0)


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


func set_music_volume(v: float) -> void:
	music_volume = clampf(v, 0.0, 1.0)
	_apply_bus_volume()
	_commit()


func set_sfx_volume(v: float) -> void:
	sfx_volume = clampf(v, 0.0, 1.0)
	_apply_bus_volume()
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
		"music_volume": music_volume,
		"sfx_volume": sfx_volume,
	}))


func load_settings() -> void:
	if not FileAccess.file_exists(PATH):
		return
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(PATH))
	if not data is Dictionary:
		return
	fx_intensity = float(data.get("fx_intensity", 0.0))
	shake_scale = float(data.get("shake_scale", 1.0))
	flash_scale = float(data.get("flash_scale", 1.0))
	music_volume = float(data.get("music_volume", 1.0))
	sfx_volume = float(data.get("sfx_volume", 1.0))
	_apply_bus_volume()
	changed.emit()
