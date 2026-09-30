class_name RestPoint
extends Area2D
## Dinlenme noktasi / checkpoint (DEVIN_PLAN M4): oyuncu degince REST
## durumu, tam can + tam ruh, checkpoint_id set edilir ve oyun kaydedilir.
## Metinsiz geri bildirim: sleep piktogrami + mavi parilti.

@export var checkpoint_id: StringName = &"cp"

var _used := false


func _ready() -> void:
	collision_layer = 0
	collision_mask = 4  # player hurtbox
	var col := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(28, 34)
	col.shape = rect
	add_child(col)

	var sprite := Sprite2D.new()
	sprite.texture = AssetLoader.texture(&"prop/rest_point", Vector2i(12, 18))
	sprite.modulate = Color(0.5, 0.8, 1.0)
	sprite.name = "sprite"
	sprite.position.y = -6
	add_child(sprite)

	area_entered.connect(_on_area_entered)


func _on_area_entered(area: Area2D) -> void:
	var actor := area.get_parent()
	while actor != null and not actor.has_method("take_damage"):
		actor = actor.get_parent()
	if actor == null or not actor.is_in_group(&"player"):
		return
	rest(actor)


func rest(player) -> void:
	_used = true
	GameState.checkpoint_id = checkpoint_id
	GameState.set_flag(&"respawn_pos", global_position)
	GameState.set_flag(&"respawn_ch", GameState.current_chapter)
	player.sm.change_to(Samurai.S_REST, true)
	player.health.reset()
	GameState.soul = GameState.SOUL_MAX
	SaveSystem.save_game()
	EventBus.checkpoint_reached.emit(checkpoint_id)
	Pictogram.show_on(player, &"sleep", 1.2, Vector2(0, -26))
	FX.spark(global_position + Vector2(0, -10))
	AudioManager.play_sfx(&"sfx/checkpoint", global_position)
