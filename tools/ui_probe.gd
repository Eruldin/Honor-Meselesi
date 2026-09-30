extends Control

func _ready() -> void:
	var t: Node = load("res://src/ui/Title.tscn").instantiate()
	add_child(t)
	await get_tree().create_timer(1.5).timeout
	get_viewport().get_texture().get_image().save_png("res://.probe_out/ui_title.png")
	# settings ac
	if t.has_method("_on_settings"):
		t._on_settings()
	elif t.has_node("SettingsMenu"):
		t.get_node("SettingsMenu").visible = true
	await get_tree().create_timer(0.8).timeout
	get_viewport().get_texture().get_image().save_png("res://.probe_out/ui_settings.png")
	get_tree().quit()
