extends Node2D
## Genel bolum probe'u: --probe=chN --spot=<0..1> ile seviye ortasina icer.
## Ornek: --path . tools/ProbeCh.tscn --probe=ch3 --spot=0.5

var _scene


func _ready() -> void:
	var ch := "ch3"
	var spot := 0.5
	var death := false
	for a in OS.get_cmdline_args() + OS.get_cmdline_user_args():
		if a.begins_with("--probe="):
			ch = a.get_slice("=", 1)
		if a.begins_with("--spot="):
			spot = float(a.get_slice("=", 1))
		if a == "--death":
			death = true
	var scn := load("res://src/levels/%s/Ch%s.tscn" % [ch, ch.substr(2)])
	if scn == null:
		push_error("no scene for " + ch)
		get_tree().quit(1)
		return
	_scene = scn.instantiate()
	if "auto_advance" in _scene:
		_scene.auto_advance = false
	if death:
		var lw: float = _scene.get("LEVEL_W") if _scene.get("LEVEL_W") != null else 1600.0
		var fy: float = _scene.get("FLOOR_Y") if _scene.get("FLOOR_Y") != null else 250.0
		GameState.set_flag(&"death_mark_ch", StringName(ch))
		GameState.set_flag(&"death_mark_pos",
			Vector2(lerpf(200.0, lw - 200.0, spot), fy - 14))
		GameState.set_flag(&"death_mark_soul", 8)
	add_child(_scene)
	get_tree().create_timer(6.0).timeout.connect(get_tree().quit)
	call_deferred("_shoot", ch, spot)


func _shoot(ch: String, spot: float) -> void:
	await get_tree().create_timer(1.0).timeout
	var sam = _scene.get("samurai")
	var lw: float = _scene.get("LEVEL_W") if _scene.get("LEVEL_W") != null else 1600.0
	var fy: float = _scene.get("FLOOR_Y") if _scene.get("FLOOR_Y") != null else 250.0
	if sam != null:
		sam.global_position = Vector2(lerpf(200.0, lw - 200.0, spot), fy - 20)
	await get_tree().create_timer(1.2).timeout
	get_viewport().get_texture().get_image().save_png(
		"res://.probe_out/%s_%.0f.png" % [ch, spot * 100])
	get_tree().quit()
