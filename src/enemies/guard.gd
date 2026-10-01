class_name Guard
extends EnemyBase
## Bolum 1 kalkanli muhafiz: onden gelen vuruslari bloklar (kivilcim, hasar
## yok); arkadan ya da saldiri animasyonu sirasinda vurulabilir.
## Periyodik olarak telegraph (parlaklik) -> kisa lunge saldirisi yapar.

enum GState { APPROACH, TELEGRAPH, LUNGE, RECOVER }

var gstate := GState.APPROACH
var _t := 0.0
var _player: Node2D
var facing := -1
var _hint_shown := false


func _init() -> void:
	max_hp = 3
	body_size = Vector2(14, 20)
	asset_key = &"guard"


func _ready() -> void:
	super._ready()
	if not using_real_sprite:
		sprite.modulate = Color(0.5, 0.6, 0.9)
	# Kalkan hitbox — temas hasari yok ama oyuncuyu iter
	contact_hitbox = Hitbox.new()
	contact_hitbox.collision_layer = 32
	contact_hitbox.collision_mask = 4
	var ch_col := CollisionShape2D.new()
	var ch_rect := RectangleShape2D.new()
	ch_rect.size = body_size + Vector2(4, 4)
	ch_col.shape = ch_rect
	contact_hitbox.add_child(ch_col)
	add_child(contact_hitbox)
	# Temas hitbox'i sadece lunge sirasinda aktif
	contact_hitbox.deactivate()


func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	if not health.is_alive():
		return
	if is_staggered():
		contact_hitbox.deactivate()
		gstate = GState.RECOVER
		_t = 0.5
		return
	if _player == null:
		_player = get_tree().get_first_node_in_group(&"player")
		return
	var dx: float = _player.global_position.x - global_position.x
	facing = 1 if dx > 0 else -1
	_t -= delta
	match gstate:
		GState.APPROACH:
			velocity.x = 0.0
			if absf(dx) < 60.0:
				gstate = GState.TELEGRAPH
				_t = tuning.guard_telegraph
				sprite.modulate = Color(1.4, 1.2, 0.4)  # sari parlama = telegraph
		GState.TELEGRAPH:
			velocity.x = 0.0
			if _t <= 0.0:
				gstate = GState.LUNGE
				_t = tuning.guard_lunge_time
				sprite.modulate = Color(0.5, 0.6, 0.9)
				contact_hitbox.activate(
					DamageInfo.make(1, self, Vector2(facing * 160, -40), true, false))
				AudioManager.play_sfx(&"sfx/swipe", global_position, -8.0)
		GState.LUNGE:
			velocity.x = facing * tuning.guard_lunge_speed
			if _t <= 0.0:
				gstate = GState.RECOVER
				_t = 0.7
				contact_hitbox.deactivate()
		GState.RECOVER:
			velocity.x = 0.0
			if _t <= 0.0:
				gstate = GState.APPROACH


## Kalkan: saldirgan on taraftaysa bloklar (hasar 0, kivilcim).
func take_damage(info: DamageInfo) -> void:
	var src_front := false
	if info.source != null:
		var dx := info.source.global_position.x - global_position.x
		src_front = (dx > 0) == (facing > 0)
	# Lunge/telegraph sirasinda kalkan dusuk — her acidan vurulabilir.
	var shield_up := gstate in [GState.APPROACH, GState.RECOVER]
	if shield_up and src_front:
		FX.spark(hurtbox.global_position + Vector2(facing * 6, -4))
		FX.hitstop(0.04)
		AudioManager.play_sfx(&"sfx/clang", global_position, -6.0)
		# Seken vurus cozumu ogretir: kalkan piktogrami = parry et
		if not _hint_shown:
			_hint_shown = true
			Pictogram.show_on(self, &"shield", 2.2, Vector2(0, -28))
		return
	super.take_damage(info)
