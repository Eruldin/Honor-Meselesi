class_name HudBars
extends RefCounted
## HUD cubugu: Kasaya's Frames bar dokulari varsa gercek, yoksa
## ColorRect placeholder. Donen dict: {root, fill} — fill.size.x'i
## orana gore ayarla.


static func make(w := 160.0, h := 8.0, fill_color := Color(0.8, 0.2, 0.25)) -> Dictionary:
	var root := Control.new()
	root.custom_minimum_size = Vector2(w, h)
	root.size = Vector2(w, h)
	var fill: CanvasItem
	if AssetLoader.has_asset(&"ui/hp_bg"):
		var bg := TextureRect.new()
		bg.texture = AssetLoader.texture(&"ui/hp_bg")
		bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		bg.stretch_mode = TextureRect.STRETCH_SCALE
		bg.set_anchors_preset(Control.PRESET_FULL_RECT)
		root.add_child(bg)
	else:
		var bg := ColorRect.new()
		bg.color = Color(0.08, 0.06, 0.1)
		bg.set_anchors_preset(Control.PRESET_FULL_RECT)
		root.add_child(bg)
	if AssetLoader.has_asset(&"ui/hp_fill"):
		var f := TextureRect.new()
		f.texture = AssetLoader.texture(&"ui/hp_fill")
		f.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		f.stretch_mode = TextureRect.STRETCH_SCALE
		f.anchor_right = 0.0
		f.anchor_bottom = 0.0
		f.size = Vector2(w, h)
		root.add_child(f)
		fill = f
	else:
		var f := ColorRect.new()
		f.color = fill_color
		f.size = Vector2(w, h)
		root.add_child(f)
		fill = f
	return {"root": root, "fill": fill}


## fill cubugunu 0..1 oranina gore ayarlar.
static func set_frac(bar: Dictionary, frac: float, w := 160.0) -> void:
	var f: Control = bar["fill"]
	f.size.x = w * clampf(frac, 0.0, 1.0)
