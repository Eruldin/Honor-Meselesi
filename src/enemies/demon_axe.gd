class_name DemonAxe
extends Villager
## Imp Axe Demon (SanctumPixel): gecit bolgesi orta-agirlik dusmani —
## koyluden daha dayanikli ve buyuk.


func _init() -> void:
	super._init()
	max_hp = 5
	body_size = Vector2(18, 20)
	asset_key = &"demon_axe"
	speed_override = 34.0
