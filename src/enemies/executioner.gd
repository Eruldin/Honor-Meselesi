class_name Executioner
extends Villager
## Undead Executioner (DarkPixel-Kronovi) — undead mini-boss: kripta
## bolgesinin agir elit gozcusu. Yavas ama cok sert; icadi agir, temasi
## 2 hasar, sendeleme direncli.


func _init() -> void:
	super._init()
	max_hp = 12
	body_size = Vector2(30, 42)
	asset_key = &"executioner"
	speed_override = 20.0
	knockback_resist = 0.7


func _ready() -> void:
	super._ready()
	contact_hitbox.activate(DamageInfo.make(2, self, Vector2.ZERO, true, true))
