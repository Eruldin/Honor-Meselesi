extends RefCounted
## Saldiri durumlari: Attack (3'lu kombo), AirAttack, DownAttack (pogo).

class Attack:
	extends PlayerState

	func enter() -> void:
		super.enter()
		sam.sprite_flash(Color(1.0, 0.45, 0.35))
		# Her kombo vurusuna kendi kesik efekti + savrus sesi;
		# 3. vurus agir sheet + daha guclu hasar (finisher).
		sam._spawn_slash(sam.combo_index >= 3)
		AudioManager.play_sfx(&"sfx/attack", sam.global_position)
		if sam.combo_index >= 2:
			# Zincir vurusu: her yeni vurus hafif ileri tasir — kombo
			# sabit durmak yerine dusmani takip eder.
			sam.velocity.x += sam.facing * sam.tuning.attack_lunge * 0.6

	func physics_process(delta: float) -> StringName:
		var tun: Tuning = sam.tuning
		# Yer saldirisi hareketi kilitler, hafif surtunme.
		sam.velocity.x = move_toward(sam.velocity.x, 0.0, tun.ground_decel * delta)
		if sam.input.attack_just_pressed() and sam.combo_index < 3:
			sam.combo_queued = true
		var active_start := tun.attack_duration * tun.attack_active_start
		var active_end := tun.attack_duration * tun.attack_active_end
		if t >= active_start and t <= active_end:
			sam.ensure_attack_hitbox()
		if not sam.is_on_floor():
			return Samurai.S_FALL  # kenardan dustu: saldiri iptal
		if t >= tun.attack_duration:
			if sam.combo_queued and sam.combo_index < 3:
				sam.combo_index += 1
				sam.combo_queued = false
				enter()  # ayni duruma zincir
				return &""
			return Samurai.S_IDLE
		return &""

	func exit() -> void:
		sam.attack_hitbox.deactivate()
		sam.combo_index = 0
		sam.combo_queued = false


class UpAttack:
	extends PlayerState
	## Yukari kesik (HK up-slash): yerde veya havada yukari+saldiri.
	## Ucan dusmanlari (yarasa/karga/drone) vurmanin tek dogrudan yolu.

	func enter() -> void:
		super.enter()
		sam.sprite_flash(Color(0.7, 0.9, 1.0))
		sam._spawn_slash(false, true)
		AudioManager.play_sfx(&"sfx/attack", sam.global_position)

	func physics_process(delta: float) -> StringName:
		var tun: Tuning = sam.tuning
		if sam.is_on_floor():
			sam.velocity.x = move_toward(sam.velocity.x, 0.0, tun.ground_decel * delta)
		else:
			sam.apply_run(delta, sam.input.move_axis())
			sam.apply_gravity(delta)
		if t >= tun.air_attack_duration * tun.attack_active_start and t <= tun.air_attack_duration * tun.attack_active_end:
			sam.ensure_up_hitbox()
		if t >= tun.air_attack_duration:
			return Samurai.S_IDLE if sam.is_on_floor() else Samurai.S_FALL
		return &""

	func exit() -> void:
		sam.up_hitbox.deactivate()


class AirAttack:
	extends PlayerState

	func enter() -> void:
		super.enter()
		sam.sprite_flash(Color(1.0, 0.55, 0.35))
		sam._spawn_slash(false)
		AudioManager.play_sfx(&"sfx/attack", sam.global_position)

	func physics_process(delta: float) -> StringName:
		var tun: Tuning = sam.tuning
		sam.apply_run(delta, sam.input.move_axis())
		sam.apply_gravity(delta)
		if t >= tun.air_attack_duration * tun.attack_active_start and t <= tun.air_attack_duration * tun.attack_active_end:
			sam.ensure_attack_hitbox()
		if sam.is_on_floor():
			return Samurai.S_IDLE
		if t >= tun.air_attack_duration:
			return Samurai.S_FALL
		return &""

	func exit() -> void:
		sam.attack_hitbox.deactivate()


class DownAttack:
	extends PlayerState
	## Havada asagi + saldiri. Pogoable hurtbox'a degerse samurai
	## _on_down_struck uzerinden yukari seker (Hollow Knight pogo'su).

	func enter() -> void:
		super.enter()
		sam.sprite_flash(Color(1.0, 0.8, 0.2))
		sam.velocity.x = move_toward(sam.velocity.x, 0.0, 400.0)

	func physics_process(delta: float) -> StringName:
		var tun: Tuning = sam.tuning
		sam.apply_gravity(delta)
		# Asagi saldiri aninda aktif — pogo dusus sirasinda gecikmesin.
		if t <= tun.down_attack_duration * tun.attack_active_end:
			sam.ensure_down_hitbox()
		if sam.is_on_floor():
			return Samurai.S_IDLE
		if t >= tun.down_attack_duration:
			return Samurai.S_FALL
		return &""

	func exit() -> void:
		sam.down_hitbox.deactivate()
