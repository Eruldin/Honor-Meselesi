class_name InputSource
extends Node
## Girdi soyutlamasi (DEVIN_PLAN §4.1). Samuray Input'a dogrudan
## dokunmaz; girdiyi buradan okur. PlayerInputSource gercek kontrolcuyu,
## AIInputSource ise Bolum 7'de samurayi boss olarak surmek (ve testlerde
## deterministik girdi uretmek) icin kodu baglar.

## Her fizik frame basinda sahip tarafindan bir kez cagirilir.
func poll() -> void:
	pass

## -1..1 yatay eksen.
func move_axis() -> float:
	return 0.0

func down_held() -> bool:
	return false

func jump_just_pressed() -> bool:
	return false

func jump_held() -> bool:
	return false

func jump_just_released() -> bool:
	return false

func attack_just_pressed() -> bool:
	return false

func parry_just_pressed() -> bool:
	return false

func dash_just_pressed() -> bool:
	return false

func focus_just_pressed() -> bool:
	return false

func form_next_just_pressed() -> bool:
	return false

func form_prev_just_pressed() -> bool:
	return false
