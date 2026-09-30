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
