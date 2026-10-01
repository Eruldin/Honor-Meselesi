extends RefCounted
## Savunma/reaksiyon durumlari: Parry, Hurt, Dead.

class Parry:
	extends PlayerState

	func enter() -> void:
		super.enter()
		sam.parry_timer = sam.tuning.parry_window
		sam.parry_succeeded = false
		sam.velocity.x = 0.0
		sam.sprite_flash(Color(0.4, 0.9, 1.0))

	func physics_process(delta: float) -> StringName:
		sam.parry_timer -= delta
		sam.apply_gravity(delta)
		if sam.parry_succeeded:
			# Basarili parry sonrasi kisa gurur payi.
			return Samurai.S_IDLE if t >= 0.15 else &""
		if t >= sam.tuning.parry_window + sam.tuning.parry_recovery:
			return Samurai.S_FALL if not sam.is_on_floor() else Samurai.S_IDLE
		return &""

	func exit() -> void:
		sam.parry_timer = 0.0
		if not sam.parry_succeeded and sam.health.is_alive():
			EventBus.parry_whiffed.emit(sam)


class Hurt:
	extends PlayerState

	func enter() -> void:
		super.enter()
		sam.sprite_flash(Color(1.0, 0.2, 0.2))

	func physics_process(delta: float) -> StringName:
		sam.apply_gravity(delta)
		sam.velocity.x = move_toward(sam.velocity.x, 0.0, sam.tuning.ground_decel * delta)
		if t >= sam.tuning.hurt_stun_time:
			return Samurai.S_FALL if not sam.is_on_floor() else Samurai.S_IDLE
		return &""


class Dead:
	extends PlayerState

	func enter() -> void:
		super.enter()
		sam.velocity = Vector2.ZERO
		sam.sprite_flash(Color(0.2, 0.2, 0.2))

	func physics_process(delta: float) -> StringName:
		sam.velocity.x = 0.0
		sam.apply_gravity(delta)
		return &""  # cikis: SceneRouter/respawn veya test
