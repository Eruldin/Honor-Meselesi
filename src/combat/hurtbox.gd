class_name Hurtbox
extends Area2D
## Hasar alan taraf. Sahibi take_damage() implement eder.
## pogoable: bu hedefe asagi saldiriyla sekip yukselinebilir mi.

signal hit_received(info: DamageInfo)

## Bu hedef "pogoable" mi (ustune inilip sekilir mi — diken, dusman).
@export var pogoable: bool = true


func _ready() -> void:
	monitoring = true
	monitorable = true
	area_entered.connect(_on_area_entered)


func _on_area_entered(area: Area2D) -> void:
	if area is Hitbox:
		area.try_hit(self)


func can_be_hit() -> bool:
	return get_owner_actor() != null and get_owner_actor().has_method("take_damage")


func get_owner_actor() -> Node:
	var n := get_parent()
	while n != null:
		if n.has_method("take_damage"):
			return n
		n = n.get_parent()
	return null


func receive_hit(info: DamageInfo, _hitbox: Hitbox) -> void:
	var actor := get_owner_actor()
	if actor == null:
		return
	hit_received.emit(info)
	actor.take_damage(info)
