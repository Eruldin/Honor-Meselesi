class_name ImpRed
extends Villager
## Kucuk kizil imp — kalabalik surpriz dusman; hizli, zayif.


func _init() -> void:
	super._init()
	max_hp = 2
	body_size = Vector2(13, 14)
	asset_key = &"imp_red"
	speed_override = 70.0
	aggro_pitch = 1.4
