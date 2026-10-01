extends "res://src/levels/ch7/ch7.gd"
## M8 PR kaydi: Kul Diyari turu — saga yuru, kovanlari kes, yarasalardan
## kac, dinlen, arena, Kul Muhafizi. build/capture_c7/ altina PNG yazar.

var _ai: AIInputSource
var _frames_dir := "res://build/capture_c7"
var _capture_count := 0
var _capturing := false


func _ready() -> void:
	auto_advance = false
	_ai = AIInputSource.new()
	super._ready()
	creature.set_input_source(_ai)
	# Yaratik olurse sahne reload'u kayit betigini oldurur; kaydi sag tut.
	creature.health.max_health = 99
	creature.health.reset()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(_frames_dir))
	_run_script()


func _wait(sec: float) -> void:
	await get_tree().create_timer(sec).timeout


func _fight() -> void:
	_ai.tap(&"attack")
	await _wait(0.4)
	_ai.tap(&"attack")
	await _wait(0.4)


func _walk_to(x: float, timeout := 14.0) -> void:
	var t := 0.0
	while creature.global_position.x < x and t < timeout:
		if not is_instance_valid(samurai):
			return
		_ai.axis(1.0)
		await get_tree().create_timer(0.1).timeout
		t += 0.1
	_ai.axis(0.0)


func _run_script() -> void:
	await _wait(0.8)
	_capturing = true
	for i in 14:
		_ai.axis(-1.0 if _ai.flip else 1.0) if false else _ai.axis(1.0)
		await _wait(0.25)
		_ai.axis(0.0)
		_ai.tap(&"attack")
		await _wait(0.45)
		if i % 4 == 2:
			_ai.tap(&"dash")
		if i % 5 == 4:
			_ai.tap(&"jump")
		await _wait(0.4)
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
