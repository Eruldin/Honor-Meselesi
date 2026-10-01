extends Node2D
## ch7 meta assault gorsel probu: savasi baslat, boss canini %55'in altina
## indir, letterbox + ters kontrol aninda kare yakala.
var _scene

func _ready() -> void:
	var scn := load("res://src/levels/ch7/Ch7.tscn")
	_scene = scn.instantiate()
	_scene.auto_advance = false
	add_child(_scene)
	get_tree().create_timer(12.0).timeout.connect(get_tree().quit)
	call_deferred("_run")

func _run() -> void:
	await get_tree().create_timer(1.2).timeout
	_scene._choice_decide()
	await get_tree().create_timer(0.5).timeout
	_scene.boss.health.take(int(_scene.boss.health.max_health * 0.50))
	await get_tree().create_timer(2.0).timeout
	var img := get_viewport().get_texture().get_image()
	img.save_png("res://.probe_out/ch7_meta.png")
	prints("saved ch7_meta.png inverted:", _scene.creature.controls_inverted)
