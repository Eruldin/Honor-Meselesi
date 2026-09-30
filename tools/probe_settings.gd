extends Node2D
func _ready() -> void:
	var s := SettingsMenu.new()
	add_child(s)
	s._open = true
	s.visible = true
	s._rebuild_tab()
	await get_tree().create_timer(1.0).timeout
	get_viewport().get_texture().get_image().save_png("res://.probe_out/settings_menu.png")
	get_tree().quit()
