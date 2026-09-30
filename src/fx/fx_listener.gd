class_name FxListener
extends Node
## EventBus'taki efekt isteklerini uygular: Engine.time_scale ile
## hit-stop, kameraya shake, parry kivilcimi icin placeholder sprite.

@export var camera_path: NodePath

var _ts_token := 0


func _ready() -> void:
	EventBus.hitstop_requested.connect(_on_hitstop)
	EventBus.screenshake_requested.connect(_on_shake)
	EventBus.spark_emitted.connect(_on_spark)
	EventBus.damage_dealt.connect(_on_damage_dealt)
	EventBus.actor_died.connect(_on_actor_died)


func _on_hitstop(duration: float) -> void:
	_slow_time(0.001, duration)


## Zaman olcegi istekleri tek kuyrukta: ust uste binen isteklerde en
## dusuk scale gecerli kalir, son istegin timer'i eski hiza dondurur.
func _slow_time(scale: float, duration: float) -> void:
	_ts_token += 1
	var my := _ts_token
	Engine.time_scale = minf(Engine.time_scale, scale)
	await get_tree().create_timer(duration, true, false, true).timeout
	if my == _ts_token:
		Engine.time_scale = 1.0


func _on_shake(strength: float, duration: float) -> void:
	var cam := get_node_or_null(camera_path)
	if cam != null and cam.has_method("shake"):
		cam.shake(strength, duration)


func _on_spark(pos: Vector2) -> void:
	var spark := Sprite2D.new()
	spark.texture = AssetLoader.texture(&"fx/spark", Vector2i(10, 10))
	spark.modulate = Color(1.0, 0.95, 0.4)
	spark.global_position = pos
	var parent := get_tree().current_scene
	if parent == null:
		parent = self
	parent.add_child(spark)
	var tw := spark.create_tween()
	tw.set_ignore_time_scale(true)
	tw.tween_property(spark, "scale", Vector2(2.2, 2.2), 0.12)
	tw.parallel().tween_property(spark, "modulate:a", 0.0, 0.12)
	tw.finished.connect(spark.queue_free)


## Vurus aninda kucuk parcacik sacilimi + gercek VFX animi (varsa);
## olumde daha buyuk patlama animasyonu.
func _on_damage_dealt(target: Node, info) -> void:
	if target is Node2D:
		var heavy: bool = info is DamageInfo and info.damage >= 2
		_anim_burst((target as Node2D).global_position,
			&"fx/bighit" if heavy else &"fx/smallhit", 26.0 if heavy else 18.0)
		_burst((target as Node2D).global_position, 3,
			Color(1.0, 0.9, 0.5), 26.0, 0.22)
		if not target.is_in_group(&"player"):
			_soul_wisp((target as Node2D).global_position)


## Oyuncu disindaki vurusa +1 ruh: HUD ruh olcegi kosesine ucan cyan zerrecik.
func _soul_wisp(pos: Vector2) -> void:
	var cam := get_node_or_null(camera_path) as Camera2D
	if cam == null:
		return
	var parent := get_tree().current_scene
	if parent == null:
		parent = self
	var w := Sprite2D.new()
	w.texture = AssetLoader.texture(&"fx/spark", Vector2i(7, 7))
	w.modulate = Color(0.5, 0.95, 1.0, 0.9)
	w.global_position = pos
	w.z_index = 20
	parent.add_child(w)
	var dest := cam.get_screen_center_position() + Vector2(-216, -109)
	var tw := w.create_tween()
	tw.set_ignore_time_scale(true)
	tw.tween_property(w, "global_position", dest, 0.5)\
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tw.parallel().tween_property(w, "modulate:a", 0.0, 0.5)
	tw.finished.connect(w.queue_free)


func _on_actor_died(actor: Node) -> void:
	if actor is Node2D:
		var boss := actor is BossBase
		_anim_burst((actor as Node2D).global_position,
			&"fx/explosion" if boss else &"fx/puff", 72.0 if boss else 40.0)
		if boss:
			# ruh salinimi: altin halka genisleyip solar (Elden Ring esintisi)
			_anim_burst((actor as Node2D).global_position, &"fx/eldenring", 110.0)
			# kill beat: darbe ani yavaslar — zafer hissi
			_slow_time(0.22, 0.55)
		_burst((actor as Node2D).global_position, 9 if not boss else 14,
			Color(1.0, 0.85, 0.45), 48.0 if not boss else 64.0, 0.4)


## Tek atimlik VFX animasyonu (codemanu paketi). Kare yoksa sessizce gecer.
## Not: AssetLoader.frames() onbellekli SpriteFrames doner — dongu bayragini
## kopya uzerinde kapatiyoruz (orijinali baska kullanicilarla paylasilir).
func _anim_burst(pos: Vector2, key: StringName, size: float) -> void:
	var src := AssetLoader.frames(key)
	if src == null or src.get_frame_count(&"default") == 0:
		return
	var f := src.duplicate()
	f.set_animation_loop(&"default", false)
	var parent := get_tree().current_scene
	if parent == null:
		parent = self
	var a := AnimatedSprite2D.new()
	a.sprite_frames = f
	a.position = pos
	var fs: Vector2 = f.get_frame_texture(&"default", 0).get_size()
	if fs.y > 0.0:
		a.scale = Vector2.ONE * (size / fs.y)
	a.z_index = 8
	parent.add_child(a)
	a.animation_finished.connect(a.queue_free)
	a.play(&"default")


func _burst(pos: Vector2, n: int, col: Color, spread: float, life: float) -> void:
	var parent := get_tree().current_scene
	if parent == null:
		parent = self  # test sahnelerinde current_scene yok
	for i in n:
		var sp := Sprite2D.new()
		sp.texture = AssetLoader.texture(&"fx/spark", Vector2i(8, 8))
		sp.modulate = col
		sp.global_position = pos
		parent.add_child(sp)
		var dir := Vector2.RIGHT.rotated(randf() * TAU)
		var tw := sp.create_tween()
		tw.set_ignore_time_scale(true)
		tw.tween_property(sp, "global_position",
			pos + dir * randf_range(spread * 0.5, spread), life)
		tw.parallel().tween_property(sp, "modulate:a", 0.0, life)
		tw.finished.connect(sp.queue_free)
