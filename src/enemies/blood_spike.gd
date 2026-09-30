class_name BloodSpike
extends Node2D
## Kont Vlad kan kaziklari: yerde uyarici isaret (metinsiz telegraph),
## sonra kazik firlar — parry'lenebilir.

@export var telegraph: float = 0.7

var hitbox: Hitbox
var _t := 0.0
var _phase := 0


func _ready() -> void:
	_tuning_ready()


func _tuning_ready() -> void:
	var t: Tuning = load("res://config/tuning.tres")
	telegraph = t.blood_spike_delay
	# Uyarici isaret — yerde kirmizi daire
	var warn := ColorRect.new()
	warn.name = "warn"
	warn.color = Color(1.0, 0.2, 0.3, 0.5)
	warn.size = Vector2(14, 3)
	warn.position = Vector2(-7, -1)
	add_child(warn)

	var spike := Sprite2D.new()
	spike.name = "spike"
	spike.texture = AssetLoader.texture(&"enemy/blood_spike", Vector2i(10, 22))
	spike.modulate = Color(0.8, 0.15, 0.3)
	spike.position = Vector2(0, -11)
	spike.visible = false
	add_child(spike)

	hitbox = Hitbox.new()
	hitbox.collision_layer = 32
	hitbox.collision_mask = 4
	var col := CollisionShape2D.new()
	var r := RectangleShape2D.new()
	r.size = Vector2(10, 24)
	col.shape = r
	hitbox.add_child(col)
	hitbox.position = Vector2(0, -11)
	add_child(hitbox)
	hitbox.deactivate()


func _physics_process(delta: float) -> void:
	_t += delta
	if _phase == 0 and _t >= telegraph:
		_phase = 1
		get_node("warn").visible = false
		get_node("spike").visible = true
		AudioManager.play_sfx(&"sfx/land_dirt", global_position, -10.0, 0.6)
		hitbox.activate(DamageInfo.make(1, self, Vector2(0, -120), true, false))
		# Kazik firlayip geri cekilir
		var tw := create_tween()
		tw.tween_interval(0.35)
		tw.tween_callback(func() -> void: hitbox.deactivate())
		tw.tween_property(get_node("spike"), "scale:y", 0.1, 0.3)
		tw.tween_callback(queue_free)
