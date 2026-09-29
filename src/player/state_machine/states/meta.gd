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
	## Mavi "kod isimasi" gecisi; cikista bekleyen form uygulanir.

	func enter() -> void:
		super.enter()
		sam.sprite_flash(Color(0.2, 0.7, 1.0))
		FX.shake(1.0, 0.15)

	func physics_process(delta: float) -> StringName:
		sam.velocity.x = 0.0
		sam.apply_gravity(delta)
		# Donusum sirasinda hafif buyume/kuculme puls'u
		var s := Vector2.ONE * (1.0 + 0.15 * sin(t * 25.0))
		sam.sprite.scale = s
		if sam._anims != null:
			sam._anims.scale = s * 0.55
		if t >= 0.4:
			return Samurai.S_FALL if not sam.is_on_floor() else Samurai.S_IDLE
		return &""

	func exit() -> void:
		sam.sprite.scale = Vector2.ONE
		if sam._anims != null:
			sam._anims.scale = Vector2.ONE * 0.55
		sam.apply_pending_form()


class Cutscene:
	extends PlayerState
	## Tum girdi yok sayilir; CutscenePlayer cikista durumu degistirir.

	func physics_process(delta: float) -> StringName:
		sam.velocity.x = 0.0
		sam.apply_gravity(delta)
		return &""
