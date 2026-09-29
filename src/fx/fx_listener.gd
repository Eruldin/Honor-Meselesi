class_name FxListener
extends Node
## EventBus'taki efekt isteklerini uygular: Engine.time_scale ile
## hit-stop, kameraya shake, parry kivilcimi icin placeholder sprite.

@export var camera_path: NodePath


func _ready() -> void:
	EventBus.hitstop_requested.connect(_on_hitstop)
	EventBus.screenshake_requested.connect(_on_shake)
	EventBus.spark_emitted.connect(_on_spark)


func _on_hitstop(duration: float) -> void:
	Engine.time_scale = 0.001
	await get_tree().create_timer(duration, true, false, true).timeout
	Engine.time_scale = 1.0


func _on_shake(strength: float, duration: float) -> void:
	var cam := get_node_or_null(camera_path)
	if cam != null and cam.has_method("shake"):
		cam.shake(strength, duration)


func _on_spark(pos: Vector2) -> void:
	var spark := Sprite2D.new()
	spark.texture = AssetLoader.placeholder_texture("fx/spark", Vector2i(10, 10))
	spark.modulate = Color(1.0, 0.95, 0.4)
	spark.global_position = pos
	get_tree().current_scene.add_child(spark)
	var tw := spark.create_tween()
	tw.set_ignore_time_scale(true)
	tw.tween_property(spark, "scale", Vector2(2.2, 2.2), 0.12)
	tw.parallel().tween_property(spark, "modulate:a", 0.0, 0.12)
	tw.finished.connect(spark.queue_free)
