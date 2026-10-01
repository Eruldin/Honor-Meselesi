class_name Ghost
extends EnemyBase
## Bolum 3 hayalet: kivilcim (parry/spark) yakininda gorunur ve
## vurulabilir olur; aksi halde soluk + hasar almaz (DEVIN_PLAN M6).

var revealed := false
var _reveal_timer := 0.0
var _player: Node2D


func _init() -> void:
	max_hp = 2
	body_size = Vector2(14, 18)
	asset_key = &"ghost"
	contact_damage = true


func _ready() -> void:
	super._ready()
	_set_dim()
	EventBus.spark_emitted.connect(_on_spark)
	EventBus.parry_succeeded.connect(_on_spark)


func _on_spark(pos: Vector2) -> void:
	if global_position.distance_to(pos) < tuning.ghost_reveal_radius:
		reveal()


func reveal() -> void:
	if not revealed:
		AudioManager.play_sfx(&"sfx/ghost", global_position, -6.0)
	revealed = true
	_reveal_timer = tuning.ghost_reveal_time
	var c := Color(0.7, 0.85, 1.0, 0.95)
	sprite.modulate = c
	if anims != null:
		anims.modulate = c


func _set_dim() -> void:
	var c := Color(0.6, 0.7, 1.0, 0.25)
	sprite.modulate = c
	if anims != null:
		anims.modulate = c


func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	if not health.is_alive():
		return
	if revealed:
		_reveal_timer -= delta
		if _reveal_timer <= 0.0:
			revealed = false
			_set_dim()
	if _player == null:
		_player = get_tree().get_first_node_in_group(&"player")
		return
	var dx: float = _player.global_position.x - global_position.x
	if absf(dx) < 150.0:
		velocity.x = signf(dx) * tuning.ghost_speed


## Solukken hasar almaz — once kivilcimla aciga cikmali.
func take_damage(info: DamageInfo) -> void:
	if not revealed:
		# Soluk bedenden vurus gecer — sessiz kalmaz, hayalet bir suzultu
		# dondurur (oyuncu 'vurdu ama olmadi' hissini gorur).
		AudioManager.play_sfx(&"sfx/ghost", global_position, -14.0, 0.7)
		return
	super.take_damage(info)
