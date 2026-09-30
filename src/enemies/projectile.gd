class_name Projectile
extends Node2D
## Parry'lenebilir mermi. Parry basarili olursa yon terslenir ve
## artik dusman hurtbox'larina vurur (kaynak degisir).
## vertical=true: dikey iner (drone); parry'de yukari geri doner.

@export var speed: float = 110.0
@export var max_range: float = 400.0
@export var vertical := false

var direction: int = -1
var reflected: bool = false
var hitbox: Hitbox
var _travelled: float = 0.0


func _ready() -> void:
	var sprite := Sprite2D.new()
	sprite.texture = AssetLoader.texture(&"enemy/projectile", Vector2i(6, 6))
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
	hitbox.activate(DamageInfo.make(1, self,
		Vector2(0, 60) if vertical else Vector2(direction * 60, 0), true, false))
	AudioManager.play_sfx(&"sfx/dash", global_position, -14.0, randf_range(1.15, 1.35))


func _physics_process(delta: float) -> void:
	var step := speed * delta
	if vertical:
		position.y += (-step if reflected else step)
	else:
		position.x += (direction if not reflected else -direction) * step
	_travelled += step
	if _travelled >= max_range:
		queue_free()


## Samurai._on_parry_success cagirir: mermi geri doner.
func on_parried() -> void:
	reflected = true
	_travelled = 0.0
	if not vertical:
		direction = -direction
	hitbox.collision_mask = 16  # artik dusman hurtbox'lari
	modulate_self()


func modulate_self() -> void:
	get_child(0).modulate = Color(0.3, 1.0, 1.0)
