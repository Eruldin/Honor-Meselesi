class_name LootChest
extends Node2D
## Vurunca acilan odul sandigi: oyuncuyu tam iyilestirir, tek kullanimlik.
## Kelimesiz odul isareti — gizli odalarda durur; vurusla kapagi acilir.

var _opened := false
var _sprite: Sprite2D


func _ready() -> void:
	_sprite = Sprite2D.new()
	_sprite.texture = AssetLoader.texture(&"prop/chest", Vector2i(20, 16))
	add_child(_sprite)
	var hb := Hurtbox.new()
	hb.pogoable = true
	add_child(hb)
	hb.hit_received.connect(_on_hit)


## Hurtbox sahibi olarak hasar almaz; vurus sadece acma tetigidir.
func take_damage(_info: DamageInfo) -> void:
	pass


func _on_hit(_info: DamageInfo) -> void:
	if _opened:
		return
	_opened = true
	_sprite.modulate = Color(1.4, 1.2, 0.7)
	var tw := _sprite.create_tween()
	tw.tween_property(_sprite, "scale", Vector2(1.15, 0.85), 0.12)
	tw.tween_property(_sprite, "scale", Vector2.ONE, 0.18)
	var p := get_tree().get_first_node_in_group(&"player")
	if p != null:
		p.health.reset()
		Pictogram.show_on(p, &"heart", 1.2, Vector2(0, -26))
	FX.spark(global_position + Vector2(0, -6))
	AudioManager.play_sfx(&"sfx/reward", global_position)
