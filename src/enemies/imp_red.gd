class_name ImpRed
extends Villager
## Kucuk kizil imp — kalabalik surpriz dusman; hizli, zayif.
## Kovalarken arada hoplar — kucuk cin firlamasi.

var _hop_t := 0.6


func _init() -> void:
	super._init()
	max_hp = 2
	body_size = Vector2(13, 14)
	asset_key = &"imp_red"
	speed_override = 70.0
	aggro_pitch = 1.4


func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	if is_staggered() or not health.is_alive() or not _noticed:
		return
	_hop_t -= delta
	if is_on_floor() and _hop_t <= 0.0 and absf(velocity.x) > 15.0:
		_hop_t = 1.4
		velocity.y = -175.0
		play_anim(&"jump", 0.5)
