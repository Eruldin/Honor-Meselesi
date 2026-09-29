extends "res://src/levels/ch2/ch2.gd"
## M5 PR kaydi: AIInputSource ile Bolum 2 turu — ninja, terminal hack
## (drone formu), lazer kapi, koruma, Unit-0 arena.
## build/capture_c2/ altina PNG yazar.

var _ai: AIInputSource
var _frames_dir := "res://build/capture_c2"
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
	_ai.tap(&"attack")
	await _wait(0.35)


func _walk_to(x: float, timeout := 10.0) -> void:
	var t := 0.0
	while is_instance_valid(samurai) and samurai.global_position.x < x and t < timeout:
		_ai.axis(1.0)
		await get_tree().create_timer(0.1).timeout
		t += 0.1
	_ai.axis(0.0)


func _run_script() -> void:
	await _wait(0.8)
	_capturing = true

	await _walk_to(360)
	for i in 4:
		await _fight()          # ninja — tek vuruslar isinaltilir, kombo isler
	await _walk_to(560)
	_ai.tap(&"jump")
	await _wait(0.6)          # drone menzili
	await _walk_to(770)

	# Drone formuna gec, terminal hackle (gate acilir)
	_ai.tap(&"form_next")
	await _wait(0.7)
	await _wait(2.0)          # hack suresi
	await _walk_to(940)
	_ai.tap(&"form_next")     # samuraya don (drone -> siradaki)
	await _wait(0.7)
	await _fight()            # ninja 2
	await _walk_to(1100)
	await _wait(1.0)          # dinlenme
	await _walk_to(1180)
	for i in 3:
		await _fight()        # koruma — govde bloklari + pil
	_ai.tap(&"jump")
	await _wait(0.4)
	await _fight()

	await _walk_to(1315)      # arena
	await _wait(0.6)
	for i in 3:
		await _fight()
		_ai.tap(&"parry")     # yumruk parry denemesi
		await _wait(0.4)
	await _wait(2.0)

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
