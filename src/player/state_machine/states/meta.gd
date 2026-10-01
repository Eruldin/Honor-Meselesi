extends RefCounted
## Meta durumlar: Rest (checkpoint), Transform (M2'de form gecisi),
## Cutscene (girdi kesilir, CutscenePlayer surer). M1'de minimal.

class Rest:
	extends PlayerState
	var _inspect_done := false

	func enter() -> void:
		super.enter()
		_inspect_done = false
		sam.velocity = Vector2.ZERO
		sam.sprite_flash(Color(0.4, 1.0, 0.6))
		sam.health.reset()
		# M9: bellek dunyasinda yorgunluk — basini ellerine alma pozu
		if GameState.current_chapter == &"ch6":
			sam.set_weary_visual(true)

	func exit() -> void:
		sam.set_weary_visual(false)
		sam.set_katana_inspect_visual(false)

	func physics_process(delta: float) -> StringName:
		sam.apply_gravity(delta)
		# M9 ikinci vurus: ~1.6s yorgunluktan sonra katananin
		# catlagina bakma pozuna gecer.
		if not _inspect_done and t > 1.6 \
				and GameState.current_chapter == &"ch6":
			_inspect_done = true
			sam.set_weary_visual(false)
			sam.set_katana_inspect_visual(true)
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
		FX.spark(sam.global_position)
		AudioManager.play_sfx(&"sfx/ghost", sam.global_position, -8.0, 1.25)

	func physics_process(delta: float) -> StringName:
		sam.velocity.x = 0.0
		sam.apply_gravity(delta)
		# Donusum sirasinda hafif buyume/kuculme puls'u
		var s := Vector2.ONE * (1.0 + 0.15 * sin(t * 25.0))
		sam.sprite.scale = s
		if sam._anims != null:
			sam._anims.scale = s * Samurai.ANIMS_SCALE
		if t >= 0.4:
			return Samurai.S_FALL if not sam.is_on_floor() else Samurai.S_IDLE
		return &""

	func exit() -> void:
		sam.sprite.scale = Vector2.ONE
		if sam._anims != null:
			sam._anims.scale = Vector2.ONE * Samurai.ANIMS_SCALE
		sam.apply_pending_form()


class Cutscene:
	extends PlayerState
	## Tum girdi yok sayilir; CutscenePlayer cikista durumu degistirir.

	func physics_process(delta: float) -> StringName:
		sam.velocity.x = 0.0
		sam.apply_gravity(delta)
		return &""
