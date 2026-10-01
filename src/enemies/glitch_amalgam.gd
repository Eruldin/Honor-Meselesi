class_name GlitchAmalgam
extends BossBase
## Bolum 6 boss'u — Glitch Amalgam (big_zombie sprite'lari, cyan glitch
## tonu). Onceki boss'larin bellek yankilari: sok dalgasi (Cluck),
## kan-dikeni serisi (Vlad), gudumlu fuzeler (Unit-0), piksel yagmuru
## (Tiran). M9 spec: 4 faz — her faz bir formla kirilir
## (Robot → Tavuk → Golge → Piksel/havadaki vurus); yanlis vurus clang
## + swap piktogrami (gargoyle/terminal ile ayni dil). Beyaz patlamayla
## bitis.

enum AState { SLEEP, APPROACH, TELL, SLAM_RISE, SLAM_FALL, CAST, GAP }

const PHASE_FORMS: Array[StringName] = [&"robot", &"tavuk", &"golge", &"piksel"]
const PHASE_TINTS: Array[Color] = [
	Color(0.72, 0.78, 0.92),   # robot — celik bellek
	Color(1.15, 0.95, 0.55),   # tavuk — kanat bellegi
	Color(0.55, 0.4, 0.95),    # golge — karanlik bellek
	Color(1.1, 0.6, 1.3),      # piksel — kirilgan bellek
]

var bstate := AState.SLEEP
var _t := 0.0
var _player: Node2D
var facing := -1
var _atk_idx := 0
var _rain: PixelRain
var arena_root: Node2D
var arena_left := 0.0
var arena_right := 0.0
var floor_y := 250.0


func _init() -> void:
	max_hp = 22
	body_size = Vector2(24, 27)
	contact_damage = true
	asset_key = &"glitch_amalgam"
	phase_thresholds = [0.75, 0.5, 0.25]


func _phase_tint() -> Color:
	return PHASE_TINTS[mini(phase, PHASE_TINTS.size() - 1)]


func required_form() -> StringName:
	return PHASE_FORMS[mini(phase, PHASE_FORMS.size() - 1)]


func _ready() -> void:
	super._ready()
	# Glitch tonu — fazin form-bellek renginde
	sprite.modulate = _phase_tint()
	if anims != null:
		anims.modulate = _phase_tint()
	contact_hitbox.activate(DamageInfo.make(1, self, Vector2.ZERO, true, true))
	_rain = PixelRain.new()
	if get_parent() != null:
		get_parent().add_child(_rain)


func _exit_tree() -> void:
	if is_instance_valid(_rain):
		_rain.queue_free()


func on_activated() -> void:
	bstate = AState.APPROACH
	_t = 1.6
	_rain.area_left = arena_left
	_rain.area_right = arena_right
	Pictogram.show_on(self, &"alarm", 1.0, Vector2(0, -36))
	FX.glitch(1.0, 0.8)


func on_reset() -> void:
	bstate = AState.SLEEP
	_t = 0.0
	_player = null
	_atk_idx = 0
	sprite.modulate = _phase_tint()
	if anims != null:
		anims.modulate = _phase_tint()
	if _rain != null and is_instance_valid(_rain):
		_rain.active = false


func on_phase_changed(_p: int) -> void:
	var c := _phase_tint()
	sprite.modulate = c
	if anims != null:
		anims.modulate = c
	FX.glitch(1.0, 0.9)
	FX.shake(3.5, 0.5)
	# Yeni faz = yeni form sarti — kelimesiz ipucu
	Pictogram.show_on(self, &"swap", 1.4, Vector2(0, -body_size.y - 12))


## M9 form kapisi: yanlis form/yerde vurus seker (clang + swap ipucu).
## Oyuncu gerekli forma sahip degilse kapi kalkar (guvenlik agi —
## normal akista ch6'da hepsi acik olur). Piksel fazinda yerdeki
## vurus seker; havada olan her vurus sayilir.
func _gate_blocks(info: DamageInfo) -> bool:
	var sam := info.source as Samurai
	if sam == null or sam.form == null:
		return false
	var req := required_form()
	if req == &"piksel":
		return sam.is_on_floor()
	if not GameState.unlocked_forms.has(req):
		return false
	return sam.form.id != req


