class_name FlyingSword
extends AshBat
## Ucan kilic: havada suzulur, oyuncu menzile girince dalis yapar
## (Castlevania tarzi). AshBat dalis dongusunu kullanir.


func _init() -> void:
	super._init()
	max_hp = 2
	body_size = Vector2(10, 16)
	asset_key = &"long_sword"
