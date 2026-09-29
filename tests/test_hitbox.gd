extends GutTest
## Hitbox gecikmesi regresyonu: activate() ayni frame'de acilir ama
## overlap listesi bir fizik frame sonra dolar — duran dusman kacmamali.

var sam: Samurai
var ai: AIInputSource

func _make_floor(c: Vector2, s: Vector2) -> StaticBody2D:
	var b := StaticBody2D.new()
	b.collision_layer = 1
	var col := CollisionShape2D.new()
	var r := RectangleShape2D.new()
	r.size = s
	col.shape = r
	b.add_child(col)
	b.global_position = c
	return b

func _frames(n: int) -> void:
	for _i in n:
		await get_tree().physics_frame

func test_attack_damages_standing_enemy() -> void:
	add_child_autofree(_make_floor(Vector2(0, 0), Vector2(400, 20)))
	sam = Samurai.new()
	ai = AIInputSource.new()
	sam.input = ai
	sam.global_position = Vector2(0, -30)
	add_child_autofree(sam)
	var e := EnemyBase.new()
	e.global_position = Vector2(22, -10)
	add_child_autofree(e)
	await _frames(14)
	assert_true(sam.is_on_floor(), "kurulum: zeminde")
	ai.tap(&"attack")
	await _frames(30)
	assert_lt(e.health.current, e.health.max_health,
		"saldiri hitbox'i menzildeki dusmana hasar vermeli")
