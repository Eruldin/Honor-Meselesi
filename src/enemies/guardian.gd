class_name Guardian
extends EnemyBase
## Bolum 2 dev koruma: buyuk, yavas, guclu temas. Tum vuruslar bloklanir —
## TEK zayif nokta sirtindaki pil (arkadaki WeakBattery child'i).

var _player: Node2D
var battery: WeakBattery


func _init() -> void:
	max_hp = 8
	body_size = Vector2(24, 34)
	asset_key = &"guardian"
	contact_damage = true


func _ready() -> void:
	super._ready()
	if not using_real_sprite:
		sprite.modulate = Color(0.4, 0.5, 0.7)
	contact_hitbox.activate(DamageInfo.make(2, self, Vector2.ZERO, true, true))
	battery = WeakBattery.new(self)
	add_child(battery)


func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	if is_staggered() or not health.is_alive():
		return
	if _player == null:
		_player = get_tree().get_first_node_in_group(&"player")
		return
	var dx: float = _player.global_position.x - global_position.x
	if absf(dx) < 110.0:
		velocity.x = signf(dx) * tuning.guardian_speed


## Ana govde her zaman bloklar — pil haric hicbir vurus gecmez.
func take_damage(_info: DamageInfo) -> void:
	FX.spark(hurtbox.global_position + Vector2(0, -10))
	FX.hitstop(0.03)
	AudioManager.play_sfx(&"sfx/clang", global_position, -4.0)


## Zayif pil: ayri hurtbox — sadece bu hasar gecirir.
class WeakBattery:
	extends Node2D
	var g: Guardian
	var hurtbox: Hurtbox

	func _init(owner: Guardian) -> void:
		g = owner
		position = Vector2(14, -8)  # sirt taraf (facing'e gore kayar)

	func _ready() -> void:
		var spr := Sprite2D.new()
		spr.texture = AssetLoader.texture(&"enemy/battery", Vector2i(8, 10))
		spr.modulate = Color(1.0, 0.8, 0.2)
		add_child(spr)
		hurtbox = Hurtbox.new()
		hurtbox.collision_layer = 16
		hurtbox.collision_mask = 8
		var col := CollisionShape2D.new()
		var r := RectangleShape2D.new()
		r.size = Vector2(10, 12)
		col.shape = r
		hurtbox.add_child(col)
		add_child(hurtbox)

	func _process(_d: float) -> void:
		# Pil hep sirt tarafta kalsin (oyuncunun ters yonunde)
		var p: Node2D = g.get_tree().get_first_node_in_group(&"player")
		if p != null:
			var behind := -signf(p.global_position.x - g.global_position.x)
			position.x = behind * 14.0

	func take_damage(info: DamageInfo) -> void:
		# Pil vurulunca hasar guardian'a gecer (x1.5 zayif nokta bonusu)
		var boosted := DamageInfo.make(int(ceil(info.damage * 1.5)),
			info.source, info.knockback, info.parryable, info.pogoable)
		g.health.take(boosted.damage)
		g.sprite.modulate = Color(2.0, 1.5, 1.0)
		g._flash_timer = 0.08
		EventBus.damage_dealt.emit(g, boosted)
