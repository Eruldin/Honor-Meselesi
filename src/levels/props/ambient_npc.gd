class_name AmbientNpc
extends Node2D
## Pasif sahne NPC'si: durur, oyuncu yaklasinca urker ve geri cekilir.
## Hostil degildir — hitbox'suz; sadece atmosfer (ofkeli koyun sakinleri).
## npc/<key> manifest girdisi gercek sprite verir; yoksa placeholder.

@export var npc_key: StringName = &"peasant1"
@export var flee_speed: float = 26.0
@export var scare_range: float = 34.0
## Piktogram ikonu: ilk urktugunde bir kez gosterilir. Bos = sessiz.
@export var picto_icon: StringName = &""

var _sprite: Sprite2D
var _scared := false
var _player: Node2D
var _home_x: float
var _picto_shown := false


func _ready() -> void:
	_sprite = Sprite2D.new()
	_sprite.texture = AssetLoader.texture(&"npc/" + String(npc_key), Vector2i(14, 16))
	add_child(_sprite)
	_home_x = position.x


func _process(delta: float) -> void:
	if _player == null:
		_player = get_tree().get_first_node_in_group(&"player")
		return
	var dx: float = global_position.x - _player.global_position.x
	_sprite.flip_h = dx < 0.0   # oyuncuya donuk dur
	if absf(dx) < scare_range:
		if not _scared:
			_scared = true
			# Ilk urkme: piktogram + kisa homurtu (tek seferlik)
			if not _picto_shown and picto_icon != &"":
				_picto_shown = true
				Pictogram.show_on(self, picto_icon, 1.8, Vector2(0, -18))
			var grunts: Array[StringName] = [&"sfx/npc_blip",
				&"sfx/npc_grunt_2", &"sfx/npc_grunt_3"]
			AudioManager.play_sfx(grunts[randi() % grunts.size()],
				global_position, -16.0, randf_range(0.85, 1.15))
	else:
		_scared = false
	# urkmusse oyuncudan uzaklas, ama evinden 40px'den fazla kacmaz
	var target_v := 0.0
	if _scared:
		target_v = signf(dx) * flee_speed
	elif absf(position.x - _home_x) > 4.0:
		target_v = signf(_home_x - position.x) * flee_speed * 0.4
	position.x += target_v * delta
	position.x = clampf(position.x, _home_x - 40.0, _home_x + 40.0)