func take_damage(info: DamageInfo) -> void:
	if not active or not health.is_alive():
		return
	if _gate_blocks(info):
		AudioManager.play_sfx(&"sfx/clang", global_position)
		FX.spark(global_position + Vector2(0, -body_size.y * 0.4))
		Pictogram.show_on(self, &"swap", 0.9, Vector2(0, -body_size.y - 12))
		return
	super.take_damage(info)


func _on_died() -> void:
	# M9 spec: beyaz patlamayla bitis — CRT beyazla karar
	FX.glitch(1.6, 1.4)
	FX.shake(4.0, 0.5)
	super._on_died()


func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	if not active or not health.is_alive() or _parry_frozen(delta):
		return
	if _player == null:
		_player = get_tree().get_first_node_in_group(&"player")
		return
	var dx: float = _player.global_position.x - global_position.x
	facing = 1 if dx > 0 else -1
	sprite.flip_h = facing < 0
	_t -= delta
	var speed := 24.0 if phase >= 1 else 18.0
	var gap := 0.9 if phase >= 1 else 1.3

	match bstate:
		AState.APPROACH:
			velocity.x = facing * speed
			if _t <= 0.0:
				_choose()
		AState.TELL:
			velocity.x = 0.0
			var tell := _phase_tint() * 1.4
			sprite.modulate = tell
			if anims != null:
				anims.modulate = tell
			if _t <= 0.0:
				bstate = AState.SLAM_RISE
				_t = 0.45
				sprite.modulate = _phase_tint()
				if anims != null:
					anims.modulate = _phase_tint()
		AState.SLAM_RISE:
			velocity.x = facing * 30.0
			velocity.y = -240.0
			if _t <= 0.0:
				bstate = AState.SLAM_FALL
				velocity.y = 60.0
		AState.SLAM_FALL:
			velocity.y = minf(velocity.y + 1500.0 * delta, 540.0)
			if is_on_floor():
				_land()
				bstate = AState.GAP
				_t = gap
		AState.CAST:
			velocity.x = 0.0
			if _t <= 0.0:
				bstate = AState.GAP
				_t = gap
		AState.GAP:
			velocity.x = move_toward(velocity.x, 0.0, 600.0 * delta)
			if _t <= 0.0:
				bstate = AState.APPROACH
				_t = 1.5


func _choose() -> void:
	var pick := _atk_idx % 4
	_atk_idx += 1
	match pick:
		0:  # Cluck yankisi — slam
			bstate = AState.TELL
			_t = 0.55
		1:  # Vlad yankisi — diken serisi
			_cast_spikes()
			bstate = AState.CAST
			_t = 1.6
		2:  # Unit-0 yankisi — fuze savulu
			_cast_volley()
			bstate = AState.CAST
			_t = 1.4
		_:  # Tiran yankisi — piksel yagmuru (kisa)
			_rain.active = true
			FX.glitch(0.5, 0.4)
			bstate = AState.CAST
			_t = 2.0


func _land() -> void:
	FX.shake(3.5, 0.35)
	AudioManager.play_sfx(&"sfx/explosion", global_position, -4.0, 0.8)
	for d in [-1, 1]:
		var w := Shockwave.new()
		w.direction = d
		w.global_position = global_position + Vector2(d * 12, 8)
		w.add_to_group(&"boss_spawn")
		_root().add_child(w)


func _cast_spikes() -> void:
	var n := 5 if phase >= 1 else 3
	for i in n:
		var sp := BloodSpike.new()
		sp.global_position = Vector2(
			clampf(_player.global_position.x + (i - n / 2) * 30.0,
				arena_left + 12.0, arena_right - 12.0),
			floor_y)
		sp.add_to_group(&"boss_spawn")
		_root().add_child(sp)
		sp.get_node("warn").color = Color(0.4, 1.0, 1.0, 0.5)
		sp.get_node("spike").modulate = Color(0.5, 0.9, 1.1)


func _cast_volley() -> void:
	# Uc gudumlu fuze — ustten ve yandan
	for i in 3:
		var m := HomingMissile.new()
		m.global_position = global_position + Vector2(0, -30 - i * 16)
		m.sender = self
		m.add_to_group(&"boss_spawn")
		_root().add_child(m)
	FX.glitch(0.4, 0.3)


func _process(delta: float) -> void:
	# PixelRain suresi dolunca kapat (CAST sayacina gore)
	if _rain != null and _rain.active and bstate != AState.CAST:
		_rain.active = false


func _root() -> Node:
	return arena_root if arena_root != null else get_parent()
