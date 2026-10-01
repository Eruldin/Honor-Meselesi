class_name ExplodingEgg
extends CharacterBody2D
## Lord Cluck yumurtasi: yere oturur, fuse dolunca patlar (AoE).
## Oyuncu kilicla vurursa patrona geri yollar (DEVIN_PLAN M4).

enum State { IDLE, FUSED, REFLECTED }

var state := State.IDLE
var boss: Node2D
var _fuse := 0.0
var _tuning: Tuning
var _reflect_dir := 0

var hurtbox: Hurtbox
var hitbox: Hitbox
var sprite: Sprite2D


func _ready() -> void:
	_tuning = load("res://config/tuning.tres")
	collision_layer = 0
	collision_mask = 1

	var col := CollisionShape2D.new()
	var c := CircleShape2D.new()
	c.radius = 6.0
	col.shape = c
	add_child(col)

	sprite = Sprite2D.new()
	sprite.texture = AssetLoader.texture(&"enemy/egg", Vector2i(10, 12))
	sprite.modulate = Color(0.95, 0.9, 0.6)
	add_child(sprite)

	hurtbox = Hurtbox.new()
	hurtbox.collision_layer = 16
	hurtbox.collision_mask = 8
	var hb := CollisionShape2D.new()
	var hbr := CircleShape2D.new()
	hbr.radius = 7.0
	hb.shape = hbr
	hurtbox.add_child(hb)
	add_child(hurtbox)

	hitbox = Hitbox.new()
	hitbox.collision_layer = 32
	hitbox.collision_mask = 4  # oyuncu
	var hc := CollisionShape2D.new()
	var hcr := CircleShape2D.new()
	hcr.radius = _tuning.egg_blast_radius
	hc.shape = hcr
	hitbox.add_child(hc)
	add_child(hitbox)
	hitbox.deactivate()

	_fuse = _tuning.egg_fuse


func _physics_process(delta: float) -> void:
	match state:
		State.IDLE:
			# Yere dus
			velocity.y = minf(velocity.y + 700.0 * delta, 300.0)
			move_and_slide()
			if is_on_floor():
				state = State.FUSED
		State.FUSED:
			_fuse -= delta
			# Fiting yakinlastikca yanip soner
			sprite.modulate = Color(1.0, 0.5, 0.3) if int(_fuse * 8) % 2 == 0 \
				else Color(0.95, 0.9, 0.6)
			if _fuse <= 0.0:
				_explode()
		State.REFLECTED:
			velocity = Vector2(_reflect_dir * _tuning.egg_reflect_speed, -40)
			move_and_slide()
			# Fitil yansitmada da isler — patronu iskalayan yumurta ekran
			# disinda sonsuza ucmaz; duvara carpinca da patlar.
			_fuse -= delta
			if _fuse <= 0.0 or is_on_wall():
				_explode()


## Oyuncu vurusu: patrona geri yolla.
func take_damage(info: DamageInfo) -> void:
	if state == State.REFLECTED:
		return
	state = State.REFLECTED
	hurtbox.queue_free()  # artik vurulmaz
	sprite.modulate = Color(0.4, 1.0, 1.0)
	if boss != null and is_instance_valid(boss):
		_reflect_dir = int(signf(boss.global_position.x - global_position.x))
	if _reflect_dir == 0 and info.source != null:
		_reflect_dir = int(signf(global_position.x - info.source.global_position.x))
	if _reflect_dir == 0:
		_reflect_dir = 1
	# Patrona carptiginda hasar vermesi icin hitbox'i dusman katmanina ac;
	# katman 8'e gecmezse dusman hurtbox'lari (mask=8) onu hic goremez.
	hitbox.collision_layer = 8
	hitbox.collision_mask = 16
	var hc := hitbox.get_child(0).shape as CircleShape2D
	hc.radius = 8.0
	hitbox.activate(DamageInfo.make(_tuning.egg_reflect_damage, self,
		Vector2(_reflect_dir * 60, -30), false, false))
	hitbox.struck.connect(_on_reflected_struck, CONNECT_ONE_SHOT)


func _on_reflected_struck(_hb: Hurtbox) -> void:
	_explode()


func _explode() -> void:
	if state != State.REFLECTED:
		hitbox.collision_mask = 4
		hitbox.activate(DamageInfo.make(1, self, Vector2.ZERO, false, false))
	sprite.scale = Vector2(3, 3)
	sprite.modulate = Color(1.0, 0.8, 0.3, 0.9)
	FX.shake(2.0, 0.2)
	AudioManager.play_sfx(&"sfx/explosion", global_position)
	var tw := create_tween()
	tw.tween_property(sprite, "modulate:a", 0.0, 0.15)
	tw.finished.connect(queue_free)
