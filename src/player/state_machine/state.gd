class_name PlayerState
extends RefCounted
## Tek bir oyuncu durumu. sam = sahip Samurai (untyped — dairesel
## bagimliligi engellemek icin). physics_process sonraki durum id'si
## dondurur; bos donerse durum surer.

var sam
var t: float = 0.0  ## durumda gecen sure


func _init(owner) -> void:
	sam = owner


func enter() -> void:
	t = 0.0


func exit() -> void:
	pass


func physics_process(_delta: float) -> StringName:
	return &""


## Tum "normal" durumlarin paylastigi girdi kontrolleri.
func _shared(delta: float) -> StringName:
	if sam.input.attack_just_pressed():
		if sam.is_on_floor():
			if sam.input.up_held():
				sam.start_up_attack()
				return Samurai.S_UP_ATTACK
			sam.start_ground_attack()
			return Samurai.S_ATTACK
		if sam.input.down_held():
			sam.start_down_attack()
			return Samurai.S_DOWN_ATTACK
		if sam.input.up_held():
			sam.start_up_attack()
			return Samurai.S_UP_ATTACK
		sam.start_air_attack()
		return Samurai.S_AIR_ATTACK
	if sam.input.parry_just_pressed():
		sam.start_parry()
		return Samurai.S_PARRY
	if sam.input.dash_just_pressed() and sam.dash_cooldown <= 0.0:
		sam.start_dash()
		return Samurai.S_DASH
	if sam.input.form_next_just_pressed() and sam.cycle_form(1):
		return Samurai.S_TRANSFORM
	if sam.input.form_prev_just_pressed() and sam.cycle_form(-1):
		return Samurai.S_TRANSFORM
	return &""
