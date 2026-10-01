class_name GlitchCreature
extends CharacterBody2D
## Bolum 7 — perspektif kaymasi: oyuncu artik Glitch Yaratik.
## Hafif/ucan: dusuk yercekimi, kisik dusme hizi. Saldirisi glitch
## tanesi (menzilli), dash'i kisa glitch-kaybolusu (i-frame).

var input: InputSource
## MetaDirector (ch7): boss sahnesi kontrolleri ters cevirir — sadece
## yatay eksen (klasik adil inversion), isaret piktogrami ch7 verir.
var controls_inverted := false
var health: Health
var hurtbox: Hurtbox
var sprite: Sprite2D
var anims: AnimatedSprite2D
var facing := -1
var _dash_cd := 0.0
var _bolt_cd := 0.0
var _iframes := 0.0
var _flicker := 0.0
var _coyote := 0.0
var _jbuf := 0.0
var _tuning: Tuning
var dead := false

signal died


func _ready() -> void:
	_tuning = load("res://config/tuning.tres")
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

	# Sapka hirsizinin ana formu: dark_character anim bankasi varsa
	# oynar, yoksa koyu kutle gorunumunde kalir.
	_build_anims()

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


func _build_anims() -> void:
	var sf := SpriteFrames.new()
	for anim in [&"idle", &"walk", &"attack", &"hurt", &"die"]:
		var f := AssetLoader.frames(&"enemy/dark_character/" + String(anim))
		if f != null and f.get_frame_count(&"default") > 0:
			var speed := f.get_animation_speed(&"default")
			var loop := f.get_animation_loop(&"default")
			sf.add_animation(anim)
			for i in f.get_frame_count(&"default"):
				sf.add_frame(anim, f.get_frame_texture(&"default", i),
					f.get_frame_duration(&"default", i))
			sf.set_animation_speed(anim, speed)
			sf.set_animation_loop(anim, loop)
	sf.remove_animation(&"default")
	if not sf.has_animation(&"idle"):
		return
	anims = AnimatedSprite2D.new()
	anims.sprite_frames = sf
	var fs: Vector2 = sf.get_frame_texture(&"idle", 0).get_size()
	if fs.x > 0 and fs.y > 0:
		anims.scale = Vector2(14, 20) * 1.8 / fs
		anims.position.y = -8.0
	add_child(anims)
	anims.play(&"idle")
	sprite.visible = false


func _physics_process(delta: float) -> void:
	if dead or input == null:
		return
	input.poll()
	_dash_cd = maxf(_dash_cd - delta, 0.0)
	_bolt_cd = maxf(_bolt_cd - delta, 0.0)
	_iframes = maxf(_iframes - delta, 0.0)

	# Ucan: hafif yercekimi + dusuk maks dusus
	velocity.y = minf(velocity.y + 500.0 * delta, 90.0)
	var dir := input.move_axis()
	if controls_inverted:
		dir = -dir
	velocity.x = move_toward(velocity.x, dir * 80.0, 500.0 * delta)
	if absf(dir) > 0.1:
		facing = 1 if dir > 0 else -1
	if anims != null:
		anims.flip_h = facing < 0
		if not anims.is_playing() or anims.animation in [&"idle", &"walk"]:
			anims.play(&"walk" if absf(velocity.x) > 10.0 else &"idle")
	# Fliker: glitch karakteri hafif titrer
	_flicker += delta
	# Dokunulmazlik penceresinde goz kirpma (samurai ile ayni dil)
	var blink := _iframes > 0.0 and not dead \
		and int(Time.get_ticks_msec() / 70) % 2 == 0
	var want_a := 0.55 if blink else 1.0
	sprite.modulate = Color(0.05, 0.05, 0.12 + 0.08 * absf(sin(_flicker * 13.0)))
	sprite.modulate.a = want_a
	if anims != null:
		anims.modulate = sprite.modulate + Color(0.35, 0.35, 0.4)
		anims.modulate.a = want_a

	if input.jump_just_pressed():
		_jbuf = _tuning.jump_buffer_time
	_jbuf = maxf(_jbuf - delta, 0.0)
	_coyote = _tuning.coyote_time if is_on_floor() else maxf(_coyote - delta, 0.0)
	if _jbuf > 0.0 and (is_on_floor() or _coyote > 0.0):
		_jbuf = 0.0
		_coyote = 0.0
		velocity.y = -160.0  # hafif hop
	if input.jump_just_released() and velocity.y < -60.0:
		velocity.y = -60.0  # erken birakilan hop kisa kalir
	if input.dash_just_pressed() and _dash_cd <= 0.0:
		_dash_cd = 0.7
		_iframes = 0.25
		FX.glitch(0.35, 0.2)
		position.x += facing * 26.0
		AudioManager.play_sfx(&"sfx/dash", global_position)
	if input.attack_just_pressed() and _bolt_cd <= 0.0:
		_bolt_cd = 0.32
		_fire_bolt()
	move_and_slide()


func _fire_bolt() -> void:
	if anims != null:
		anims.play(&"attack")
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
	if anims != null:
		anims.play(&"hurt")


func _on_died() -> void:
	dead = true
	EventBus.actor_died.emit(self)
	died.emit()
	sprite.modulate = Color(1.0, 0.2, 0.2)
	if anims != null:
		anims.play(&"die")
	var tw := create_tween()
	tw.tween_property(sprite, "scale", Vector2.ZERO, 0.6)
	if anims != null:
		tw.parallel().tween_property(anims, "scale", Vector2.ZERO, 0.6)
	FX.glitch(1.2, 0.9)
