extends "res://src/levels/ch1/ch1.gd"
## Ch1 kayit turu: koy -> orman -> magara -> gecit -> torii -> arena.
## AIInputSource ile senaryolu; takilirsa ileri teleport eder.
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


func _fight(n := 2) -> void:
	for i in n:
		_ai.tap(&"attack")
		await _wait(0.4)


func _walk_to(x: float, timeout := 10.0) -> void:
	var t := 0.0
	var last_x := -999.0
	var stuck := 0.0
	while samurai.global_position.x < x and t < timeout:
		if not is_instance_valid(samurai):
			return
		_ai.axis(1.0)
		# Takildiysa ziplayarak kurtulmaya calis
		if absf(samurai.global_position.x - last_x) < 2.0:
			stuck += 0.1
			if stuck > 0.4:
				_ai.tap(&"jump")
				stuck = 0.0
		else:
			stuck = 0.0
		last_x = samurai.global_position.x
		await get_tree().create_timer(0.1).timeout
		t += 0.1
	_ai.axis(0.0)
	if t >= timeout:
		samurai.global_position.x = x  # kayit icin ileri atla


func _run_script() -> void:
	await _wait(0.8)
	_capturing = true

	# A: koy — tabela, kukla, koyluler
	await _walk_to(160)
	await _wait(0.6)        # move tabelasi
	await _walk_to(430)
	await _fight(3)         # kukla + sword tabelasi
	await _walk_to(640)
	await _fight(3)
	await _walk_to(860)
	await _fight(3)
	await _walk_to(1010)
	await _wait(0.8)        # rest: fener + save

	# B: orman — bariyer tirmanisi
	await _walk_to(1200)
	await _fight(2)         # mantarlar
	await _walk_to(1360)
	_ai.tap(&"jump"); await _wait(0.4)
	_ai.axis(1.0); _ai.tap(&"jump"); await _wait(0.35)
	_ai.tap(&"jump"); await _wait(0.5)
	_ai.axis(0.0)
	await _walk_to(1600, 6.0)
	await _fight(2)         # kaplumbaga
	await _walk_to(1950)
	await _fight(3)
	await _walk_to(2250)
	await _wait(0.8)        # rest

	# C: magara — dikenler, hayalet
	await _walk_to(2450)
	await _fight(2)
	await _walk_to(2600)
	_ai.tap(&"jump"); await _wait(0.4)
	_ai.axis(1.0); _ai.tap(&"jump"); await _wait(0.4)
	_ai.tap(&"jump"); await _wait(0.5)
	_ai.axis(0.0)
	await _walk_to(2950, 6.0)
	await _fight(2)         # hayalet (parry/spark'ta gorunur)
	await _walk_to(3250)
	await _fight(2)         # gizli duvar kirilsin

	# D: gecit — muhafizlar, sovalye, kapi
	await _walk_to(3700)
	await _fight(3)
	_ai.tap(&"parry")
	await _wait(0.4)
	await _fight(2)
	await _walk_to(3940)
	await _fight(3)
	await _walk_to(4060)
	await _wait(0.8)        # rest
	await _walk_to(4230)
	await _fight(5)         # sovalye -> kapi acilir
	await _wait(1.0)

	# E: torii -> arena -> boss
	await _walk_to(4590)
	await _wait(1.0)        # duvarlar yukselir
	await _fight(3)
	_ai.tap(&"jump")
	await _wait(0.5)
	await _fight(3)
	await _wait(2.0)        # boss slam + yumurta

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
