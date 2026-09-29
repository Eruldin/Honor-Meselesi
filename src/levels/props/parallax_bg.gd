class_name ParallaxBg
extends RefCounted
## Katmanli parallax arka plan kurar. Her katman bir Parallax2D +
## yatayda döşenmis sprite; kamera yavaslayan katmanlarda az yürür.
##
## Kullanim:
##   ParallaxBg.add(self, LEVEL_W, [
##       {id = &"bg/forest_far", scroll = 0.15},
##       {id = &"bg/forest_mid", scroll = 0.35},
##       {id = &"bg/forest_near", scroll = 0.6, modulate = Color(0.9,0.6,0.6)},
##   ])
##
## spec alanlari: id (StringName, zorunlu), scroll (x carpan, vars 0.3),
## y (katmanin taban yeri, vars 270 — sahne yuksekligi), modulate (Color).


static func add(root: Node2D, level_w: float, specs: Array) -> void:
	for s in specs:
		var id: StringName = s.get("id", &"")
		if not AssetLoader.has_asset(id):
			continue
		var tex := AssetLoader.texture(id)
		var th := tex.get_height()
		var tw := tex.get_width()
		if th <= 0 or tw <= 0:
			continue
		# katmani ekran yuksekligine olcekle, sonra yatayda dose
		var k: float = 270.0 / th
		var tile_w := int(ceilf(tw * k))
		var scroll := float(s.get("scroll", 0.3))
		var x0 := float(s.get("x0", 0.0))
		var x1 := float(s.get("x1", level_w))
		var dist := maxf(0.0, x1 - x0)
		var need_w := int(ceilf(480.0 + dist * scroll + tile_w))
		if need_w <= 0: continue
		var layer_img := Image.create(need_w, 270, false, Image.FORMAT_RGBA8)
		layer_img.fill(Color.TRANSPARENT)
		var timg := tex.get_image()
		if timg.get_format() != Image.FORMAT_RGBA8:
			timg.convert(Image.FORMAT_RGBA8)
		timg.resize(tile_w, 270, Image.INTERPOLATE_NEAREST)
		for x in range(0, need_w, tile_w):
			layer_img.blit_rect(timg, Rect2i(0, 0, tile_w, 270), Vector2i(x, 0))
		var p := Parallax2D.new()
		p.scroll_scale = Vector2(scroll, 1.0)
		var sp := Sprite2D.new()
		sp.texture = ImageTexture.create_from_image(layer_img)
		sp.centered = false
		sp.position.x = x0 * scroll
		sp.position.y = float(s.get("y", 270.0)) - 270.0
		if s.has("z_index"):
			p.z_index = s["z_index"]
		if s.has("modulate"):
			sp.modulate = s["modulate"]
		p.add_child(sp)
		root.add_child(p)
