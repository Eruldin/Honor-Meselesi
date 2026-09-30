class_name Soldier
extends Villager
## Orius cyberpunk askeri — bolum 2'nin piyade dusmani. Dort uniform
## varyasyonundan biri (variant 1-4).


@export var variant: int = 1


func _init() -> void:
	super._init()
	max_hp = 3
	body_size = Vector2(12, 18)
	asset_key = &"soldier1"
	speed_override = 45.0


func _ready() -> void:
	variant = clampi(variant, 1, 4)
	asset_key = StringName("soldier%d" % variant)
	super._ready()
