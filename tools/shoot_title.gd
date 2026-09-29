extends Node2D
func _ready() -> void:
	add_child(load("res://src/ui/Title.tscn").instantiate())
	await get_tree().create_timer(1.2).timeout
	get_viewport().get_texture().get_image().save_png("C:/Users/PC/AppData/Local/Temp/title.png")
	get_tree().quit()
