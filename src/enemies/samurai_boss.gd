class_name SamuraiBoss
extends BossBase
## Bolum 7 final boss'u — oyuncunun pesine dustugu samurayin kendisi.
## player/samurai/* sheet'lerini kullanir (ayni animasyonlar, basinda
## kasa). Saldirilari oyuncunun hareket setini yansitir: yaklasma,
## telegraph -> kilic savrulusu, dash-gecisi, ara ara parry-durusu.
## F2 (%50): daha hizli + cift savrulus.

enum BState { SLEEP, APPROACH, TELL, SLASH, DASH_THROUGH, PARRY_STANCE, GAP }

var bstate := BState.SLEEP
var _t := 0.0
var _player: Node2D
var facing := -1
var _slash_hitbox: Hitbox
var _combo := 0
var arena_root: Node2D
var arena_left := 0.0
var arena_right := 0.0


func _init() -> void:
	max_hp = 26
	body_size = Vector2(14, 20)
	contact_damage = false
	asset_key = &"final_samurai"
	phase_thresholds = [0.5]


func _ready() -> void:
	super._ready()
	# Kasa — final boss samurayin tam hali
	if AssetLoader.has_asset(&"prop/hat"):
		var hat := Sprite2D.new()
		hat.texture = AssetLoader.texture(&"prop/hat", Vector2i(22, 12))
		hat.position = Vector2(0, -body_size.y * 0.62)
		add_child(hat)
	_slash_hitbox = Hitbox.new()
	_slash_hitbox.collision_layer = 32
	_slash_hitbox.collision_mask = 4
	var col := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(18, 16)
	col.shape = rect
	_slash_hitbox.add_child(col)
	add_child(_slash_hitbox)
	_slash_hitbox.deactivate()


func on_activated() -> void:
	bstate = BState.APPROACH
	_t = 1.2
	Pictogram.show_on(self, &"alarm", 1.2, Vector2(0, -30))


func on_reset() -> void:
	bstate = BState.SLEEP
	_t = 0.0
	_player = null
	_combo = 0
	_atk_tick = 0
	_slash_hitbox.deactivate()


func on_phase_changed(_p: int) -> void:
	FX.glitch(1.0, 0.8)
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
	_t -= delta
	var speed := 42.0 if phase >= 1 else 32.0

	match bstate:
		BState.APPROACH:
			velocity.x = facing * speed
			if _t <= 0.0:
				_choose(dx)
		BState.TELL:
			velocity.x = 0.0
			var c := Color(1.5, 1.2, 0.7)
			sprite.modulate = c
			if anims != null:
				anims.modulate = c
			if _t <= 0.0:
				_do_slash()
		BState.SLASH:
			velocity.x = facing * 60.0
			if _t <= 0.0:
				_slash_hitbox.deactivate()
				_combo += 1
				# F2'de ikinci savrulus zincirlenir
				if phase >= 1 and _combo % 2 == 1:
					bstate = BState.TELL
					_t = 0.3
				else:
					bstate = BState.GAP
					_t = 1.0 if phase >= 1 else 1.4
		BState.DASH_THROUGH:
			velocity.x = facing * 190.0
			if _t <= 0.0:
				bstate = BState.GAP
				_t = 0.9
		BState.PARRY_STANCE:
			velocity.x = 0.0
			var c := Color(0.7, 0.9, 1.6)
			sprite.modulate = c
			if anims != null:
				anims.modulate = c
			if _t <= 0.0:
				sprite.modulate = Color.WHITE
				if anims != null:
					anims.modulate = Color.WHITE
				bstate = BState.GAP
				_t = 0.8
		BState.GAP:
			velocity.x = move_toward(velocity.x, 0.0, 700.0 * delta)
			if _t <= 0.0:
				bstate = BState.APPROACH
				_t = 1.2


func _choose(dx: float) -> void:
	_atk_tick += 1
	var pick := _atk_tick % 4
	match pick:
		0, 2:
			if absf(dx) < 46.0:
				bstate = BState.TELL
				_t = 0.45
			else:
				_start_dash()
		1:
			_start_dash()
		_:
			if phase >= 1:
				bstate = BState.PARRY_STANCE
				_t = 0.9
			else:
				bstate = BState.TELL
				_t = 0.45


var _atk_tick := 0


func _do_slash() -> void:
	bstate = BState.SLASH
	_t = 0.28
	sprite.modulate = Color.WHITE
	if anims != null:
		anims.modulate = Color.WHITE
	play_anim(&"attack", 0.4)
	_slash_hitbox.position.x = facing * 12.0
	_slash_hitbox.activate(DamageInfo.make(
		1, self, Vector2(facing * 130.0, -50.0), true, true))
	AudioManager.play_sfx(&"sfx/attack", global_position)


func _start_dash() -> void:
	bstate = BState.DASH_THROUGH
	_t = 0.35
	AudioManager.play_sfx(&"sfx/dash", global_position)


## Parry durusu sirasinda onden gelen vuruslar kivilcimlanir.
func take_damage(info: DamageInfo) -> void:
	if bstate == BState.PARRY_STANCE and info.source != null:
		var dx := info.source.global_position.x - global_position.x
		if (dx > 0) == (facing > 0):
			FX.spark(hurtbox.global_position + Vector2(facing * 6, -4))
			FX.hitstop(0.05)
			AudioManager.play_sfx(&"sfx/parry", global_position)
			return
	super.take_damage(info)
