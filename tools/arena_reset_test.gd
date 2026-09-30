extends "res://src/levels/ch1/ch1.gd"
## Arena soft-lock regresyonu: boss tetik -> oyuncuyu oldur -> respawn'da
## duvarlar inmeli, boss sifirlanmali, tetik yeniden ateslenebilmeli.

var _ai: AIInputSource


func _ready() -> void:
	auto_advance = false
	super._ready()
	_ai = AIInputSource.new()
	samurai.set_input_source(_ai)
	# checkpoint'i arena oncesi dinlenmeye al (4050)
	GameState.set_flag(&"respawn_pos", Vector2(4050, FLOOR_Y - 4))
	_run()


func _run() -> void:
	await get_tree().create_timer(0.6).timeout
	samurai.global_position = Vector2(4560, FLOOR_Y - 20)
	await get_tree().create_timer(0.4).timeout
	# tetigi dogal gec
	samurai.global_position.x = 4585
	await get_tree().create_timer(2.0).timeout
	print("[R] started=%s wall0=%s boss_active=%s" % [
		_boss_started, _arena_walls[0].collision_layer, boss.active])
	# oyuncuyu oldur
	samurai.take_damage(DamageInfo.make(99, boss, Vector2.ZERO, true, true))
	await get_tree().create_timer(2.5).timeout
	print("[R] after-death: samx=%.0f wall0=%s boss_active=%s boss_hp=%s started=%s" % [
		samurai.global_position.x, _arena_walls[0].collision_layer,
		boss.active, boss.health.current, _boss_started])
	print("[R] boss_pos=%.0f (home=%.0f)" % [boss.global_position.x, _boss_home.x])
	# tekrar yakla? tetik yeniden ateslenmeye hazir olmali
	samurai.global_position.x = 4520
	await get_tree().create_timer(0.5).timeout
	samurai.global_position.x = 4590
	await get_tree().create_timer(1.0).timeout
	print("[R] re-enter: started=%s wall0=%s boss_active=%s" % [
		_boss_started, _arena_walls[0].collision_layer, boss.active])
	get_viewport().get_texture().get_image().save_png("res://.probe_out/arena_reset.png")
	get_tree().quit()
