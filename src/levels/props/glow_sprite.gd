extends Sprite2D
## Yumusak isik halesi: tek dokulu radyal gradyan, ADD blend ile parlar.
## Global class_name yerine preload ile kullanilir (class cache bagimsiz).
## Dokuyu tum ornekler paylasir — ilk kullanimda bir kez uretilir.

static var _tex: ImageTexture


func _init(radius := 14.0, col := Color(1.0, 0.85, 0.5, 0.45)) -> void:
	if _tex == null:
		var img := Image.create(24, 24, false, Image.FORMAT_RGBA8)
		for y in 24:
			for x in 24:
				var d := Vector2(x - 11.5, y - 11.5).length() / 11.5
				var a := clampf(1.0 - d, 0.0, 1.0)
				img.set_pixel(x, y, Color(1.0, 1.0, 1.0, a * a))
		_tex = ImageTexture.create_from_image(img)
	texture = _tex
	scale = Vector2.ONE * (radius / 12.0)
	modulate = col
	var mat := CanvasItemMaterial.new()
	mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	material = mat
