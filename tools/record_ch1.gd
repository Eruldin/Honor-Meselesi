extends "res://src/levels/ch1/ch1.gd"
## M4 PR kaydi: AIInputSource ile senaryolu Bolum 1 turu —
## saga kos, dusmanlari kes, dinlenme noktasi, sovalye formu, arena, boss.
## build/capture_c1/ altina PNG yazar.

var _ai: AIInputSource
var _frames_dir := "res://build/capture_c1"
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
	# Yakindaki bir seye dogru kombo — basit spam
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

	await _walk_to(330)
	await _fight()          # koylu 1
	await _wait(0.3)
	await _fight()
	await _walk_to(490)
	await _fight()          # koylu 2
	await _fight()

	await _walk_to(660)
	await _fight()          # muhafiz — kalkan bloklari gorunur
	await _fight()
	_ai.tap(&"jump")        # arkaya atlamak icin ziplayip
	await _wait(0.4)
	await _fight()

	await _walk_to(820)     # dinlenme noktasi (save + heal + pikto)
	await _wait(1.0)

	await _walk_to(975)
	await _fight()          # agir sovalye -> Sovalye formu duser
	await _fight()
	await _fight()
	await _wait(1.2)        # donusum animasyonu gorunsun

	await _walk_to(1200)    # arena tetigi — duvarlar + boss aktif
	await _wait(0.8)
	await _fight()          # boss'a ilk vuruslar
	await _fight()
	_ai.tap(&"jump")
	await _wait(0.5)
	await _fight()
	await _wait(2.5)        # boss slam + yumurtalar gorunsun
	await _fight()

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
