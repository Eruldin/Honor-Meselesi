class_name PortalFx
extends RefCounted
## Bolum sonu portali gorseli: gercek portal animasyonu varsa onu
## kullanir, yoksa renkli halka placeholder.


static func make(size := Vector2(24, 40)) -> Node2D:
	var root := Node2D.new()
	if AssetLoader.has_frames(&"fx/portal"):
		var a := AnimatedSprite2D.new()
		a.sprite_frames = AssetLoader.frames(&"fx/portal")
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
