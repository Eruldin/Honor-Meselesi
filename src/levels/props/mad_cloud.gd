class_name MadCloud
extends Node2D
## Bolum 4 tekinsiz dekor: devinen gozlu bulut; ara ara devrilip kirilir
## (dusen parca hitbox'suz, sadece gorsel rahatsizlik — plan M7 "bozuk hava").

var _eye_l: ColorRect
var _eye_r: ColorRect
var _player: Node2D
var _t: float


func _ready() -> void:
	var t: Tuning = load("res://config/tuning.tres")
	_t = t.cloud_tip_interval * randf()
	var body := Sprite2D.new()
	body.texture = _cloud_texture()
	add_child(body)
	for dx in [-6.0, 6.0]:
		var eye := ColorRect.new()
		eye.size = Vector2(3, 4)
		eye.position = Vector2(dx - 1.5, -3)
		eye.color = Color(0.1, 0.1, 0.15)
		add_child(eye)
		if dx < 0:
			_eye_l = eye
		else:
			_eye_r = eye


func _process(delta: float) -> void:
	var t: Tuning = load("res://config/tuning.tres")
	if _player == null:
		_player = get_tree().get_first_node_in_group(&"player")
	else:
		# Gozler oyuncuyu izler
		var dir := signf(_player.global_position.x - global_position.x)
		_eye_l.position.x = -7.5 + dir * 2.0
		_eye_r.position.x = 4.5 + dir * 2.0
	_t += delta
	if _t > t.cloud_tip_interval:
		_t = 0.0
		_tip_over()


## Pofuduk bulut dokusu: ortusen dairelerden olusan 34x14 piksel resim.
func _cloud_texture() -> ImageTexture:
	var img := Image.create(34, 14, false, Image.FORMAT_RGBA8)
	img.fill(Color.TRANSPARENT)
	var shade := Color(0.78, 0.78, 0.85)
	var light := Color(0.95, 0.95, 1.0)
	for c in [[9, 8, 6], [18, 6, 7], [26, 8, 5], [14, 10, 6], [23, 10, 5]]:
		var cx: int = c[0]
		var cy: int = c[1]
		var r: int = c[2]
		for y in range(-r, r + 1):
			for x in range(-r, r + 1):
				if x * x + y * y <= r * r:
					var px := cx + x
					var py := cy + y
					if px >= 0 and px < 34 and py >= 0 and py < 14:
						img.set_pixel(px, py, light if py < cy else shade)
	return ImageTexture.create_from_image(img)


## Devrilme: yana yatip solar — rahatsiz edici dekor olayi.
func _tip_over() -> void:
	var tw := create_tween()
	tw.tween_property(self, "rotation", PI / 2.5, 0.4)
	tw.parallel().tween_property(self, "position:y", position.y + 26, 0.4)
	tw.tween_property(self, "modulate:a", 0.0, 0.5)
	tw.tween_callback(func() -> void:
		rotation = 0.0
		position.y -= 26
		modulate.a = 1.0)
