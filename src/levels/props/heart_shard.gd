class_name HeartShard
extends Area2D
## Kalp kristali (HK maske parcasi analogu): degince +1 kalici maks can,
## tam iyilesme, kalp piktogrami. pickup_id basina tek seferlik —
## "shard_<id>" flag'i alinmissa sahnede dogmaz.
## Gorsel: ui/hud_heart (HUD kalbiyle ayni ikon = kelimesiz okunurluk),
## nazik yukari-asagi suzulme + kirmizi nabiz.

@export var pickup_id: StringName = &"shard"

var _sprite: Sprite2D
var _t := 0.0


func _ready() -> void:
	collision_layer = 0
	collision_mask = 4  # player hurtbox
	if GameState.get_flag(&"shard_" + String(pickup_id), false):
		queue_free()
		return
	var col := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(12, 14)
	col.shape = rect
	add_child(col)

	_sprite = Sprite2D.new()
	_sprite.texture = AssetLoader.texture(&"ui/hud_heart", Vector2i(10, 10))
	_sprite.position.y = -8
	add_child(_sprite)
	area_entered.connect(_on_area_entered)


func _process(delta: float) -> void:
	_t += delta
	if _sprite != null:
		_sprite.position.y = -8.0 + sin(_t * 2.4) * 2.0
		var pulse := 0.5 + 0.5 * sin(_t * 3.1)
		_sprite.modulate = Color(1.1 + pulse * 0.4, 0.9, 0.95, 1.0)


func _on_area_entered(area: Area2D) -> void:
	var actor := area.get_parent()
	while actor != null and not actor.is_in_group(&"player"):
		actor = actor.get_parent()
	if actor == null:
		return
	set_deferred("monitoring", false)
	GameState.set_flag(&"shard_" + String(pickup_id))
	GameState.max_health_bonus += 1
	actor.health.max_health += 1
	actor.health.reset()
	SaveSystem.save_game()
	Pictogram.show_on(actor, &"heart", 1.4, Vector2(0, -28))
	FX.spark(global_position + Vector2(0, -8))
	AudioManager.play_sfx(&"sfx/checkpoint", global_position, -2.0)
	queue_free()
