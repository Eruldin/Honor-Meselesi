class_name PlayerInputSource
extends InputSource
## Gercek klavye/gamepad — project.godot Input Map'ine delege eder.


func move_axis() -> float:
	return Input.get_axis(&"move_left", &"move_right")


func down_held() -> bool:
	return Input.is_action_pressed(&"move_down")


func jump_just_pressed() -> bool:
	return Input.is_action_just_pressed(&"jump")


func jump_just_released() -> bool:
	return Input.is_action_just_released(&"jump")


func jump_held() -> bool:
	return Input.is_action_pressed(&"jump")


func attack_just_pressed() -> bool:
	return Input.is_action_just_pressed(&"attack")


func parry_just_pressed() -> bool:
	return Input.is_action_just_pressed(&"parry")


func dash_just_pressed() -> bool:
	return Input.is_action_just_pressed(&"dash")


func form_next_just_pressed() -> bool:
	return Input.is_action_just_pressed(&"form_next")


func form_prev_just_pressed() -> bool:
	return Input.is_action_just_pressed(&"form_prev")
