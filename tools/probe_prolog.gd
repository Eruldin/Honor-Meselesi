extends "res://src/levels/prolog/prolog.gd"
## Prolog oda goruntusu probu — acilis fazi ekran goruntusu.
## Calistir: godot --path . res://tools/ProbeProlog.tscn

func _ready() -> void:
	fast_mode = true
	auto_advance = false
	super._ready()
	get_tree().create_timer(6.0).timeout.connect(get_tree().quit)
	_shoot()


func _shoot() -> void:
	await get_tree().create_timer(2.0).timeout
	get_viewport().get_texture().get_image().save_png(
		"C:/Users/PC/AppData/Local/Temp/prolog_room.png")
	# cutscene baslatip yaratik cikisini de yakala
	crt_game.glitch_out()
	await get_tree().create_timer(2.2).timeout
	get_viewport().get_texture().get_image().save_png(
		"C:/Users/PC/AppData/Local/Temp/prolog_creature.png")
	await get_tree().create_timer(2.5).timeout
	get_viewport().get_texture().get_image().save_png(
		"C:/Users/PC/AppData/Local/Temp/prolog_late.png")
