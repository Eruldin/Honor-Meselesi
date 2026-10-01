class_name Gargoyle
extends EnemyBase
## Kül diyarı gargoyle'u (DEVIN_PLAN M8): tas kutle — sadece Robot formu
## kirabilir. Baska formlar vurunca clang + 'swap' piktogrami (donusum
## ipucu, kelimesiz). Robot vurusu normal hasar verir; kirilinca kalinti
## parcasi kalir ve flag'e yazilir — olum/reload'da geri donmez.

@export var gargoyle_id: StringName = &"gargoyle"


func _flag() -> StringName:
	return &"gargoyle_" + gargoyle_id


func _ready() -> void:
	asset_key = &"demon_axe"
	max_hp = 3
	body_size = Vector2(20, 26)
	knockback_resist = 1.0
	contact_damage = false
	super._ready()
	# Govde terrain katmanina da katilir — oyuncu icinden gecemez,
	# kirilana kadar gercek bir tas duvar (player mask=1 ile carpisir).
	collision_layer = 64 | 1
	# Tas: gri donuk ton — yasayan dusman degil kalinti.
	sprite.modulate = Color(0.55, 0.52, 0.58)
	if anims != null:
		anims.modulate = Color(0.55, 0.52, 0.58)
		anims.speed_scale = 0.0  # heykel kipirdamaz
	if GameState.get_flag(_flag(), false):
		queue_free()


## Robot disi vurus tasla seker: clang + kivilcim + 'donusum' ipucu.
## damage_dealt emit edilmez — zirh farm'i yok (Guard clang kurali).
func take_damage(info: DamageInfo) -> void:
	if not health.is_alive():
		return
	var robot_hit: bool = info.source is Samurai \
		and (info.source as Samurai).form != null \
		and (info.source as Samurai).form.id == &"robot"
	if not robot_hit:
		AudioManager.play_sfx(&"sfx/clang", global_position)
		FX.spark(global_position + Vector2(0, -body_size.y * 0.4))
		Pictogram.show_on(self, &"swap", 0.9, Vector2(0, -body_size.y - 12))
		return
	super.take_damage(info)


## Tas kirilinca bayrak duser — reload'da geri gelmez.
func _on_died() -> void:
	GameState.set_flag(_flag())
	SaveSystem.save_game()
	super._on_died()
