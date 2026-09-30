extends "res://src/levels/ch1/ch1.gd"
## Sovalye + kapi akisi probe: oyuncuyu sovalyenin yanina koyar,
## AI ile yuruyup saldirir, durumu loglar.

var _ai: AIInputSource


func _ready() -> void:
	auto_advance = false
	super._ready()
	_ai = AIInputSource.new()
	samurai.set_input_source(_ai)
	samurai.global_position = Vector2(4180, FLOOR_Y - 30)
	samurai.velocity = Vector2.ZERO
	_run()


func _run() -> void:
	await get_tree().create_timer(0.5).timeout
	var t := 0.0
	while t < 20.0:
		_ai.axis(1.0)
		_ai.tap(&"attack")
		await get_tree().create_timer(0.5).timeout
		t += 0.5
		var gs := -1.0
		if _gate_body != null:
			gs = _gate_body.modulate.a
		print("[GATE t=%.1f] sam=%.0f,hp=%d kn_hp=%s kn_x=%s boss=%s gate_a=%.2f" % [
			t, samurai.global_position.x, samurai.health.current,
			str(knight.health.current) if is_instance_valid(knight) else "DEAD",
			str(snapped(knight.global_position.x, 0.1)) if is_instance_valid(knight) else "-",
			str(boss.bstate) if is_instance_valid(boss) else "?",
			gs,
		])
		if (not is_instance_valid(knight) or not knight.health.is_alive()) and gs < 0.1:
			break
	# Kapi acildi — arena tetigini dogal gec, boss aktive olsun
	_ai.tap(&"attack")
	var t2 := 0.0
	while samurai.global_position.x < 4700 and t2 < 15.0:
		_ai.axis(1.0)
		await get_tree().create_timer(0.5).timeout
		t2 += 0.5
	_ai.axis(0.0)
	await get_tree().create_timer(1.5).timeout
	print("[BOSS] sam=%.0f bstate=%s active=%s" % [
		samurai.global_position.x,
		str(boss.bstate),
		str(boss.active),
	])
	get_tree().quit()
