extends Node2D
func _ready() -> void:
	add_child(load("res://src/ui/Title.tscn").instantiate())
	await get_tree().create_timer(1.2).timeout
	get_viewport().get_texture().get_image().save_png("res://.probe_out/title.png")
	get_tree().quit()
