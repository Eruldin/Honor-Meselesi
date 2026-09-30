class_name WeatherFx
extends Node2D
## Bolge bazli hava efektleri — gercek sprite'lar, hafif oynatim.
## zone_ranges: [{x0, x1, kind}] — kind: "petals" | "rain" | "dust_motes".
## Parcaciklar kameranin gordugu alana duser, ekran disinda silinir.

const PETAL_FALL := 22.0
const PETAL_SWAY := 14.0
const RAIN_FALL := 190.0

var _cam: Camera2D
var _zones: Array = []
var _spawn_acc := 0.0
var _tex := {}


func setup(cam: Camera2D, zones: Array) -> void:
	_cam = cam
	_zones = zones
	for id in [&"vfx/petal", &"vfx/raindrop", &"vfx/dust", &"vfx/rainsplash"]:
		if AssetLoader.has_asset(id):
			_tex[id] = AssetLoader.texture(id) \
				if not AssetLoader.has_frames(id) \
				else AssetLoader.frames(id).get_frame_texture(&"default", 0)


func _process(delta: float) -> void:
	if _cam == null or _zones.is_empty():
		return
	_spawn_acc += delta
	if _spawn_acc >= 0.12:
		_spawn_acc = 0.0
		_tick_spawn()


func _tick_spawn() -> void:
	var vx: float = _cam.get_screen_center_position().x
	for z in _zones:
		if vx < z.x0 - 240 or vx > z.x1 + 240:
			continue  # bolge ekran disi — parcacik uretme
		match z.kind:
			"petals":
				# Seyrek: her tik %35 ihtimalle tek petal
				if randf() < 0.35:
					_spawn_petal(vx)
			"rain":
				_spawn_rain(vx)


func _spawn_petal(vx: float) -> void:
	if not _tex.has(&"vfx/petal"):
		return
	var p := Sprite2D.new()
	p.texture = _tex[&"vfx/petal"]
	p.scale = Vector2(0.5, 0.5)   # 5x4px -> ince petal, dev yaprak degil
	var px := vx + randf_range(-230.0, 230.0)
	p.position = Vector2(px, _cam.get_screen_center_position().y - 140.0)
	p.modulate = Color(1.0, 0.8, 0.9, 0.65)
	p.z_index = 6
	add_child(p)
	var sway := randf_range(-PETAL_SWAY, PETAL_SWAY)
	var dur := randf_range(4.0, 6.5)
	var tw := p.create_tween().set_parallel(true)
	tw.tween_property(p, "position:y", p.position.y + 280.0, dur)
	tw.tween_property(p, "position:x", px + sway, dur)
	tw.tween_property(p, "rotation", randf_range(-1.6, 1.6), dur)
	tw.chain().tween_property(p, "modulate:a", 0.0, 0.5)
	tw.finished.connect(p.queue_free)


func _spawn_rain(vx: float) -> void:
	if not _tex.has(&"vfx/raindrop"):
		return
	for i in 3:  # yagmur daha sik
		var p := Sprite2D.new()
		p.texture = _tex[&"vfx/raindrop"]
		p.position = Vector2(vx + randf_range(-240.0, 240.0),
			_cam.get_screen_center_position().y - 150.0)
		p.modulate = Color(0.7, 0.8, 1.0, 0.75)
		p.z_index = 6
		add_child(p)
		var drop_h := 300.0
		var dur := drop_h / RAIN_FALL
		var tw := p.create_tween()
		tw.tween_property(p, "position:y", p.position.y + drop_h, dur)
		tw.finished.connect(_splash.bind(p))


func _splash(drop: Sprite2D) -> void:
	var pos := drop.position
	drop.queue_free()
	if not _tex.has(&"vfx/rainsplash"):
		return
	var s := Sprite2D.new()
	s.texture = _tex[&"vfx/rainsplash"]
	s.position = pos
	s.modulate = Color(0.7, 0.8, 1.0, 0.6)
	s.z_index = 6
	add_child(s)
	var tw := s.create_tween()
	tw.tween_property(s, "modulate:a", 0.0, 0.25)
	tw.finished.connect(s.queue_free)


## Yuruyus/kosu tozu — karakter ayagina tek seferlik puff.
## samurai.gd cagirir; kare bittiginde yok olur.
static func puff(parent: Node, pos: Vector2) -> void:
	if parent == null or not AssetLoader.has_asset(&"vfx/dust"):
		return
	var d := Sprite2D.new()
	d.texture = AssetLoader.texture(&"vfx/dust")
	d.position = pos + Vector2(randf_range(-2.0, 2.0), -2.0)
	d.modulate = Color(0.75, 0.68, 0.6, 0.8)
	d.z_index = 5
	parent.add_child(d)
	var tw := d.create_tween().set_parallel(true)
	tw.tween_property(d, "scale", Vector2(1.9, 1.9), 0.45)
	tw.tween_property(d, "position:y", d.position.y - 8.0, 0.45)
	tw.tween_property(d, "modulate:a", 0.0, 0.45)
	tw.finished.connect(d.queue_free)
