class_name Druid
extends Villager
## Orman buyucusu (DuskBorne): yavas ama dayanikli elit — oyuncuya
## yaklastikca saldiri animsiyonu oynar.


func _init() -> void:
	super._init()
	max_hp = 7
	body_size = Vector2(20, 32)
	asset_key = &"druid"
	speed_override = 28.0


func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	# Oyuncu yakinsa saldiri animi (vurus hitbox'i temas hitbox'idir)
	if _player != null and health.is_alive() and not is_staggered():
		var dx: float = _player.global_position.x - global_position.x
		if absf(dx) < 30.0 and _anim_lock <= 0.0:
			play_anim(&"attack", 0.7)
			AudioManager.play_sfx(&"sfx/swipe", global_position, -10.0, 0.9)
			_earth_burst(signf(dx))


## Saldiri aninda onundeki zeminde yer-patlama efekti — buyucu imzasi.
func _earth_burst(dir: float) -> void:
	if not AssetLoader.has_frames(&"fx/druid_earth"):
		return
	var fx := AnimatedSprite2D.new()
	fx.sprite_frames = AssetLoader.frames(&"fx/druid_earth")
	var ts: Vector2 = fx.sprite_frames.get_frame_texture(&"default", 0).get_size()
	fx.scale = Vector2.ONE * (46.0 / ts.y)
	fx.position = Vector2(dir * 18.0, -ts.y * fx.scale.y * 0.5)
	fx.z_index = 2
	add_child(fx)
	fx.play(&"default")
	fx.animation_finished.connect(fx.queue_free, CONNECT_ONE_SHOT)
