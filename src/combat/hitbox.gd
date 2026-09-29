class_name Hitbox
extends Area2D
## Saldiri tarafi. Hurtbox'a carptiginda DamageInfo tasir.
## Sadece aktifken (active flag) vurur; her aktivasyonda bir kez vurur.

signal struck(hurtbox: Hurtbox)

@export var auto_damage_info := true

var damage_info: DamageInfo
var _hit_targets: Array[int] = []  ## bu aktivasyonda vurulanlar (instance_id)


func _ready() -> void:
	monitoring = false
	monitorable = true
	set_deferred("monitorable", true)


## Hitbox'i DamageInfo ile ac.
func activate(info: DamageInfo) -> void:
	damage_info = info
	_hit_targets.clear()
	monitoring = true
	# Ayakta duran hurtbox'lari da yakala (overlap zaten varsa).
	call_deferred("_check_overlaps")


func deactivate() -> void:
	monitoring = false
	damage_info = null
	_hit_targets.clear()


func _check_overlaps() -> void:
	if not monitoring:
		return
	for area in get_overlapping_areas():
		if area is Hurtbox:
			try_hit(area)


## Hurtbox tarafindan cagirilir (area_entered) veya overlap taramasiyla.
func try_hit(hurtbox: Hurtbox) -> bool:
	if not monitoring or damage_info == null:
		return false
	if _hit_targets.has(hurtbox.get_instance_id()):
		return false
	if not hurtbox.can_be_hit():
		return false
	_hit_targets.append(hurtbox.get_instance_id())
	hurtbox.receive_hit(damage_info, self)
	struck.emit(hurtbox)
	return true
