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
	# Overlap listesi ancak bir sonraki fizik adiminda dolar — ayni
	# frame'de sormak bos dondurur, o yuzden bir fizik frame beklenir.
	_late_overlap_check.call_deferred()


func _late_overlap_check() -> void:
	# Node free edilirse baglanti otomatik duser — await-instead kalintisi
	# "class instance is gone" hatasi vermez. Ayni fizik frame'de tekrar
	# aktivasyon tek baglantiyla yeterli (one-shot).
	if not get_tree().physics_frame.is_connected(_check_overlaps):
		get_tree().physics_frame.connect(_check_overlaps, CONNECT_ONE_SHOT)


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
