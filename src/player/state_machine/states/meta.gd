extends RefCounted
## Meta durumlar: Rest (checkpoint), Transform (M2'de form gecisi),
## Cutscene (girdi kesilir, CutscenePlayer surer). M1'de minimal.

class Rest:
	extends PlayerState

	func enter() -> void:
		super.enter()
		sam.velocity = Vector2.ZERO
		sam.sprite_flash(Color(0.4, 1.0, 0.6))
		sam.health.reset()

	func physics_process(delta: float) -> StringName:
		sam.apply_gravity(delta)
		if sam.input.move_axis() != 0.0 or sam.input.jump_just_pressed():
			return Samurai.S_IDLE
		return &""


class Transform:
	extends PlayerState

	func physics_process(_delta: float) -> StringName:
		sam.velocity.x = 0.0
		if t >= 0.4:
			return Samurai.S_IDLE
		return &""


class Cutscene:
	extends PlayerState
	## Tum girdi yok sayilir; CutscenePlayer cikista durumu degistirir.

	func physics_process(delta: float) -> StringName:
		sam.velocity.x = 0.0
		sam.apply_gravity(delta)
		return &""
