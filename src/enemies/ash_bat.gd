class_name AshBat
extends EnemyBase
## Bolum 5 kul yarassı: havada sinus salinimi yapar, oyuncu menzile
## girince dalis gecirir. Yer cekimi uygulanmaz (uçar).

var _player: Node2D
var _t := 0.0
var _home: Vector2
var _diving := false


func _init() -> void:
	max_hp = 2
	body_size = Vector2(14, 10)
	contact_damage = true
	asset_key = &"ash_bat"


func _ready() -> void:
	super._ready()
	if not using_real_sprite:
		sprite.modulate = Color(0.5, 0.45, 0.55)
	_home = global_position


func _physics_process(delta: float) -> void:
	# Ucan dusman: EnemyBase'in gravity'sini atla ama stagger sayacini
	# ve temas-hitbox pencere yonetimini koru.
	stagger_timer = maxf(stagger_timer - delta, 0.0)
	_manage_contact_hitbox()
	if _player == null:
		_player = get_tree().get_first_node_in_group(&"player")
	if is_staggered() or not health.is_alive():
		velocity = Vector2.ZERO
		move_and_slide()
		return
	_t += delta
	if _player != null:
		var dx: float = _player.global_position.x - global_position.x
		var dy: float = _player.global_position.y - global_position.y
		sprite.flip_h = dx < 0
		if _diving:
			velocity = velocity.normalized() * tuning.ash_bat_dive_speed
			# Dalis, duvara vurmadan da _t suresinde biter — acik boslukta
			# veya duvar boyunca sonsuza kaymaz.
			if velocity.length() < 1.0 or _t >= 0.0:
				_diving = false
		elif absf(dx) < 90.0 and absf(dy) < 60.0:
			# Dalis: oyuncuya dogru atil, sonra geri don
			_diving = true
			_t = -1.2  # dalis suresi (negatif sayac)
			velocity = Vector2(dx, dy).normalized() * tuning.ash_bat_dive_speed
			play_anim(&"jump", 0.7)  # bankada varsa dalis pozu
		elif _t >= 0.0:
			# Evi cevresinde sinirli salinim
			var tx := _home.x + sin(_t * 0.9) * 26.0
			var ty := _home.y + sin(_t * 1.7) * 8.0
			velocity = Vector2(tx - global_position.x, ty - global_position.y) * 3.0
		else:
			# Dalis sonrasi eve donus
			velocity = Vector2(_home - global_position) * 1.4
			if velocity.length() > tuning.ash_bat_speed * 2.0:
				velocity = velocity.normalized() * tuning.ash_bat_speed * 2.0
	move_and_slide()
