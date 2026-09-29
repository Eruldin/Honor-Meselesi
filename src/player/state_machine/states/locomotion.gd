extends RefCounted
## Hareket durumlari: Idle, Run, Jump, Fall, Dash.
## Samurai preload ile yukler: Locomotion.Idle.new(sam) gibi.

class Idle:
	extends PlayerState

	func physics_process(delta: float) -> StringName:
		sam.apply_run(delta, sam.input.move_axis())
		var next := _shared(delta)
		if next != &"":
			return next
		if sam.try_jump():
			return Samurai.S_JUMP
		if not sam.is_on_floor():
			return Samurai.S_FALL
		if absf(sam.input.move_axis()) > 0.1:
			return Samurai.S_RUN
		return &""


class Run:
	extends PlayerState

	func physics_process(delta: float) -> StringName:
		sam.apply_run(delta, sam.input.move_axis())
		var next := _shared(delta)
		if next != &"":
			return next
		if sam.try_jump():
			return Samurai.S_JUMP
		if not sam.is_on_floor():
			return Samurai.S_FALL
		if absf(sam.input.move_axis()) <= 0.1:
			return Samurai.S_IDLE
		return &""


class Jump:
	extends PlayerState

	func physics_process(delta: float) -> StringName:
		var next := _shared(delta)
		if next != &"":
			return next
		sam.apply_run(delta, sam.input.move_axis())
		sam.apply_gravity(delta)
		if sam.input.jump_just_released():
			sam.cut_jump()
		if sam.velocity.y >= 0.0:
			return Samurai.S_FALL
		if sam.is_on_floor():
			return Samurai.S_IDLE
		return &""


class Fall:
	extends PlayerState

	func physics_process(delta: float) -> StringName:
		var next := _shared(delta)
		if next != &"":
			return next
		sam.apply_run(delta, sam.input.move_axis())
		sam.apply_gravity(delta)
		# try_jump hem coyote'yi (havada) hem de buffer'i (inince) kapsar.
		if sam.try_jump():
			return Samurai.S_JUMP
		if sam.is_on_floor():
			return Samurai.S_RUN if absf(sam.input.move_axis()) > 0.1 else Samurai.S_IDLE
		return &""


class Dash:
	extends PlayerState

	func enter() -> void:
		super.enter()
		sam.velocity.y = 0.0
		sam.sprite_flash(Color(0.3, 0.8, 1.0))

	func physics_process(delta: float) -> StringName:
		sam.velocity = Vector2(sam.dash_dir * sam.tuning.dash_speed, 0.0)
		if t >= sam.tuning.dash_time:
			sam.dash_cooldown = sam.tuning.dash_cooldown
			sam.velocity.x *= 0.35
			return Samurai.S_FALL if not sam.is_on_floor() else Samurai.S_IDLE
		return &""
