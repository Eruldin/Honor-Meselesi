class_name PortalFx
extends RefCounted
## Bolum sonu portali gorseli: gercek portal animasyonu varsa onu
## kullanir, yoksa renkli halka placeholder.

const GlowSprite := preload("res://src/levels/props/glow_sprite.gd")


static func make(size := Vector2(38, 62), key: StringName = &"fx/portal") -> Node2D:
	var root := Node2D.new()
	# Boyut kapisi on plan katmanlarinin ustunde okunur — sahnenin
	# dekor/hava sprite'lari (z<=6) arasinda kaybolmaz.
	root.z_index = 7
	# Portal isigi cevreye sacilir — boyut kapisi kaynagi olarak okunur.
	var glow_col := Color(0.45, 0.8, 1.0, 0.5)
	if key == &"fx/portal_dark":
		glow_col = Color(0.55, 0.35, 0.9, 0.55)
	elif key == &"fx/portal_grey":
		glow_col = Color(0.6, 0.62, 0.7, 0.45)
	var glow := GlowSprite.new(size.x * 1.7, glow_col)
	glow.z_index = -1
	root.add_child(glow)
	if AssetLoader.has_frames(key):
		var a := AnimatedSprite2D.new()
		a.sprite_frames = AssetLoader.frames(key)
		var ts: Vector2 = a.sprite_frames.get_frame_texture(&"default", 0).get_size()
		a.scale = size / ts
		a.play(&"default")
		root.add_child(a)
	else:
		var ring := ColorRect.new()
		ring.size = Vector2(20, 34)
		ring.position = -ring.size / 2.0
		ring.color = Color(0.4, 0.8, 1.0, 0.6)
		root.add_child(ring)
	return root
