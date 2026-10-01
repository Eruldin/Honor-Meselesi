extends "res://src/levels/prolog/prolog.gd"
## M10 epilog — Prolog kulubesi yeniden kullanilir, rolleri ters
## (DEVIN_PLAN spec: genc samuray sapkayi alir, dikey glitch kesme).
## Genç samuray ayni sekilde oturur; bu kez Glitch Yaratik
## sapkayi GERI VERIR — dongunun basa sardigi gorulur. Sonra
## dikey glitch kesme + jenerik + Prolog'a donus.

const CREDITS_MUSIC := &"music/credits"
const PROLOG_PATH := "res://src/levels/prolog/Prolog.tscn"


func _start_sequence() -> void:
	_phase = &"cutscene"
	# Roller ters: yaratik sapkayi TASIYOR — sapka bu sahnede
	# yaratigin elinde baslar, oturan genc samuraya verilir.
	creature.visible = true
	creature.global_position = Vector2(430, FLOOR_Y - 20)
	if is_instance_valid(creature_sprite) and creature_sprite is AnimatedSprite2D:
		(creature_sprite as AnimatedSprite2D).flip_h = true
	hat.get_parent().remove_child(hat)
	creature.add_child(hat)
	hat.position = Vector2(0, -30)   # yaratigin basinin ustunde tasir
	hat.rotation = 0.15
	cutscene = CutscenePlayer.new()
	add_child(cutscene)
	var cs_ref: WeakRef = weakref(cutscene)
	cutscene.play(_steps(), {
		"creature": creature, "samurai": samurai, "black": black,
	}, _apply_end_state)
	var tw := create_tween()
	tw.tween_property(black, "modulate:a", 0.0, 1.2)
	await tw.finished
	if not is_instance_valid(cs_ref.get_ref()):
		return


func _steps() -> Array:
	return [
		# Yaratik sapkayla oturan gence yaklasir — calmaya degil,
		# vermeye geldi: yavas, temkinli adimlar.
		{op = "walk_to", node = "creature", x = 258.0, speed = 55.0},
		{op = "wait", t = 0.5},
		# Sapkayi genc samurayin basina birakir — calinan an
		# geri verilir; iki taraf ayni kisi gibi durur.
		{op = "call", fn = func() -> void:
			hat.get_parent().remove_child(hat)
			samurai.add_child(hat)
			hat.position = Vector2(2, -26)
			hat.rotation = 0.0
			FX.spark(samurai.global_position + Vector2(0, -22))},
		{op = "wait", t = 0.7},
		# Yaratik geri cekilir — isi bitti; dongu tekrar basliyor.
		{op = "hop_to", node = "creature", to = Vector2(360, FLOOR_Y - 26),
			dur = 0.55, arc = 22.0},
		{op = "wait", t = 0.8},
		{op = "call", fn = _vertical_glitch_cut},
	]


func _apply_end_state() -> void:
	# Skip guvenligi: atlama takas anindan once gelebilir — sapka
	# genc samurayin basinda, kesme aninda sahne karanlik olmali.
	if hat.get_parent() != samurai:
		hat.get_parent().remove_child(hat)
		samurai.add_child(hat)
		hat.position = Vector2(2, -26)
		hat.rotation = 0.0
	_start_credits()


func _vertical_glitch_cut() -> void:
	# Dikey glitch kesme: ekranin ortasinda ince bir isik yirtigi
	# belirir, titreyerek genisler — sonra siyah + jenerik.
	var cut := ColorRect.new()
	cut.color = Color(0.85, 0.95, 1.0)
	cut.size = Vector2(2, 270)
	cut.position = Vector2(239, 0)
	var layer := CanvasLayer.new()
	layer.layer = 60
	add_child(layer)
	layer.add_child(cut)
	FX.glitch(1.6, 0.9)
	var tw := create_tween()
	tw.tween_property(cut, "size:x", 12.0, 0.35)
	tw.parallel().tween_property(cut, "position:x", 234.0, 0.35)
	tw.tween_property(cut, "size:x", 3.0, 0.12)
	tw.parallel().tween_property(cut, "position:x", 238.5, 0.12)
	tw.tween_property(cut, "size:x", 26.0, 0.18)
	tw.parallel().tween_property(cut, "position:x", 227.0, 0.18)
	tw.tween_property(black, "modulate:a", 1.0, 0.25)
	await tw.finished
	layer.queue_free()
	_start_credits()


func _start_credits() -> void:
	AudioManager.play_music(CREDITS_MUSIC)
	var credits := Credits.new()
	add_child(credits)
	credits.finished.connect(func() -> void:
		# Epilog bitti — dongu kapandi; Continue Prolog'a doner.
		GameState.set_flag(&"epilog_done", true)
		SaveSystem.save_game()
		if auto_advance:
			EventBus.scene_change_requested.emit(PROLOG_PATH),
		CONNECT_ONE_SHOT)
