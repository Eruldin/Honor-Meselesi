class_name FormReveal
extends Node2D
## Yeni form acilinca oyuncunun ustunde beliren gorsel (kelimesiz):
## form sprite'i ufaktan buyuyerek belirir, parlar, biraz kalir, kaybolur.
## Kullanim: FormReveal.show_on(samurai, &"tavuk")

const HOLD := 1.1
const RISE := 0.35
const FALL := 0.3


static func show_on(host: Node2D, form_id: StringName) -> FormReveal:
	var r := FormReveal.new()
	host.add_child(r)
	r.z_index = 30
	r._present(host, form_id)
	return r


func _present(host: Node2D, form_id: StringName) -> void:
	var form := FormLibrary.get_form(form_id)
	var tex_id := &"player/%s/idle" % form_id
	if form != null and form.sprite_asset != &"" \
			and AssetLoader.has_asset(form.sprite_asset):
		tex_id = form.sprite_asset
	var sp := Sprite2D.new()
	sp.texture = AssetLoader.texture(tex_id, Vector2i(18, 18))
	sp.position = Vector2(0, -30)
	sp.modulate = (form.sprite_color if form != null else Color.WHITE) * Color(1.3, 1.3, 1.3, 1.0)
	add_child(sp)

	FX.spark(host.global_position + Vector2(0, -30))
	AudioManager.play_sfx(&"sfx/checkpoint", host.global_position, -2.0)

	var tw := create_tween()
	sp.scale = Vector2(0.15, 0.15)
	tw.tween_property(sp, "scale", Vector2(1.15, 1.15), RISE)\
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(sp, "scale", Vector2.ONE, 0.12)
	tw.tween_interval(HOLD)
	tw.tween_property(sp, "scale", Vector2(0.0, 0.0), FALL)\
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tw.finished.connect(queue_free)
