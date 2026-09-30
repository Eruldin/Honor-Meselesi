class_name HudBars
extends RefCounted
## HUD cubugu: Kasaya's Frames bar dokulari varsa gercek, yoksa
## ColorRect placeholder. Donen dict: {root, fill} — fill.size.x'i
## orana gore ayarla.


static func make(w := 160.0, h := 8.0, fill_color := Color(0.8, 0.2, 0.25), trail := false) -> Dictionary:
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
	var out := {"root": root, "fill": fill}
	if trail:
		# Beyaz iz cubugu — hasar sonrasi kirmizi fill'in gerisinde eriyen
		# golge (HK boss bar'i). drain() her frame gunceller.
		var tr := ColorRect.new()
		tr.color = Color(0.95, 0.95, 0.95, 0.55)
		tr.size = Vector2(w, h)
		root.add_child(tr)
		root.move_child(tr, root.get_child_count() - 2)  # fill'in altinda
		out["trail"] = tr
	return out


## Boss can cubugu: fill aninda iner, beyaz iz ~0.5 bar/sn hizla eriyip
## yakalar — vurulunca okunakli kisa beyaz kenar birakir (HK tarzi).
static func drain(bar: Dictionary, frac: float, w: float, delta: float) -> void:
	var f: Control = bar["fill"]
	f.size.x = w * clampf(frac, 0.0, 1.0)
	var tr: ColorRect = bar.get("trail")
	if tr == null:
		return
	if tr.size.x < f.size.x:
		tr.size.x = f.size.x
	else:
		tr.size.x = move_toward(tr.size.x, f.size.x, w * 0.5 * delta)


## fill cubugunu 0..1 oranina gore ayarlar.
static func set_frac(bar: Dictionary, frac: float, w := 160.0) -> void:
	var f: Control = bar["fill"]
	f.size.x = w * clampf(frac, 0.0, 1.0)
