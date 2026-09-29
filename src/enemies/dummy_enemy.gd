class_name DummyEnemy
extends EnemyBase
## Test odasi kuklasi: saldirmaz, sadece hasar alir. Parry testi
## Turret+Projectile ikilisiyle yapilir.


func _init() -> void:
	max_hp = 3
	body_size = Vector2(14, 18)
	asset_key = &"dummy"
