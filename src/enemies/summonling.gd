class_name Summonling
extends Villager
## Executioner'in cagirdigi kucuk golemciik — appear animiyle yerden cikar,
## tek canlik hizli tacizci. Sayisi SummonCap ile sinirli.


func _init() -> void:
	max_hp = 1
	body_size = Vector2(12, 10)
	asset_key = &"summonling"
	speed_override = 52.0
	contact_damage = true


func _ready() -> void:
	super._ready()
	add_to_group(&"summonling")
	stagger_timer = 0.45
	play_anim(&"appear", 0.45)
