extends "res://src/levels/ch1/ch1.gd"

func _ready() -> void:
	auto_advance = false
	super._ready()
	await get_tree().create_timer(0.5).timeout
	var counts := {}
	for n in get_children():
		var c := n.get_class()
		if n.get_script() != null:
			c = n.get_script().resource_path.get_file().get_basename()
		counts[c] = counts.get(c, 0) + 1
		if c in ["crow", "druid", "demon_axe", "imp_red", "executioner", "cave_bat", "flying_sword"]:
			print("[NEW] %s @%s anims=%s alive=%s" % [c, n.global_position,
				n.anims != null, n.health.is_alive()])
	print("[COUNTS] %s" % counts)
	get_tree().quit()
