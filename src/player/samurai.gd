class_name Samurai
extends CharacterBody2D
## Oyuncu karakteri. Tum oynanis sayilari config/tuning.tres'ten gelir.
## Girdi InputSource uzerinden okunur — ayni govde Bolum 7'de
## AIInputSource ile final boss olarak surulur (DEVIN_PLAN §4.1).

const S_IDLE := &"idle"
const S_RUN := &"run"
const S_JUMP := &"jump"
const S_FALL := &"fall"
const S_DASH := &"dash"
const S_ATTACK := &"attack"
const S_AIR_ATTACK := &"air_attack"
const S_DOWN_ATTACK := &"down_attack"
const S_PARRY := &"parry"
const S_HURT := &"hurt"
const S_DEAD := &"dead"
const S_REST := &"rest"
const S_TRANSFORM := &"transform"
const S_CUTSCENE := &"cutscene"

const Locomotion := preload("res://src/player/state_machine/states/locomotion.gd")
const Combat := preload("res://src/player/state_machine/states/combat.gd")
const Defense := preload("res://src/player/state_machine/states/defense.gd")
const Meta := preload("res://src/player/state_machine/states/meta.gd")

## Testlerde veya sahnede farkli deger verilebilir.
@export var tuning: Tuning

var input: InputSource
var sm: StateMachine
var health: Health
var hurtbox: Hurtbox
var attack_hitbox: Hitbox
var down_hitbox: Hitbox
var sprite: Sprite2D
var col: CollisionShape2D
var form: FormData
var pending_form: StringName = &""
var form_time_left: float = 0.0  ## gecici formlar icin geri sayim
var jumps_used: int = 0

var facing: int = 1
var combo_index: int = 0
var combo_queued: bool = false

var coyote_timer: float = 0.0
var jump_buffer_timer: float = 0.0
var dash_cooldown: float = 0.0
var dash_dir: int = 1
var invuln_timer: float = 0.0
var parry_timer: float = 0.0
var parry_succeeded: bool = false

var _flash_timer: float = 0.0


func _ready() -> void:
	if tuning == null:
		tuning = load("res://config/tuning.tres")
	_build_nodes()
	if input == null:
		set_input_source(PlayerInputSource.new())
	elif input.get_parent() == null:
		add_child(input)
	sm = StateMachine.new()
	sm.name = "StateMachine"
	add_child(sm)
	sm.register_state(S_IDLE, Locomotion.Idle.new(self))
	sm.register_state(S_RUN, Locomotion.Run.new(self))
	sm.register_state(S_JUMP, Locomotion.Jump.new(self))
	sm.register_state(S_FALL, Locomotion.Fall.new(self))
	sm.register_state(S_DASH, Locomotion.Dash.new(self))
	sm.register_state(S_ATTACK, Combat.Attack.new(self))
	sm.register_state(S_AIR_ATTACK, Combat.AirAttack.new(self))
	sm.register_state(S_DOWN_ATTACK, Combat.DownAttack.new(self))
	sm.register_state(S_PARRY, Defense.Parry.new(self))
	sm.register_state(S_HURT, Defense.Hurt.new(self))
	sm.register_state(S_DEAD, Defense.Dead.new(self))
	sm.register_state(S_REST, Meta.Rest.new(self))
	sm.register_state(S_TRANSFORM, Meta.Transform.new(self))
	sm.register_state(S_CUTSCENE, Meta.Cutscene.new(self))
	var initial_form := FormLibrary.get_form(GameState.current_form)
	if initial_form == null:
		initial_form = FormLibrary.get_form(&"samurai")
	apply_form_data(initial_form)
	sm.change_to(S_IDLE)
	add_to_group(&"player")


func _build_nodes() -> void:
	collision_layer = 2
	collision_mask = 1  # sadece terrain

	col = CollisionShape2D.new()
	var capsule := CapsuleShape2D.new()
	capsule.radius = 5.0
	capsule.height = 18.0
	col.shape = capsule
	add_child(col)

	sprite = Sprite2D.new()
	sprite.texture = AssetLoader.texture(&"player/samurai/idle", Vector2i(12, 20))
	add_child(sprite)

	health = Health.new()
	health.max_health = tuning.max_health
	health.name = "Health"
	add_child(health)

	hurtbox = Hurtbox.new()
	hurtbox.name = "Hurtbox"
	hurtbox.collision_layer = 4
	hurtbox.collision_mask = 32  # enemy hitbox katmani
	var hb_col := CollisionShape2D.new()
	var hb_rect := RectangleShape2D.new()
	hb_rect.size = Vector2(12, 18)
	hb_col.shape = hb_rect
	hurtbox.add_child(hb_col)
	add_child(hurtbox)

	attack_hitbox = Hitbox.new()
	attack_hitbox.name = "AttackHitbox"
	attack_hitbox.collision_layer = 8
	attack_hitbox.collision_mask = 16  # enemy hurtbox katmani
	var at_col := CollisionShape2D.new()
	var at_rect := RectangleShape2D.new()
	at_rect.size = Vector2(18, 10)
	at_col.shape = at_rect
	attack_hitbox.add_child(at_col)
	attack_hitbox.position = Vector2(12, -2)
	attack_hitbox.struck.connect(_on_attack_struck)
	add_child(attack_hitbox)

	down_hitbox = Hitbox.new()
	down_hitbox.name = "DownHitbox"
	down_hitbox.collision_layer = 8
	down_hitbox.collision_mask = 16
	var dn_col := CollisionShape2D.new()
	var dn_rect := RectangleShape2D.new()
	dn_rect.size = Vector2(14, 8)
	dn_col.shape = dn_rect
	down_hitbox.add_child(dn_col)
	down_hitbox.position = Vector2(0, 12)
	down_hitbox.struck.connect(_on_down_struck)
	add_child(down_hitbox)


