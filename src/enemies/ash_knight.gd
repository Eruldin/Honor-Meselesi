class_name AshKnight
extends Samurai
## B5 "kul sovalyesi" — oyuncu govdesi AIInputSource ile surulen ayna
## dusman: kosar, ziplayip saldirir, yakin vurusa parry dener.
## M10: "AIInputSource kullanir, oyuncunun hareketlerini taklit eder".

const AGGRO_RANGE := 190.0
const ATTACK_RANGE := 26.0
const PARRY_RANGE := 40.0
const DASH_RANGE := 95.0

var _ai: AIInputSource
var _target: Node2D
var _think := 0.0
var _dying := false


func _init() -> void:
	_ai = AIInputSource.new()
	input = _ai


func _ready() -> void:
	# Oyuncu tuning'inin bir kopyasi — biraz agir/duzgun bir ayna.
	if tuning == null:
		tuning = load("res://config/tuning.tres").duplicate()
		tuning.run_speed *= 0.82
		tuning.dash_cooldown *= 1.8
		tuning.jump_velocity *= 0.92
		tuning.hurt_invuln_time = 0.5
	super._ready()
	remove_from_group(&"player")
	# Savas katmanlari dusmana cevrilir: govde/hurtbox dusman,
	# saldiri hitbox'lari oyuncu hurtbox'unu vurur.
	collision_layer = 64
	collision_mask = 1
	hurtbox.collision_layer = 16
	hurtbox.collision_mask = 8
	for hb in [attack_hitbox, down_hitbox, up_hitbox]:
		hb.collision_layer = 32
		hb.collision_mask = 4
	health.max_health = 4
	health.reset()
	# Kul goruntusu: kor-turuncu tona cekilmis samurai sheet'i.
	# (_anims sadece sheet asset'i varken olusur — assetsiz ortamda sprite'a kalir.)
	var ash := Color(1.05, 0.72, 0.5, 1.0)
	sprite.modulate = ash
	if _anims != null:
		_anims.modulate = ash
		_anims.speed_scale = 0.9


func _physics_process(delta: float) -> void:
	_brain(delta)
	super._physics_process(delta)
	# Olum sonrasi: govde bir sure kalip kul gibi dagilir.
	if _dying:
		modulate.a = maxf(modulate.a - delta * 1.1, 0.0)
		if modulate.a <= 0.0:
			queue_free()


func _brain(delta: float) -> void:
	if _dying or sm == null or sm.current_name == S_DEAD:
		_ai.axis(0.0)
		return
	if not is_instance_valid(_target):
		_target = get_tree().get_first_node_in_group(&"player") as Node2D
	if _target == null or not (_target is Samurai and (_target as Samurai).health.is_alive()):
		_ai.axis(0.0)
		return
	var dx: float = _target.global_position.x - global_position.x
	var dist := absf(dx)
	if dist > AGGRO_RANGE:
		_ai.axis(0.0)
		return
	_think -= delta
	# Menzil disinda kos; cok uzaksa arada dash ile kapat.
	var dir := signf(dx)
	if dist > ATTACK_RANGE:
		_ai.axis(dir)
		if _think <= 0.0:
			_think = 0.18
			if dist > DASH_RANGE and is_on_floor() and randf() < 0.3:
				_ai.tap(&"dash")
			elif (_target.global_position.y < global_position.y - 34.0
					and is_on_floor() and randf() < 0.5):
				_ai.tap(&"jump")
	else:
		_ai.axis(0.0)
		if _think <= 0.0:
			_think = 0.16
			# Oyuncu vurusa girdiyse arada parry dene — ayna hissi.
			var p := _target as Samurai
			if dist < PARRY_RANGE and randf() < 0.3 \
					and p.sm.current_name in [S_ATTACK, S_AIR_ATTACK,
						S_DOWN_ATTACK, S_UP_ATTACK]:
				_ai.tap(&"parry")
			else:
				_ai.tap(&"attack")


## Dusman surumu: oyuncunun agir shake/vignette geri bildirimini verme —
## kivilcim + hafif hitstop + ruh (damage_dealt) yeter.
func take_damage(info: DamageInfo) -> void:
	if sm.current_name == S_DEAD:
		return
	if sm.current_name == S_PARRY and parry_timer > 0.0 and info.parryable:
		_on_parry_success(info)
		return
	if invuln_timer > 0.0:
		return
	health.take(info.damage)
	invuln_timer = tuning.hurt_invuln_time
	AudioManager.play_sfx(&"sfx/hit", global_position)
	var dir := 1.0
	if info.source != null:
		dir = signf(global_position.x - info.source.global_position.x)
		if dir == 0.0:
			dir = -facing
	velocity = Vector2(dir * tuning.hurt_knockback * (1.0 - form.knockback_resist),
		-tuning.hurt_knockback * 0.4)
	EventBus.damage_dealt.emit(self, info)
	FX.hitstop(tuning.hitstop_normal)
	if health.is_alive():
		sm.change_to(S_HURT, true)
	else:
		_die()


func _die() -> void:
	_dying = true
	sm.change_to(S_DEAD, true)
	set_deferred("collision_layer", 0)
	set_deferred("collision_mask", 0)
	for hb in [attack_hitbox, down_hitbox, up_hitbox, hurtbox]:
		hb.set_deferred("collision_layer", 0)
		hb.set_deferred("collision_mask", 0)
	AudioManager.play_sfx(&"sfx/ghost", global_position)
	EventBus.actor_died.emit(self)


## Soylu'nun parry'si: oyuncu icin soul odulu emit etme (parry_succeeded
## sinyali oyuncunun basarisina aittir); geri kalan geri bildirim ayni.
func _on_parry_success(info: DamageInfo) -> void:
	parry_succeeded = true
	var spark_pos := hurtbox.global_position + Vector2(facing * 8.0, -4.0)
	FX.spark(spark_pos)
	FX.hitstop(tuning.hitstop_parry)
	FX.shake(tuning.shake_light, tuning.shake_duration)
	AudioManager.play_sfx(&"sfx/parry", global_position)
	if info.source != null and info.source.has_method("on_parried"):
		info.source.on_parried()
