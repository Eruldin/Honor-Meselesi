class_name HeartSpear
extends Area2D
## MetaDirector (ch7): HUD'dan sokulen son dolu kalp oyuncuya atilir.
## Yavas homing (~4.5s), degince 1 hasar; sonra HUD'a geri ucar.
## Olum/reload sirasinda sahne zaten yenilenir — geri donus garantisi
## ch7 tarafindan izlenmez, sadece is_instance_valid guard yeterli.

signal returned(spear: HeartSpear)

var _target: Node2D
var _vel := Vector2.ZERO
var _speed := 60.0
var _turn := 4.0
var _fly_time := 4.5
var _returning := false
var _ret_dur := 0.8
var _ret_t := 0.0
var _ret_from := Vector2.ZERO
var _ret_to := Vector2.ZERO
var _done := false


func launch(target: Node2D) -> void:
	_target = target
	var spr := Sprite2D.new()
	spr.texture = AssetLoader.texture(&"ui/hud_heart", Vector2i(12, 12))
	spr.modulate = Color(1.4, 0.7, 0.75)
	add_child(spr)
	var col := CollisionShape2D.new()
	var r := RectangleShape2D.new()
	r.size = Vector2(10, 10)
	col.shape = r
	add_child(col)
	collision_layer = 0
	collision_mask = 4  # oyuncu
	# Firlatma yonu: ekran kosesinden iceri
	_vel = (_target.global_position - global_position).normalized() * _speed
	body_entered.connect(_on_body)


func _physics_process(delta: float) -> void:
	if _done:
		return
	if _returning:
		_ret_t += delta / _ret_dur
		global_position = _ret_from.lerp(_ret_to, minf(_ret_t, 1.0))
		if _ret_t >= 1.0:
			_done = true
			returned.emit(self)
		return
	if not is_instance_valid(_target):
		_start_return()
		return
	_fly_time -= delta
	var want: Vector2 = (_target.global_position - global_position).normalized()
	var cur := _vel.normalized()
	var ang := cur.angle_to(want)
	var max_turn := _turn * delta
	cur = cur.rotated(clampf(ang, -max_turn, max_turn))
	_vel = cur * _speed
	global_position += _vel * delta
	rotation = _vel.angle()
	if _fly_time <= 0.0:
		_start_return()


func _on_body(body: Node2D) -> void:
	if _done or _returning:
		return
	if body == _target:
		body.take_damage(DamageInfo.make(1, null,
			(global_position - body.global_position).normalized() * 140.0,
			false, true))
		_start_return()


func _start_return() -> void:
	_returning = true
	_ret_from = global_position
	# HUD kosesine geri — kalbin yuvasi ust-sol
	_ret_to = Vector2(32, 12)
