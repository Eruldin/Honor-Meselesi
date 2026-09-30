extends GutTest
## Kalp kristali (HeartShard): kalici +1 maks can + tam iyilesme,
## "shard_<id>" bayragi geri dogmayi engeller.

var sam: Samurai


func before_each() -> void:
	Engine.time_scale = 1.0
	GameState.reset()
	sam = Samurai.new()
	sam.input = AIInputSource.new()
	sam.global_position = Vector2(0, -30)
	add_child_autofree(sam)
	await get_tree().physics_frame


func after_each() -> void:
	Engine.time_scale = 1.0


func test_heart_shard_grants_max_health_and_full_heal() -> void:
	var base := sam.health.max_health
	sam.health.take(1)  # hasarli basla — tam iyilesme gozlemlensin
	var shard := HeartShard.new()
	shard.pickup_id = &"t_shard_a"
	add_child_autofree(shard)
	await get_tree().physics_frame
	shard._on_area_entered(sam.hurtbox)
	assert_eq(GameState.max_health_bonus, 1)
	assert_eq(sam.health.max_health, base + 1, "maks can +1")
	assert_eq(sam.health.current, base + 1, "kristal tam iyilestirir")
	assert_true(GameState.get_flag(&"shard_t_shard_a", false))


func test_heart_shard_flagged_does_not_respawn() -> void:
	GameState.set_flag(&"shard_t_shard_b")
	var shard := HeartShard.new()
	shard.pickup_id = &"t_shard_b"
	add_child_autofree(shard)
	await get_tree().physics_frame
	assert_false(is_instance_valid(shard), "bayrakli kristal sahnede dogmaz")
	assert_eq(GameState.max_health_bonus, 0)
