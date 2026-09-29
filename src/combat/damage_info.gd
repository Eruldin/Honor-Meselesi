class_name DamageInfo
extends RefCounted
## Bir vurusun tasidigi veri (DEVIN_PLAN §4.3).
## parryable: parry penceresinde karsilanabilir mi
## pogoable: bu vurusa/kaynaga pogo yapilabilir mi (Hurtbox da tasiyabilir)

var damage: int = 1
var knockback: Vector2 = Vector2.ZERO
var parryable: bool = true
var pogoable: bool = true
var source: Node2D = null  ## saldirgan (parry'de sersemletmek icin)


static func make(dmg: int, src: Node2D, kb := Vector2.ZERO, can_parry := true, can_pogo := true) -> DamageInfo:
	var d := DamageInfo.new()
	d.damage = dmg
	d.source = src
	d.knockback = kb
	d.parryable = can_parry
	d.pogoable = can_pogo
	return d
