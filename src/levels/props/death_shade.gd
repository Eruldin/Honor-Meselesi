class_name DeathShade
extends Node2D
## Olum golgesi: oyuncunun olumunde ruhu burada kalir; golgeyi vurunca
## ruh geri doner (Hollow Knight shade'i). Hurtbox'a sahiptir — herhangi
## bir saldiriyla tek vurusta krilir.

var _spr: Sprite2D
var _t := 0.0
var _dead := false


func _ready() -> void:
	# Karanlik glitch kutle — gozler cyan yanar
	_spr = Sprite2D.new()
	_spr.texture = AssetLoader.texture(&"enemy/glitch_creature",
		Vector2i(15, 13))
	_spr.modulate = Color(0.09, 0.09, 0.2)
	add_child(_spr)
	for dx in [-3.0, 3.0]:
		var eye := ColorRect.new()
		eye.size = Vector2(3, 4)
		eye.position = Vector2(dx - 1.5, -4)
		eye.color = Color(0.55, 1.0, 0.95)
		_spr.add_child(eye)
	# Soluk cyan hale — karanlik sahnelerde yerini belli eder
	var halo := ColorRect.new()
	halo.size = Vector2(26, 20)
	halo.position = Vector2(-13, -12)
	halo.color = Color(0.35, 0.85, 0.8, 0.1)
	halo.z_index = -1
	add_child(halo)

	var hb := Hurtbox.new()
	hb.collision_layer = 16   # enemy hurtbox katmani — saldiri vurur
	hb.collision_mask = 0     # sadece vurulur, kimseyi bulamaz
	hb.pogoable = true        # ustunden sekip de calilebilir
	var col := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(16, 14)
	col.shape = rect
	hb.add_child(col)
	add_child(hb)


func _process(delta: float) -> void:
	_t += delta
	_spr.position.y = sin(_t * 2.1) * 2.5
	_spr.modulate.a = 0.75 + 0.25 * sin(_t * 5.0)


func take_damage(_info: DamageInfo) -> void:
	if _dead:
		return
	_dead = true
	var back := GameState.clear_death_mark()
	FX.spark(global_position + Vector2(0, -6))
	AudioManager.play_sfx(&"sfx/ghost", global_position, -4.0, 1.25)
	var sam := get_tree().get_first_node_in_group(&"player")
	if sam != null:
		Pictogram.show_on(sam, &"dots", 1.0, Vector2(0, -26))
	queue_free()
