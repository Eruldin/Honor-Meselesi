class_name EnemyBase
extends CharacterBody2D
## Tum dusmanlarin tabani: Health + Hurtbox + placeholder sprite +
## sersemletme (parry sonrasi). Bolum 4.4'teki "telegraph zorunlu"
## kurali gercek saldirilar eklenince uygulanir.

@export var max_hp: int = 3
@export var body_size: Vector2 = Vector2(14, 16)
## Devamli temas hasari veriyorsa true (diken haric; diken kendi sinif).
@export var contact_damage: bool = false

var tuning: Tuning
var health: Health
var hurtbox: Hurtbox
var sprite: Sprite2D
var contact_hitbox: Hitbox
var stagger_timer: float = 0.0
var _flash_timer: float = 0.0


func _ready() -> void:
	tuning = load("res://config/tuning.tres")
	collision_layer = 64
	collision_mask = 1

	var col := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = body_size
	col.shape = rect
	add_child(col)

	sprite = Sprite2D.new()
	sprite.texture = AssetLoader.placeholder_texture("enemy/%s" % name, Vector2i(body_size))
	add_child(sprite)

	health = Health.new()
	health.max_health = max_hp
	add_child(health)
	health.died.connect(_on_died)

	hurtbox = Hurtbox.new()
	hurtbox.collision_layer = 16
	hurtbox.collision_mask = 8  # player hitbox
	var hb_col := CollisionShape2D.new()
	var hb_rect := RectangleShape2D.new()
	hb_rect.size = body_size + Vector2(2, 2)
	hb_col.shape = hb_rect
	hurtbox.add_child(hb_col)
	add_child(hurtbox)

	if contact_damage:
		contact_hitbox = Hitbox.new()
		contact_hitbox.collision_layer = 32
		contact_hitbox.collision_mask = 4
		var ch_col := CollisionShape2D.new()
		var ch_rect := RectangleShape2D.new()
		ch_rect.size = body_size + Vector2(4, 4)
		ch_col.shape = ch_rect
		contact_hitbox.add_child(ch_col)
		add_child(contact_hitbox)
		contact_hitbox.activate(DamageInfo.make(1, self, Vector2.ZERO, true, true))


func _physics_process(delta: float) -> void:
	stagger_timer = maxf(stagger_timer - delta, 0.0)
	velocity.y = minf(velocity.y + 800.0 * delta, 320.0)
	move_and_slide()


func _process(delta: float) -> void:
	if _flash_timer > 0.0:
		_flash_timer -= delta
		if _flash_timer <= 0.0:
			sprite.modulate = Color.WHITE


func is_staggered() -> bool:
	return stagger_timer > 0.0


func take_damage(info: DamageInfo) -> void:
	if not health.is_alive():
		return
	health.take(info.damage)
	sprite.modulate = Color(2.0, 2.0, 2.0)
	_flash_timer = 0.08
	EventBus.damage_dealt.emit(self, info)


func on_parried() -> void:
	stagger_timer = tuning.parry_stagger
	sprite.modulate = Color(1.0, 0.9, 0.3)
	_flash_timer = stagger_timer


func _on_died() -> void:
	EventBus.actor_died.emit(self)
	var tw := create_tween()
	tw.tween_property(sprite, "modulate:a", 0.0, 0.3)
	tw.finished.connect(queue_free)
