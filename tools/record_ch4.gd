extends "res://src/levels/ch4/ch4.gd"
## M7 PR kaydi: AIInputSource ile senaryolu Bolum 4 turu —
## retro platform, mantar/kaplumbaga, bloklar, arena, Tiran.
## build/capture_c4/ altina PNG yazar.

var _ai: AIInputSource
var _frames_dir := "res://build/capture_c4"
var _capture_count := 0
var _capturing := false


func _ready() -> void:
	auto_advance = false
	super._ready()
	_ai = AIInputSource.new()
	samurai.set_input_source(_ai)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(_frames_dir))
	_run_script()


func _wait(sec: float) -> void:
	await get_tree().create_timer(sec).timeout


func _fight() -> void:
	_ai.tap(&"attack")
	await _wait(0.35)
	_ai.tap(&"attack")
	await _wait(0.35)


func _walk_to(x: float, timeout := 8.0) -> void:
	var t := 0.0
	while samurai.global_position.x < x and t < timeout:
		if not is_instance_valid(samurai):
			return
		_ai.axis(1.0)
		await get_tree().create_timer(0.1).timeout
		t += 0.1
	_ai.axis(0.0)


func _run_script() -> void:
	await _wait(0.8)
	_capturing = true

	await _walk_to(280)
	await _fight()          # mantar -> bolunur
	await _fight()          # miniler
	await _walk_to(420)
	await _fight()          # blok kirma
	await _walk_to(500)
	await _fight()          # kaplumbaga -> kabuk seker
	await _wait(0.5)
	_ai.tap(&"jump")
	await _walk_to(640)
	await _wait(0.6)        # boru + ates cicegi
	await _walk_to(900)
	await _fight()
	await _walk_to(1050)
	await _wait(0.6)        # dinlenme noktasi
	await _walk_to(1195)    # arena tetigi
	await _wait(0.8)
	for i in 4:
		await _fight()
		await _wait(0.6)    # pound/flip/rain gozle
	await _wait(1.5)

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
