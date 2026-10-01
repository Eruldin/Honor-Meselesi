class_name MemoryChimera
extends AshHusk
## M9 — bellek melezi: bilesen karistirmadan dogan artik dusman.
## Husk govdesi ustunde yari silik bir drone parcasi gezer; karisik
## davranis: husk'in yurume/yakin saldirisi + ara ara glitch tukurusu.
## Ikisi bir arada — bellekte kalmis iki dusmanin tek bedeni.

var _drone_bit: Sprite2D
var _spit_t := 2.4
var _bob_t := 0.0


func _init() -> void:
	super._init()
	max_hp = 7


func _ready() -> void:
	super._ready()
	# Ikinci bilesen: ustte gezen drone parcasi
	_drone_bit = Sprite2D.new()
	_drone_bit.texture = AssetLoader.texture(&"enemy/drone", Vector2i(11, 11))
	_drone_bit.modulate = Color(0.7, 1.1, 1.3, 0.8)
	_drone_bit.position = Vector2(0, -body_size.y - 7)
	add_child(_drone_bit)


func _process(delta: float) -> void:
	super._process(delta)
	if _drone_bit == null:
		return
	_bob_t += delta
	_drone_bit.position.y = -body_size.y - 7 + sin(_bob_t * 3.0) * 2.0
	_drone_bit.visible = health.is_alive()


func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	if not health.is_alive() or is_staggered() or _player == null:
		return
	if hstate != HState.APPROACH:
		return
	_spit_t -= delta
	if _spit_t <= 0.0 and absf(_player.global_position.x - global_position.x) < 150.0:
		_spit_t = randf_range(2.4, 3.6)
		_spit()


func _spit() -> void:
	var p := Projectile.new()
	p.direction = 1 if facing > 0 else -1
	p.speed = 70.0
	p.global_position = global_position + Vector2(facing * 7.0, -13)
	p.modulate = Color(0.7, 1.1, 1.3)
	get_parent().add_child(p)
	AudioManager.play_sfx(&"sfx/swipe", global_position, -8.0, 1.15)
	FX.glitch(0.12, 0.2)
