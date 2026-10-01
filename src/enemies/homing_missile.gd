class_name HomingMissile
extends Node2D
## Unit-0 gudumlu fuzesi: oyuncuya dogru doner, temas = patlama hasari.
## Parry'lenebilir (parry'de patrona geri doner — zirh kirma kapisi).

var hitbox: Hitbox
var _vel := Vector2.ZERO
var _tuning: Tuning
var _life := 5.0
var _dead := false


func _ready() -> void:
	_tuning = load("res://config/tuning.tres")
	var sprite := Sprite2D.new()
	sprite.texture = AssetLoader.texture(&"enemy/missile", Vector2i(10, 5))
	sprite.modulate = Color(1.0, 0.6, 0.2)
	add_child(sprite)

	hitbox = Hitbox.new()
	hitbox.collision_layer = 32
	hitbox.collision_mask = 4 | 1  # oyuncu hurtbox + duvar govdesi
	var col := CollisionShape2D.new()
	var c := CircleShape2D.new()
	c.radius = 6.0
	col.shape = c
	hitbox.add_child(col)
	add_child(hitbox)
	hitbox.activate(DamageInfo.make(1, self, Vector2.ZERO, true, false))
	hitbox.body_entered.connect(func(_b: Node) -> void: _explode())
	_vel = Vector2(-_tuning.missile_speed, -60)


func _physics_process(delta: float) -> void:
	_life -= delta
	if _life <= 0.0:
		_explode()
		return
	var p := get_tree().get_first_node_in_group(&"player")
	if p != null:
		var want: Vector2 = (p.global_position - global_position).normalized() * _tuning.missile_speed
		_vel = _vel.lerp(want, _tuning.missile_turn * delta)
	position += _vel * delta
	rotation = _vel.angle()


## Parry: fuze geri doner ve artik dusmanlara (Unit-0'a) vurur.
func on_parried() -> void:
	_vel = -_vel * 0.8
	hitbox.collision_mask = 16 | 1
	hitbox.struck.connect(func(_h: Hurtbox) -> void: _explode(), CONNECT_ONE_SHOT)
	get_child(0).modulate = Color(0.3, 1.0, 1.0)


func _explode() -> void:
	if _dead:
		return
	_dead = true
	var spr := get_child(0)
	spr.scale = Vector2(3, 3)
	spr.modulate = Color(1.0, 0.7, 0.2, 0.9)
	FX.shake(2.0, 0.2)
	AudioManager.play_sfx(&"sfx/explosion", global_position, -6.0)
	var tw := create_tween()
	tw.tween_property(spr, "modulate:a", 0.0, 0.12)
	tw.finished.connect(queue_free)
