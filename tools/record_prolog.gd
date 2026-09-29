extends "res://src/levels/prolog/prolog.gd"
## M3 PR icin prolog kaydi. AIInputSource CRT mini-oyununda ziplar;
## cutscene kendiliginden akar. build/capture/ altina PNG yazar.
##
## Calistir: godot --path . res://tools/RecordProlog.tscn

var _ai: AIInputSource
var _frames_dir := "res://build/capture_p"
var _capture_count := 0
var _capturing := false


func _ready() -> void:
	fast_mode = true
	auto_advance = false
	super._ready()
	_ai = AIInputSource.new()
	crt_game.input.queue_free()
	crt_game.input = _ai
	crt_game.add_child(_ai)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(_frames_dir))
	EventBus.cutscene_finished.connect(_on_done, CONNECT_ONE_SHOT)
	_run_script()


func _run_script() -> void:
	await get_tree().create_timer(1.4).timeout
	_capturing = true
	# Mini oyun: periyodik zipla (engeller rastgele — bir kaci carpar, sorun degil)
	while _phase == &"play":
		_ai.tap(&"jump")
		await get_tree().create_timer(0.55).timeout
	# Cutscene sona erene dek capture surer
	while _phase == &"cutscene":
		await get_tree().create_timer(0.2).timeout


func _on_done(_id: StringName) -> void:
	await get_tree().create_timer(0.8).timeout
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
