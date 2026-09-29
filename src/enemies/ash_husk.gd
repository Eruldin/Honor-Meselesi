class_name AshHusk
extends EnemyBase
## Bolum 5 kul kovani (Zombie_Axe sheet'leri): oyuncuyu gorunce surunur,
## menzilde telegraph -> balta savrulusu. Yavas ama israrli.

enum HState { APPROACH, TELEGRAPH, SWIPE, RECOVER }

var hstate := HState.APPROACH
var _t := 0.0
var _player: Node2D
var facing := -1
var _swipe_hitbox: Hitbox


func _init() -> void:
	max_hp = 4
	body_size = Vector2(13, 18)
	contact_damage = true
	asset_key = &"ash_husk"


func _ready() -> void:
	super._ready()
	if not using_real_sprite:
		sprite.modulate = Color(0.55, 0.5, 0.48)
	_swipe_hitbox = Hitbox.new()
	_swipe_hitbox.collision_layer = 32
	_swipe_hitbox.collision_mask = 4
	var col := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(14, 12)
	col.shape = rect
	_swipe_hitbox.add_child(col)
	add_child(_swipe_hitbox)
	_swipe_hitbox.deactivate()


func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	if is_staggered() or not health.is_alive():
		return
	if _player == null:
		_player = get_tree().get_first_node_in_group(&"player")
		return
	var dx: float = _player.global_position.x - global_position.x
	facing = 1 if dx > 0 else -1
	sprite.flip_h = facing < 0
	_t -= delta
	match hstate:
		HState.APPROACH:
			if absf(dx) < 120.0:
				velocity.x = facing * tuning.husk_speed
				if absf(dx) < tuning.husk_attack_range:
					hstate = HState.TELEGRAPH
					_t = tuning.husk_telegraph
					sprite.modulate = Color(1.3, 1.1, 0.7)
					if anims != null:
						anims.modulate = Color(1.3, 1.1, 0.7)
			else:
				velocity.x = move_toward(velocity.x, 0.0, 300.0 * delta)
		HState.TELEGRAPH:
			velocity.x = 0.0
			if _t <= 0.0:
				hstate = HState.SWIPE
				_t = 0.3
				sprite.modulate = Color.WHITE
				if anims != null:
					anims.modulate = Color.WHITE
				play_anim(&"attack", 0.5)
				_swipe_hitbox.position.x = facing * 9.0
				_swipe_hitbox.activate(DamageInfo.make(
					1, self, Vector2(facing * 110.0, -50.0), true, true))
		HState.SWIPE:
			velocity.x = facing * 14.0
			if _t <= 0.0:
				_swipe_hitbox.deactivate()
				hstate = HState.RECOVER
				_t = 1.0
		HState.RECOVER:
			velocity.x = 0.0
			if _t <= 0.0:
				hstate = HState.APPROACH
