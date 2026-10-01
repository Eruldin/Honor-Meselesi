extends Node2D
## ch7 kalp mizragi gorsel probu: meta assault bitiminden sonra boss
## canini %30'a indir -> HUD kalbi sokulur, yaratiga atilir.
var _scene

func _ready() -> void:
	var scn := load("res://src/levels/ch7/Ch7.tscn")
	_scene = scn.instantiate()
	_scene.auto_advance = false
	add_child(_scene)
	get_tree().create_timer(16.0).timeout.connect(get_tree().quit)
	call_deferred("_run")

func _run() -> void:
	await get_tree().create_timer(1.2).timeout
	_scene._choice_decide()
	await get_tree().create_timer(0.5).timeout
	_scene.boss.health.take(int(_scene.boss.health.max_health * 0.50))
	await get_tree().create_timer(7.5).timeout  # inversion+penceresi bitsin
	_scene.boss.health.take(int(_scene.boss.health.max_health * 0.26))
	await get_tree().create_timer(1.8).timeout
	var img := get_viewport().get_texture().get_image()
	img.save_png("res://.probe_out/ch7_spear.png")
	var spears := 0
	for c in _scene.get_children():
		if c is HeartSpear:
			spears += 1
	prints("saved ch7_spear.png spears:", spears,
		"hp:", _scene.boss.health.current, "/", _scene.boss.health.max_health)
