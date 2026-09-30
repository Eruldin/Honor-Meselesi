extends Node
## Sahne gecisleri + kalici karartma katmani.
## change_scene: karart -> sahne degistir -> ac. Bolumlerin olum/respawn
## akislari da fade_to() ile ayni katmani kullanir.

signal scene_loaded(path: String)

var _is_transitioning := false
var _fade_rect: ColorRect


func _ready() -> void:
	EventBus.scene_change_requested.connect(change_scene)
	var layer := CanvasLayer.new()
	layer.layer = 120
	_fade_rect = ColorRect.new()
	_fade_rect.color = Color.BLACK
	_fade_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fade_rect.modulate.a = 0.0
	layer.add_child(_fade_rect)
	add_child(layer)


## Karartma alfasini duration'da hedefe tween'ler; bitince doner (await'lenir).
func fade_to(alpha: float, duration: float) -> void:
	if duration <= 0.0:
		_fade_rect.modulate.a = alpha
		return
	var tw := create_tween()
	tw.tween_property(_fade_rect, "modulate:a", alpha, duration)
	await tw.finished


func change_scene(path: String) -> void:
	if _is_transitioning:
		return
	_is_transitioning = true
	await fade_to(1.0, 0.25)
	var err := get_tree().change_scene_to_file(path)
	if err != OK:
		push_error("Scene change failed (%s): %s" % [path, error_string(err)])
		await fade_to(0.0, 0.2)
		_is_transitioning = false
		return
	await get_tree().process_frame
	await get_tree().process_frame
	await fade_to(0.0, 0.35)
	_is_transitioning = false
	scene_loaded.emit(path)


func reload() -> void:
	get_tree().reload_current_scene()