func set_input_source(src: InputSource) -> void:
	if input != null and input.get_parent() == self:
		remove_child(input)
		input.queue_free()
	input = src
	if input.get_parent() == null:
		add_child(input)


func _physics_process(delta: float) -> void:
	input.poll()

	# Ziplama buffer'i her frame guncellenir ki durumlar okuyabilsin.
	if input.jump_just_pressed():
		jump_buffer_timer = tuning.jump_buffer_time
	else:
		jump_buffer_timer = maxf(jump_buffer_timer - delta, 0.0)

	coyote_timer = tuning.coyote_time if is_on_floor() else maxf(coyote_timer - delta, 0.0)
	if is_on_floor():
		jumps_used = 0
	invuln_timer = maxf(invuln_timer - delta, 0.0)
	dash_cooldown = maxf(dash_cooldown - delta, 0.0)

	# Gecici form suresi: dolunca samuraya geri don ve kilidi kaldir.
	if form != null and form.duration > 0.0:
		form_time_left -= delta
		if form_time_left <= 0.0 and sm.current_name != S_TRANSFORM:
			var expired := form.id
			pending_form = &"samurai"
			sm.change_to(S_TRANSFORM, true)
			GameState.unlocked_forms.erase(expired)

	sm.physics_process(delta)
	move_and_slide()
	_update_facing()


func _process(delta: float) -> void:
	if _flash_timer > 0.0:
		_flash_timer -= delta
		if _flash_timer <= 0.0:
			sprite.modulate = form.sprite_color if form != null else Color.WHITE


func _update_facing() -> void:
	var dir := input.move_axis()
	if absf(dir) > 0.1 and sm.current_name in [S_IDLE, S_RUN, S_JUMP, S_FALL]:
		facing = 1 if dir > 0.0 else -1
	sprite.flip_h = facing < 0
	attack_hitbox.position.x = 12.0 * facing


# --- Durum yardimcilari (state'ler cagirir) ---

func apply_gravity(delta: float) -> void:
	var g_mult := form.gravity_mult
	if velocity.y > 0.0:
		g_mult *= form.hover_gravity_mult  # drone: yumusak dusus
	velocity.y = minf(velocity.y + tuning.gravity * g_mult * delta,
		tuning.max_fall_speed)


func apply_run(delta: float, dir: float) -> void:
	if absf(dir) > 0.1:
		var accel := tuning.ground_accel if is_on_floor() else tuning.air_accel
		velocity.x = move_toward(velocity.x, dir * tuning.run_speed * form.run_speed_mult,
			accel * delta)
	else:
		velocity.x = move_toward(velocity.x, 0.0, tuning.ground_decel * delta)


func try_jump() -> bool:
	if jump_buffer_timer <= 0.0:
		return false
	if coyote_timer > 0.0:
		velocity.y = -tuning.jump_velocity * form.jump_velocity_mult
		jump_buffer_timer = 0.0
		coyote_timer = 0.0
		return true
	# Havadayken ekstra ziplama (piksel sicramasi gibi form yetenegi).
	if jumps_used < form.max_air_jumps:
		jumps_used += 1
		velocity.y = -tuning.jump_velocity * form.jump_velocity_mult
		jump_buffer_timer = 0.0
		return true
	return false


func cut_jump() -> void:
	if velocity.y < 0.0:
		velocity.y *= tuning.jump_cut_multiplier


func start_dash() -> void:
	var dir := input.move_axis()
	dash_dir = int(signf(dir)) if absf(dir) > 0.1 else facing
	facing = dash_dir


func start_ground_attack() -> void:
	combo_index = 1
	combo_queued = false


func start_air_attack() -> void:
	pass


func start_down_attack() -> void:
	pass


func start_parry() -> void:
	pass


