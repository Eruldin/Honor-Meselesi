class_name SmokeMage
extends Druid
## Kül diyarı duman büyücüsü (DEVIN_PLAN M8): druid'in kül-mor kardesi.
## Daha genis patlama menzilinde oyuncunun altini koz geyser'le patlatir.


func _init() -> void:
	super._init()
	max_hp = 8
	attack_range = 46.0      # druid'den uzaktan baslar
	speed_override = 20.0    # duman gibi agir


func _ready() -> void:
	super._ready()
	var tint := Color(0.72, 0.58, 0.88)
	sprite.modulate = tint
	if anims != null:
		anims.modulate = tint


## Koz geyser: kul diyarina uyan turuncu-mor patlama.
func _earth_burst(dir: float, _tint := Color.WHITE) -> void:
	super._earth_burst(dir, Color(1.15, 0.8, 0.5))
