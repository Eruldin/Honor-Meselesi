extends Node2D
## M0 iskelet boot sahnesi — projenin asset'siz hata vermeden
## acildigini dogrular. M1'de ana sahne test odasi olur.


func _ready() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.05, 0.02, 0.08)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var label := Label.new()
	label.text = "HONOR MESELESI\nboot OK — %s" % Engine.get_version_info().string
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.set_anchors_preset(Control.PRESET_CENTER)
	add_child(label)

	# AssetLoader smoke: manifest yokken/bosken bile placeholder dusmeli.
	var spr := Sprite2D.new()
	AssetLoader.apply_to_sprite(spr, &"boot/placeholder", Vector2i(32, 32))
	spr.position = Vector2(240, 200)
	add_child(spr)
