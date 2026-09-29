class_name Unit0
extends BossBase
## Bolum 2 boss'u: agir zirhli makine. Uc saldiri: elektrik dalgasi
## (yer sok dalgasi), gudumlu fuze, hidrolik yumruk (PARRY'LENEBILIR —
## parry zirhi kirar ve kisa sure hasar alir).
## Zirhli iken dogrudan vuruslar seker (0 hasar). Olum -> Robot formu.

enum State { SLEEP, APPROACH, PUNCH_TELL, PUNCH, WAVE, MISSILE, GAP }

var bstate := State.SLEEP
var _t := 0.0
var _player: Node2D
var facing := -1
var armor_broken := false
var _armor_timer := 0.0
var _atk_idx := 0
var punch_hitbox: Hitbox

var arena_root: Node2D


func _init() -> void:
	max_hp = 18
	body_size = Vector2(28, 36)
	asset_key = &"bot"
	contact_damage = true
	phase_thresholds = [0.5]


func _ready() -> void:
	super._ready()
	sprite.modulate = Color(0.55, 0.65, 0.8)
	contact_hitbox.activate(DamageInfo.make(1, self, Vector2.ZERO, true, true))
	punch_hitbox = Hitbox.new()
	punch_hitbox.collision_layer = 32
	punch_hitbox.collision_mask = 4
	var col := CollisionShape2D.new()
	var r := RectangleShape2D.new()
	r.size = Vector2(26, 16)
	col.shape = r
	punch_hitbox.add_child(col)
	punch_hitbox.position = Vector2(20, -4)
	add_child(punch_hitbox)
	punch_hitbox.deactivate()


func on_activated() -> void:
	bstate = State.APPROACH
	Pictogram.show_on(self, &"alarm", 1.0, Vector2(0, -28))


func on_phase_changed(_p: int) -> void:
	sprite.modulate = Color(0.9, 0.5, 0.5)
	FX.glitch(0.6, 0.5)
	FX.shake(3.0, 0.4)


func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	if not active or not health.is_alive():
		return
	if _player == null:
		_player = get_tree().get_first_node_in_group(&"player")
		return
	var dx: float = _player.global_position.x - global_position.x
	facing = 1 if dx > 0 else -1
	sprite.flip_h = facing < 0
	punch_hitbox.position.x = 20.0 * facing
	_t -= delta
	_armor_timer = maxf(_armor_timer - delta, 0.0)
	if _armor_timer <= 0.0 and armor_broken:
		armor_broken = false
		sprite.modulate = Color(0.55, 0.65, 0.8) if phase == 0 else Color(0.9, 0.5, 0.5)

	var speed := tuning.unit0_p2_speed if phase >= 1 else tuning.unit0_hp_p1_speed
	var gap := tuning.unit0_attack_gap_p2 if phase >= 1 else tuning.unit0_attack_gap

	match bstate:
		State.APPROACH:
			velocity.x = facing * speed
			if _t <= 0.0:
				_choose_attack(dx)
		State.PUNCH_TELL:
			velocity.x = 0.0
			sprite.modulate = Color(1.4, 1.0, 0.3)
			if _t <= 0.0:
				bstate = State.PUNCH
				_t = 0.22
				sprite.modulate = Color(0.55, 0.65, 0.8)
				punch_hitbox.activate(DamageInfo.make(2, self,
					Vector2(facing * 220, -60), true, false))
				velocity.x = facing * tuning.unit0_punch_speed
		State.PUNCH:
			if _t <= 0.0:
				punch_hitbox.deactivate()
				bstate = State.GAP
				_t = gap
		State.WAVE:
			velocity.x = 0.0
			if _t <= 0.0:
				for dir in [-1, 1]:
					var w := Shockwave.new()
					w.direction = dir
					w.global_position = global_position + Vector2(dir * 16, 12)
					_root().add_child(w)
				bstate = State.GAP
				_t = gap
		State.MISSILE:
			velocity.x = 0.0
			if _t <= 0.0:
				var m := HomingMissile.new()
				m.global_position = global_position + Vector2(facing * 10, -20)
				_root().add_child(m)
				bstate = State.GAP
				_t = gap
		State.GAP:
			velocity.x = move_toward(velocity.x, 0.0, 700.0 * delta)
			if _t <= 0.0:
				bstate = State.APPROACH
				_t = 2.0


func _choose_attack(dx: float) -> void:
	var pick := _atk_idx % 3
	_atk_idx += 1
	# Yakinsa yumruk tercihi
	if absf(dx) < 70.0 and pick != 1:
		pick = 0
	match pick:
		0:
			bstate = State.PUNCH_TELL
			_t = tuning.unit0_telegraph
		1:
			bstate = State.WAVE
			_t = 0.4
		_:
			bstate = State.MISSILE
			_t = 0.35


## Zirh: kirilmadikca hicbir dogrudan vurus gecmez (parry punch kirar).
func take_damage(info: DamageInfo) -> void:
	if not active or not health.is_alive():
		return
	if armor_broken:
		super.take_damage(info)
	else:
		FX.spark(hurtbox.global_position + Vector2(facing * -10, -8))
		FX.hitstop(0.03)


## Oyuncu hidrolik yumrugu parry'ledi — zirh catlar.
func on_parried() -> void:
	armor_broken = true
	_armor_timer = tuning.unit0_armor_break_time
	stagger_timer = tuning.parry_stagger
	punch_hitbox.deactivate()
	bstate = State.GAP
	_t = 1.2
	sprite.modulate = Color(0.3, 1.0, 0.6)
	FX.spark(hurtbox.global_position)
	FX.glitch(0.5, 0.4)


func _root() -> Node:
	return arena_root if arena_root != null else get_parent()
