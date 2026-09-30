class_name CaveBat
extends AshBat
## Bolum 1 magara yarasa: AshBat davranisi + Dark Fantasy bat sprite'lari.


func _init() -> void:
	super._init()
	max_hp = 3
	body_size = Vector2(16, 12)
	asset_key = &"bat"
