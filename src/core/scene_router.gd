extends Node
## Sahne gecisleri. Su an basit; CRT kapanma/glitch gecis efektleri
## ileride burada toplanacak.

signal scene_loaded(path: String)

var _is_transitioning := false


func change_scene(path: String) -> void:
	if _is_transitioning:
		return
	_is_transitioning = true
	var err := get_tree().change_scene_to_file(path)
	if err != OK:
		push_error("Scene change failed (%s): %s" % [path, error_string(err)])
		_is_transitioning = false
		return
	await get_tree().process_frame
	_is_transitioning = false
	scene_loaded.emit(path)


func reload() -> void:
	get_tree().reload_current_scene()
