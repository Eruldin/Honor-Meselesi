class_name ThiefCameo
extends RefCounted
## Sapka hirsizinin kisa gorunumu: dark_character bankasiyla belirir,
## durur, sonra kacip duman olur. Kelimesiz anlatim icin cameo.


static func spawn(parent: Node, pos: Vector2) -> void:
	var bank := SpriteFrames.new()
	var ok := false
	for anim in [&"idle", &"walk"]:
		var id := StringName("enemy/dark_character/" + String(anim))
		if not AssetLoader.has_frames(id):
			continue
		var src := AssetLoader.frames(id)
		if src == null or src.get_frame_count(&"default") == 0:
			continue
		bank.add_animation(anim)
		bank.set_animation_speed(anim, src.get_animation_speed(&"default"))
		bank.set_animation_loop(anim, anim == &"idle")
		for i in src.get_frame_count(&"default"):
			bank.add_frame(anim, src.get_frame_texture(&"default", i))
		ok = true
	if not ok:
		return
	if bank.has_animation(&"default"):
		bank.remove_animation(&"default")
	var idle_anim: StringName = &"idle" if bank.has_animation(&"idle") else &"walk"
	var n := AnimatedSprite2D.new()
	n.sprite_frames = bank
	var fs: Vector2 = bank.get_frame_texture(idle_anim, 0).get_size()
	n.scale = Vector2(14.0, 20.0) * 1.8 / fs
	n.position = pos
	n.z_index = 4
	n.modulate = Color(0.8, 0.7, 0.9)
	parent.add_child(n)
	n.play(&"idle")
	_sequence(n)


static func _sequence(n: AnimatedSprite2D) -> void:
	await n.get_tree().create_timer(1.3, false).timeout
	if not is_instance_valid(n):
		return
	n.play(&"walk")
	var tw := n.create_tween()
	tw.tween_property(n, "position:x", n.position.x + 90.0, 0.7)
	tw.parallel().tween_property(n, "modulate:a", 0.0, 0.7).set_delay(0.25)
	tw.finished.connect(n.queue_free)
