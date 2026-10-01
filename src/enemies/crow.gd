class_name Crow
extends AshBat
## Plague Crow — elit mini-boss yaratigi (gecit yaklasimi bekcesi).
## AshBat dalis dongusunun daha sert ve dayanikli hali.


func _init() -> void:
	super._init()
	max_hp = 8
	body_size = Vector2(24, 18)
	contact_damage = true
	asset_key = &"crow"
	knockback_resist = 0.5


func _ready() -> void:
	super._ready()
	# Elit temas = 2 hasar — sersemleme sonrasi re-aktivasyon da bunu kullanir
	_contact_info = DamageInfo.make(2, self, Vector2.ZERO, true, true)
	contact_hitbox.activate(_contact_info)
