class_name FlickerPlatform
extends StaticBody2D
## Bolum 6 bellek parcasi platformu: periyodik olarak "unutulur" —
## once yanip soner (telegraph), sonra collision kapanir ve dusurur,
## bir sure sonra geri gelir.

@export var size := Vector2(56, 10)
## Gorunur kalma + kayip kalma sureleri (sn)
@export var on_time := 3.4
@export var off_time := 1.4
## Baslangic faz kaymasi — platformlar ayni anda kaybolmasin
@export var phase_offset := 0.0
@export var tex_id: StringName = &""

var _t := 0.0
var _on := true
var _sprite: Sprite2D


func _ready() -> void:
	collision_layer = 1
	var col := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = size
	col.shape = rect
	add_child(col)
	_sprite = Sprite2D.new()
	if tex_id != &"" and AssetLoader.has_asset(tex_id):
		_sprite.texture = AssetLoader.tiled_texture(tex_id, Vector2i(size))
	else:
		_sprite.texture = AssetLoader.texture(&"terrain/flicker", Vector2i(size))
		_sprite.modulate = Color(0.45, 0.4, 0.7)
	add_child(_sprite)
	
	# Havada ucmamasi icin tavana bagli kopan zincir/ip gorunumu
	var chain := Sprite2D.new()
	chain.texture = AssetLoader.tiled_texture(&"terrain/chain", Vector2i(4, 150))
	chain.modulate = Color(0.3, 0.3, 0.4, 0.6)
	chain.position = Vector2(0, -75)
	chain.z_index = -1
	_sprite.add_child(chain)

	_t = on_time - fmod(phase_offset, on_time + off_time)


func _process(delta: float) -> void:
	_t -= delta
	if _on:
		# Son 0.8s: yanip sonerek uyar (telegraph)
		if _t < 0.8:
			_sprite.modulate.a = 0.4 + 0.5 * absf(sin(_t * 22.0))
		if _t <= 0.0:
			_on = false
			_t = off_time
			collision_layer = 0
			_sprite.visible = false
			AudioManager.play_sfx(&"sfx/ghost", global_position,
				-14.0, randf_range(1.2, 1.4))
	else:
		if _t <= 0.0:
			_on = true
			_t = on_time
			collision_layer = 1
			_sprite.visible = true
			_sprite.modulate.a = 1.0
			AudioManager.play_sfx(&"sfx/ui", global_position,
				-14.0, randf_range(1.3, 1.5))
