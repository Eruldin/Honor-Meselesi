class_name CaveBat
extends AshBat
## Bolum 1 magara yarasa: AshBat davranisi + Dark Fantasy bat sprite'lari.
## `sleeping_start` ile sacak altina asili uyurken dogar; oyuncu yaklasinca
## wake animi oynayip normal ucus AI'sina gecer.

var sleeping_start := false
var _asleep := false


func _init() -> void:
	super._init()
	max_hp = 3
	body_size = Vector2(16, 12)
	asset_key = &"bat"


func _ready() -> void:
	super._ready()
	_asleep = sleeping_start
	if _asleep and anims != null and anims.sprite_frames.has_animation(&"sleep"):
		anims.play(&"sleep")


func _physics_process(delta: float) -> void:
	if not _asleep:
		super._physics_process(delta)
		return
	stagger_timer = maxf(stagger_timer - delta, 0.0)
	_anim_lock = 0.5  # sleep animini idle/walk auto-sync'inden koru
	if anims != null and anims.sprite_frames.has_animation(&"sleep") \
			and anims.animation != &"sleep":
		anims.play(&"sleep")
	velocity = Vector2.ZERO
	move_and_slide()
	if is_staggered() or not health.is_alive():
		_wake()
		return
	if _player == null:
		_player = get_tree().get_first_node_in_group(&"player")
	if _player != null:
		var dx: float = _player.global_position.x - global_position.x
		var dy: float = _player.global_position.y - global_position.y
		if absf(dx) < 110.0 and absf(dy) < 90.0:
			_wake()


func _wake() -> void:
	_asleep = false
	_t = 0.0
	_home = global_position
	play_anim(&"wake", 1.65)
