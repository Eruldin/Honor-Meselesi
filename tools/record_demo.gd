extends "res://src/levels/test_room/test_room.gd"
## PR icin oynanis kaydi araci (git repo icine girmez ciktiya yazmaz:
## build/capture/ gitignore'li). AIInputSource ile senaryolu demo surer,
## her 3. frame'i PNG olarak kaydeder; sonra tools/make_gif.py GIF'ler.
##
## Calistir: godot --path . res://tools/RecordDemo.tscn

var _ai: AIInputSource
var _frames_dir := "res://build/capture"
var _capture_count := 0
var _capturing := false


func _ready() -> void:
	super._ready()
	_ai = AIInputSource.new()
	samurai.set_input_source(_ai)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(_frames_dir))
	_run_script()


func _wait(sec: float) -> void:
	await get_tree().create_timer(sec).timeout


func _run_script() -> void:
	await _wait(0.6)
	_capturing = true

	_ai.axis(1.0)              # kos
	await _wait(0.7)
	_ai.axis(0.0)
	await _wait(0.2)

	_ai.tap(&"form_next")      # samurai -> tavuk
	await _wait(0.6)
	_ai.tap(&"form_next")      # tavuk -> robot
	await _wait(0.6)

	_ai.axis(-1.0)             # robotla sola, catlak zemine yuruyus
	await _wait(0.7)
	_ai.axis(0.0)
	await _wait(0.8)           # zemin kirilir

	_ai.tap(&"form_prev")      # robot -> tavuk
	await _wait(0.6)

	_ai.axis(1.0)              # platforma dogru kos
	await _wait(0.7)
	_ai.tap(&"jump")
	_ai.hold(&"jump")          # suzulus
	await _wait(1.1)
	_ai.release(&"jump")
	await _wait(0.4)

	_ai.axis(1.0)              # dar tunelden yuru (sadece tavuk)
	await _wait(1.6)
	_ai.axis(0.0)

	_ai.tap(&"attack")         # kukla onunde kombo
	await _wait(0.2)
	_ai.tap(&"attack")
	await _wait(0.6)

	_capturing = false
	print("capture done: %d frames" % _capture_count)
	get_tree().quit()


func _process(delta: float) -> void:
	super._process(delta)
	if not _capturing:
		return
	_capture_count += 1
	if _capture_count % 3 != 0:
		return
	var img := get_viewport().get_texture().get_image()
	img.resize(480, 270, Image.INTERPOLATE_NEAREST)
	img.save_png("%s/f%04d.png" % [_frames_dir, _capture_count])
