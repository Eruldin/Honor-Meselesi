class_name GlitchBolt
extends Area2D
## Glitch Yaratik'in menzilli saldirisi — cyan glitch tanesi.
## Dusman katmanina (16) vurur, 1 hasar, duvara/fayiz mesafede silinir.

var vel := Vector2(150, 0)
var dmg := 1
var src: Node
var _life := 1.2
var _trail_t := 0.0
var _tex: Texture2D


func _ready() -> void:
	collision_layer = 8
	collision_mask = 16 | 1  # dusman hurtbox + duvar govdesi
	var bc := CollisionShape2D.new()
	var br := RectangleShape2D.new()
	br.size = Vector2(6, 4)
	bc.shape = br
	add_child(bc)
	var bs := Sprite2D.new()
	_tex = AssetLoader.texture(&"fx/bolt", Vector2i(6, 4))
	bs.texture = _tex
	bs.modulate = Color(0.4, 1.0, 0.9)
	add_child(bs)
	area_entered.connect(_on_hit)
	body_entered.connect(_on_wall)


func _physics_process(delta: float) -> void:
	position += vel * delta
	# titresim — glitch dokusu
	modulate.a = 0.7 + 0.3 * absf(sin(Time.get_ticks_msec() * 0.02))
	# ardinda solan veri tanecikleri — glitch izi
	_trail_t -= delta
	if _trail_t <= 0.0:
		_trail_t = 0.045
		var m := Sprite2D.new()
		m.texture = _tex
		m.modulate = Color(0.4, 1.0, 0.9, 0.4)
		m.global_position = global_position + Vector2(
			randf_range(-1.0, 1.0), randf_range(-2.0, 2.0))
		get_parent().add_child(m)
		var tw := m.create_tween()
		tw.tween_property(m, "modulate:a", 0.0, 0.22)
		tw.finished.connect(m.queue_free)
	_life -= delta
	if _life <= 0.0:
		queue_free()


func _on_hit(area: Area2D) -> void:
	var hb := area as Hurtbox
	if hb == null:
		return
	var owner := hb.get_parent()
	if owner != null and owner.has_method("take_damage"):
		var s: Node = src if is_instance_valid(src) else null
		owner.take_damage(DamageInfo.make(
			dmg, s, Vector2(signf(vel.x) * 60.0, -20.0), false, false))
	FX.hitstop(0.04)
	queue_free()


## Duvar/terrain govdesine carpinca silinir — duvar arkasindan gecmez.
func _on_wall(_body: Node) -> void:
	queue_free()
