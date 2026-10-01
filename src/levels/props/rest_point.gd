class_name RestPoint
extends Area2D
## Dinlenme noktasi / checkpoint (DEVIN_PLAN M4): oyuncu degince REST
## durumu, tam can + tam ruh, checkpoint_id set edilir ve oyun kaydedilir.
## Metinsiz geri bildirim: sleep piktogrami + mavi parilti.

const GlowSprite := preload("res://src/levels/props/glow_sprite.gd")

@export var checkpoint_id: StringName = &"cp"

var _used := false
var _resting_player: Node2D = null
var _owns_music := false

## Dinlenme temasina gecmeden once calan parca — tum noktalarin paylastigi
## tek deger: B noktasi A'nin temasi sirasinda ele gecirirse ayni parcaya doner.
static var _shared_prev_music: StringName = &""


func _process(_delta: float) -> void:
	if _resting_player == null:
		return
	# Dinlenme temasi sadece oyuncu nokta yakinindayken calar;
	# uzaklasinca (ya da baska bir tetik muzigi degistirdiyse) eski parcaya don.
	if not is_instance_valid(_resting_player):
		_resting_player = null
		return
	if _resting_player.global_position.distance_to(global_position) > 140.0:
		_resting_player = null
		if _owns_music and AudioManager._current_music == &"music/rest_point" \
				and _shared_prev_music != &"":
			AudioManager.play_music(_shared_prev_music)
		_owns_music = false


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

	# Guvenli liman pariltisi — dinlenme noktasi karanlikta da okunur.
	var glow := GlowSprite.new(20.0, Color(0.45, 0.75, 1.0, 0.35))
	glow.position.y = -8
	glow.z_index = -1
	add_child(glow)

	area_entered.connect(_on_area_entered)


func _on_area_entered(area: Area2D) -> void:
	var actor := area.get_parent()
	while actor != null and not actor.has_method("take_damage"):
		actor = actor.get_parent()
	if actor == null or not actor.is_in_group(&"player"):
		return
	rest(actor)


func rest(player) -> void:
	GameState.checkpoint_id = checkpoint_id
	GameState.set_flag(&"respawn_pos", global_position)
	GameState.set_flag(&"respawn_ch", GameState.current_chapter)
	player.health.reset()
	GameState.soul = GameState.SOUL_MAX
	SaveSystem.save_game()
	EventBus.checkpoint_reached.emit(checkpoint_id)
	FX.spark(global_position + Vector2(0, -10))
	AudioManager.play_sfx(&"sfx/checkpoint", global_position)
	if _used:
		# Tekrar gecis (boss deneme kosusu vb.): can/ruh taze + kayit yeterli —
		# oturma durumu ve muzik degisimi oyuncuyu her seferinde kesmez.
		return
	_used = true
	player.sm.change_to(Samurai.S_REST, true)
	Pictogram.show_on(player, &"sleep", 1.2, Vector2(0, -26))
	# Bench temasi: dinlenme aninda sakin parca, uzaklasinca eski muzik.
	# Tema hala caliyorsa onceki parcayi ezme; bu nokta sahipligi devralir.
	if AudioManager._current_music != &"music/rest_point":
		_shared_prev_music = AudioManager._current_music
	_owns_music = true
	_resting_player = player
	AudioManager.play_music(&"music/rest_point")
