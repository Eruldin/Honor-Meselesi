extends "res://src/levels/ch1/ch1.gd"
## Hizli dogrulama probu: teleport -> kare yakala.
## Kullanim: --probe village|gate|arena

var _ai: AIInputSource
var _step := 0


func _ready() -> void:
	auto_advance = false
	super._ready()
	_ai = AIInputSource.new()
	samurai.set_input_source(_ai)
	var spot := "village"
	for a in OS.get_cmdline_args() + OS.get_cmdline_user_args():
		if a.begins_with("--probe="):
			spot = a.get_slice("=", 1)
	call_deferred("_go", spot)
	# Ne olursa olsun 5 sn sonra kapat
	get_tree().create_timer(5.0).timeout.connect(get_tree().quit)


func _go(spot: String) -> void:
	await get_tree().create_timer(0.6).timeout
	var spots := {"village": 300.0, "gate": 4200.0, "arena": 4640.0,
		"forest": 1900.0, "cave": 2700.0, "well": 480.0}
	var x: float = spots.get(spot, 300.0)
	samurai.global_position = Vector2(x, FLOOR_Y - 10)
	await get_tree().create_timer(0.4).timeout
	if spot == "gate":
		# sovalye olmemis gibi kapi kapali gorunsun; ayrica acik hali icin:
		pass
	if spot == "arena":
		_on_arena_entered(samurai.hurtbox)
		await get_tree().create_timer(1.5).timeout
	get_viewport().get_texture().get_image().save_png(
		"res://.probe_out/ch1_%s.png" % spot)
	await get_tree().create_timer(0.5).timeout
	get_viewport().get_texture().get_image().save_png(
		"res://.probe_out/ch1_%s_b.png" % spot)
	get_tree().quit()