func ensure_attack_hitbox() -> void:
	if attack_hitbox.monitoring:
		return
	var kb := Vector2(facing * tuning.attack_knockback, -30.0)
	var dmg := int(round(tuning.player_damage * form.damage_mult))
	attack_hitbox.activate(DamageInfo.make(dmg, self, kb, false, false))


func ensure_down_hitbox() -> void:
	if down_hitbox.monitoring:
		return
	down_hitbox.activate(DamageInfo.make(tuning.player_damage, self, Vector2(0, 60), false, false))


func sprite_flash(color: Color) -> void:
	sprite.modulate = color
	_flash_timer = 0.09


# --- Vurus geri cagrilari ---

func _on_attack_struck(_hurtbox: Hurtbox) -> void:
	FX.hitstop(tuning.hitstop_normal)
	FX.shake(tuning.shake_light, tuning.shake_duration)


func _on_down_struck(hb: Hurtbox) -> void:
	if sm.current_name != S_DOWN_ATTACK or not hb.pogoable:
		return
	velocity.y = -tuning.jump_velocity * tuning.pogo_factor
	invuln_timer = maxf(invuln_timer, 0.25)  # ayni frame diken hasarini yeme
	FX.hitstop(tuning.hitstop_normal)
	FX.shake(tuning.shake_light, tuning.shake_duration)
	sm.change_to(S_JUMP, true)


func take_damage(info: DamageInfo) -> void:
	if sm.current_name == S_DEAD:
		return
	# Parry penceresi: parryable vurus hasar yerine kivilcim + sersemletme.
	if sm.current_name == S_PARRY and parry_timer > 0.0 and info.parryable:
		_on_parry_success(info)
		return
	if invuln_timer > 0.0:
		return
	if sm.current_name == S_DASH and form.dash_iframes:
		return
	health.take(info.damage)
	invuln_timer = tuning.hurt_invuln_time
	var kb_scale := 1.0 - form.knockback_resist
	var dir := 1.0
	if info.source != null:
		dir = signf(global_position.x - info.source.global_position.x)
		if dir == 0.0:
			dir = -facing
	velocity = Vector2(dir * tuning.hurt_knockback * kb_scale,
		-tuning.hurt_knockback * 0.5 * kb_scale)
	EventBus.damage_dealt.emit(self, info)
	FX.hitstop(tuning.hitstop_normal)
	FX.shake(tuning.shake_heavy, tuning.shake_duration)
	if health.is_alive():
		sm.change_to(S_HURT, true)
	else:
		sm.change_to(S_DEAD, true)
		EventBus.actor_died.emit(self)


func _on_parry_success(info: DamageInfo) -> void:
	parry_succeeded = true
	var spark_pos := hurtbox.global_position + Vector2(facing * 8.0, -4.0)
	FX.spark(spark_pos)
	FX.hitstop(tuning.hitstop_parry)
	FX.shake(tuning.shake_light, tuning.shake_duration)
	EventBus.parry_succeeded.emit(spark_pos)
	if info.source != null and info.source.has_method("on_parried"):
		info.source.on_parried()


func is_alive() -> bool:
	return health.is_alive()


# --- Form sistemi (M2) ---

## Sonraki/onceki acik forma gecis istegi; TRANSFORM durumu uygular.
func cycle_form(step: int) -> bool:
	var ids := GameState.unlocked_forms
	if ids.size() < 2:
		return false
	var idx := ids.find(form.id)
	if idx < 0:
		idx = 0
	var next_id: StringName = ids[(idx + step) % ids.size()]
	if next_id == form.id:
		return false
	pending_form = next_id
	return true


## Disaridan form tak (boss odulu, gecici form): unlocked ise donusum baslar.
func equip_form(id: StringName) -> bool:
	if not GameState.unlocked_forms.has(id) or form.id == id:
		return false
	pending_form = id
	if sm.current_name not in [S_TRANSFORM, S_CUTSCENE, S_DEAD]:
		sm.change_to(S_TRANSFORM, true)
	return true


## TRANSFORM durumu cikisinda cagrilir: bekleyen formu uygular.
func apply_pending_form() -> void:
	if pending_form == &"":
		return
	var f := FormLibrary.get_form(pending_form)
	pending_form = &""
	if f != null:
		apply_form_data(f)


func apply_form_data(f: FormData) -> void:
	form = f
	form_time_left = f.duration
	var cap := col.shape as CapsuleShape2D
	cap.radius = form.body_size.x / 2.0
	cap.height = form.body_size.y
	var hb := hurtbox.get_child(0).shape as RectangleShape2D
	hb.size = form.body_size + Vector2(2, 2)
	sprite.texture = AssetLoader.texture(
		&"player/%s/idle" % form.id, Vector2i(form.body_size))
	sprite.modulate = form.sprite_color
	GameState.set_form(form.id)
