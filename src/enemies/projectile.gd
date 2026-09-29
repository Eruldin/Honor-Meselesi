class_name Projectile
extends Node2D
## Parry'lenebilir mermi. Parry basarili olursa yon terslenir ve
## artik dusman hurtbox'larina vurur (kaynak degisir).

@export var speed: float = 110.0
@export var max_range: float = 400.0

var direction: int = -1
var reflected: bool = false
var hitbox: Hitbox
var _travelled: float = 0.0


func _ready() -> void:
	var sprite := Sprite2D.new()
	sprite.texture = AssetLoader.placeholder_texture("enemy/projectile", Vector2i(6, 6))
	sprite.modulate = Color(1.0, 0.4, 0.9)
	add_child(sprite)

	hitbox = Hitbox.new()
	hitbox.collision_layer = 32
	hitbox.collision_mask = 4  # player hurtbox
	var col := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 4.0
	col.shape = circle
	hitbox.add_child(col)
	add_child(hitbox)
	hitbox.activate(DamageInfo.make(1, self, Vector2(direction * 60, 0), true, false))


func _physics_process(delta: float) -> void:
	var step := speed * delta
	position.x += direction * step
	_travelled += step
	if _travelled >= max_range:
		queue_free()


## Samurai._on_parry_success cagirir: mermi geri doner.
func on_parried() -> void:
	direction = -direction
	reflected = true
	_travelled = 0.0
	hitbox.collision_mask = 16  # artik dusman hurtbox'lari
	modulate_self()


func modulate_self() -> void:
	get_child(0).modulate = Color(0.3, 1.0, 1.0)
