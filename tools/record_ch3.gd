extends "res://src/levels/ch3/ch3.gd"
## M4 PR kaydi: AIInputSource ile senaryolu Bolum 1 turu —
## saga kos, dusmanlari kes, dinlenme noktasi, sovalye formu, arena, boss.
## build/capture_c3/ altina PNG yazar.

var _ai: AIInputSource
var _frames_dir := "res://build/capture_c3"
var _capture_count := 0
var _capturing := false


func _ready() -> void:
	auto_advance = false
	super._ready()
	_ai = AIInputSource.new()
	samurai.set_input_source(_ai)
	# Oyuncu olurse sahne reloadu kayit betigini oldurur; kaydi sag tut.
	samurai.health.max_health = 99
	samurai.health.reset()
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

	await _walk_to(320)
	await _fight()          # hayalet (kivilcim gerekir — parry ile aciga cikar)
	_ai.tap(&"parry")
	await _wait(0.4)
	await _fight()
	await _walk_to(500)
	_ai.tap(&"parry")       # kivilcim -> hayaletler gorunur
	await _wait(0.3)
	await _fight()
	await _walk_to(680)
	await _fight()          # vampir blink-in/strike
	await _fight()
	await _walk_to(440)     # geri: kurtadam duvari bolgesi
	await _wait(0.6)
	_ai.tap(&"dash")
	await _walk_to(980)
	await _wait(0.8)        # dinlenme noktasi
	await _walk_to(1195)    # arena tetigi
	await _wait(0.8)
	for i in 4:
		await _fight()
		_ai.tap(&"parry")   # lunge parry denemesi
		await _wait(0.5)
	await _wait(1.5)        # faz 2 karanlik + gozler

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
