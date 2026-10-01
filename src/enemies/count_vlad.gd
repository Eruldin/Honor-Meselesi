class_name CountVlad
extends BossBase
## Bolum 3 boss'u: Kont Vlad. Faz 1: kan kaziklari + eskrim lungi
## (parry'lenebilir). Faz 2 (can <= %50): ekran kararir — Vlad karanlikta
## saldirir; yon ipucu GORSEL: gozleri parlar + saldiri yonunu gosteren
## ok/isaret (DEVIN_PLAN M6 — stereo ses yerine gorsel alternatif).
## Olum -> Golge/Yarasa formu (i-frame dash).

enum State { SLEEP, APPROACH, SPIKES, LUNGE_TELL, LUNGE, GAP }

var bstate := State.SLEEP
var _t := 0.0
var _player: Node2D
var facing := -1
var darkness: ColorRect        ## faz 2 karanlik ortusu
var eyes: Node2D               ## karanlikta parlayan gozler
var arena_root: Node2D
var _atk_idx := 0


func _init() -> void:
	max_hp = 16
	body_size = Vector2(16, 26)
	contact_damage = true
	asset_key = &"count_vlad"
	phase_thresholds = [0.5]


func _phase_color() -> Color:
	return Color(0.6, 0.3, 0.6) if phase == 0 else Color(0.4, 0.2, 0.45)


func _restore_modulate() -> void:
	var c := _phase_color()
	sprite.modulate = c
	if anims != null:
		anims.modulate = c


func _ready() -> void:
	super._ready()
	if not using_real_sprite:
		sprite.modulate = _phase_color()
	contact_hitbox.activate(DamageInfo.make(1, self, Vector2.ZERO, true, true))
	# Karanlikta gorunen gozler
	eyes = Node2D.new()
	eyes.position = Vector2(0, -10)
	add_child(eyes)
	for dx in [-3.0, 3.0]:
		var e := ColorRect.new()
		e.size = Vector2(2, 2)
		e.position = Vector2(dx - 1, 0)
		e.color = Color(1.0, 0.2, 0.3)
		eyes.add_child(e)


func on_activated() -> void:
	bstate = State.APPROACH
	Pictogram.show_on(self, &"alarm", 1.0, Vector2(0, -24))


func on_phase_changed(_p: int) -> void:
	# Faz 2: karanlik ortu — stereo ses alternatifi olarak gozler parlar.
	_restore_modulate()
	FX.glitch(0.7, 0.6)
	FX.shake(3.0, 0.4)
	AudioManager.play_sfx(&"sfx/ghost", global_position, -4.0, 0.7)
	_spawn_darkness()


func _spawn_darkness() -> void:
	if darkness != null:
		return
	# CanvasLayer kullanilamaz: dunya-uzayi dugumlerinin z_index'i layer'i
	# asamaz — gozler karanlikta kaybolurdu. Buyuk dunya rect'i Vlad'la
	# hareket eder; gozler z=10 ile ustte kalir (yon ipucu).
	darkness = ColorRect.new()
	darkness.color = Color(0, 0, 0, 0.82)
	darkness.mouse_filter = Control.MOUSE_FILTER_IGNORE
	darkness.size = Vector2(2400, 1400)
	darkness.position = Vector2(-1200, -700)
	darkness.z_index = 5
	add_child(darkness)
	# Gozler karanligin ustunde kalsin
	eyes.z_index = 10


func on_reset() -> void:
	bstate = State.SLEEP
	_t = 0.0
	_player = null
	_atk_idx = 0
	if not using_real_sprite:
		sprite.modulate = _phase_color()
	elif anims != null:
		anims.modulate = Color.WHITE
	if darkness != null:
		darkness.queue_free()
		darkness = null
	eyes.z_index = 0


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
	eyes.position.x = facing * 2.0
	_t -= delta
	var speed := tuning.vlad_p2_speed if phase >= 1 else tuning.vlad_speed
	var gap := tuning.vlad_attack_gap_p2 if phase >= 1 else tuning.vlad_attack_gap

	match bstate:
		State.APPROACH:
			velocity.x = facing * speed
			if _t <= 0.0:
				_choose(dx)
		State.SPIKES:
			velocity.x = 0.0
			if _t <= 0.0:
				_spawn_spikes()
				bstate = State.GAP
				_t = gap
		State.LUNGE_TELL:
			velocity.x = 0.0
			var c := Color(1.3, 0.4, 0.4)
			sprite.modulate = c
			if anims != null:
				anims.modulate = c
			if _t <= 0.0:
				bstate = State.LUNGE
				_t = 0.25
				_restore_modulate()
				velocity.x = facing * tuning.vlad_lunge_speed
				contact_hitbox.activate(DamageInfo.make(1, self,
					Vector2(facing * 180, -50), true, false))
		State.LUNGE:
			if _t <= 0.0:
				bstate = State.GAP
				_t = gap
		State.GAP:
			velocity.x = move_toward(velocity.x, 0.0, 700.0 * delta)
			if _t <= 0.0:
				bstate = State.APPROACH
				_t = 1.6


func _choose(dx: float) -> void:
	var pick := _atk_idx % 2
	_atk_idx += 1
	if absf(dx) < 50.0:
		pick = 1  # yakinsa eskrim
	match pick:
		0:
			bstate = State.SPIKES
			_t = tuning.vlad_telegraph
		_:
			bstate = State.LUNGE_TELL
			_t = tuning.vlad_telegraph


func _spawn_spikes() -> void:
	# Oyuncu cizgisinde 3 kazik (merkez + iki yan)
	for off in [-30.0, 0.0, 30.0]:
		var s := BloodSpike.new()
		s.global_position = Vector2(_player.global_position.x + off, _player.global_position.y + 10)
		s.add_to_group(&"boss_spawn")
		_root().add_child(s)


func _root() -> Node:
	return arena_root if arena_root != null else get_parent()
