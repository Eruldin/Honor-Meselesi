class_name Eagle
extends AshBat
## Acik hava dalgici: yarasadan buyuk, yavas yaklasir ama daha sert dalar.


func _init() -> void:
	super._init()
	max_hp = 4
	body_size = Vector2(20, 14)
	asset_key = &"eagle"
