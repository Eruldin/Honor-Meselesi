class_name LaserGate
extends Node2D
## Dikey lazer bariyeri: temas = 1 hasar; bagli HackTerminal hacklenince
## acilir (kapanir). gate_id ile eslenir.

@export var gate_id: StringName = &"gate"
@export var size := Vector2(8, 60)

var beam: ColorRect
var hitbox: Hitbox
var open := false


func _ready() -> void:
	beam = ColorRect.new()
	beam.color = Color(0.4, 0.9, 1.0, 0.8)
	beam.size = size
	beam.position = -size / 2.0
	add_child(beam)

	hitbox = Hitbox.new()
	hitbox.collision_layer = 32
	hitbox.collision_mask = 4
	var col := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = size
	col.shape = rect
	hitbox.add_child(col)
	add_child(hitbox)
	hitbox.activate(DamageInfo.make(1, self, Vector2.ZERO, false, false))

	# Ayni id'li terminallerden "hacked" dinle
	for t in get_tree().get_nodes_in_group(&"terminals"):
		if t.gate_id == gate_id:
			t.hacked.connect(_on_hacked)


func _on_hacked(_id: StringName) -> void:
	open = true
	hitbox.deactivate()
	AudioManager.play_sfx(&"sfx/door", global_position, -2.0)
	var tw := create_tween()
	tw.tween_property(beam, "scale:y", 0.05, 0.3)
	tw.parallel().tween_property(beam, "modulate:a", 0.0, 0.3)
