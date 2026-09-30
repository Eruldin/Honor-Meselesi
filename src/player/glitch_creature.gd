class_name GlitchCreature
extends CharacterBody2D
## Bolum 7 — perspektif kaymasi: oyuncu artik Glitch Yaratik.
## Hafif/ucan: dusuk yercekimi, kisik dusme hizi. Saldirisi glitch
## tanesi (menzilli), dash'i kisa glitch-kaybolusu (i-frame).

var input: InputSource
var health: Health
var hurtbox: Hurtbox
var sprite: Sprite2D
var facing := -1
var _dash_cd := 0.0
var _iframes := 0.0
var _flicker := 0.0
var dead := false

signal died


func _ready() -> void:
	add_to_group(&"player")
	collision_layer = 4
	collision_mask = 1 | 32
	var col := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(12, 10)
	col.shape = rect
	add_child(col)

	# Prolog'daki yaratikla ayni gorunum: koyu kutle + cyan gozler
	sprite = Sprite2D.new()
	sprite.texture = AssetLoader.texture(&"enemy/glitch_creature", Vector2i(16, 14))
	sprite.modulate = Color(0.05, 0.05, 0.12)
	add_child(sprite)
	for dx in [-3.0, 3.0]:
		var eye := ColorRect.new()
		eye.size = Vector2(2, 3)
		eye.position = Vector2(dx - 1, -4)
		eye.color = Color(0.4, 1.0, 0.9)
		sprite.add_child(eye)

	health = Health.new()
	health.max_health = 5
	add_child(health)
	health.died.connect(_on_died)

	hurtbox = Hurtbox.new()
	hurtbox.collision_layer = 4
	hurtbox.collision_mask = 32
	var hb := CollisionShape2D.new()
	var hr := RectangleShape2D.new()
	hr.size = Vector2(12, 10)
	hb.shape = hr
	hurtbox.add_child(hb)
	add_child(hurtbox)
	hurtbox.hit_received.connect(_on_hit_info)


func set_input_source(src: InputSource) -> void:
	if input != null:
		input.queue_free()
	input = src
	add_child(input)


func _physics_process(delta: float) -> void:
	if dead or input == null:
		return
	input.poll()
	_dash_cd = maxf(_dash_cd - delta, 0.0)
	_iframes = maxf(_iframes - delta, 0.0)

	# Ucan: hafif yercekimi + dusuk maks dusus
	velocity.y = minf(velocity.y + 500.0 * delta, 90.0)
	var dir := input.move_axis()
	velocity.x = move_toward(velocity.x, dir * 80.0, 500.0 * delta)
	if absf(dir) > 0.1:
		facing = 1 if dir > 0 else -1
	# Fliker: glitch karakteri hafif titrer
	_flicker += delta
	sprite.modulate = Color(0.05, 0.05, 0.12 + 0.08 * absf(sin(_flicker * 13.0)))

	if input.jump_just_pressed():
		velocity.y = -160.0  # hafif hop
	if input.dash_just_pressed() and _dash_cd <= 0.0:
		_dash_cd = 0.7
		_iframes = 0.25
		FX.glitch(0.35, 0.2)
		position.x += facing * 26.0
		AudioManager.play_sfx(&"sfx/dash", global_position)
	if input.attack_just_pressed():
		_fire_bolt()
	move_and_slide()


func _fire_bolt() -> void:
	var bolt := GlitchBolt.new()
	bolt.vel = Vector2(facing * 150.0, 0)
	bolt.src = self
	bolt.global_position = global_position + Vector2(facing * 9.0, -4)
	get_parent().add_child(bolt)
	AudioManager.play_sfx(&"sfx/attack", global_position, -6.0)


func _on_hit_info(info: DamageInfo) -> void:
	if _iframes > 0.0 or dead:
		return
	health.take(info.damage)
	_iframes = 0.8
	FX.shake(2.0, 0.2)
	AudioManager.play_sfx(&"sfx/hurt", global_position)
	sprite.modulate = Color(2.0, 0.6, 0.6)


func _on_died() -> void:
	dead = true
	EventBus.actor_died.emit(self)
	died.emit()
	sprite.modulate = Color(1.0, 0.2, 0.2)
	var tw := create_tween()
	tw.tween_property(sprite, "scale", Vector2.ZERO, 0.6)
	FX.glitch(1.2, 0.9)
