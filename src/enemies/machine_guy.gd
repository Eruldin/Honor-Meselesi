class_name MachineGuy
extends Villager
## Dead Pixels makine adam — cyberpunk bolgesi robot piyade.
## Iki uniform varyasyonu (variant 1-2).


@export var variant: int = 1


func _init() -> void:
	super._init()
	max_hp = 4
	body_size = Vector2(14, 22)
	asset_key = &"machine_guy"
	speed_override = 42.0
	aggro_sfx = &"sfx/ui"
	aggro_db = -12.0
	aggro_pitch = 0.8


func _ready() -> void:
	if variant > 1:
		asset_key = &"machine_guy_b"
	super._ready()
