class_name CutscenePlayer
extends Node
## Metinsiz sinematik zaman cizelgesi yurutucusu (DEVIN_PLAN M3).
## Adimlar: Array[Dictionary] — her adimda "op" anahtari ve parametreler.
## ctx: dugum isimleri -> Node2D eslemesi (orn. {"samurai": ..., "creature": ...}).
##
## Desteklenen op'ler:
##   {op="wait", t=1.0}
##   {op="call", fn=Callable}
##   {op="flag", key=&"hat_stolen", value=true}
##   {op="face", node="samurai", dir=-1}
##   {op="walk_to", node="samurai", x=120.0, speed=55.0}   # yatay, hiza gore sure
##   {op="move_to", node="creature", to=Vector2(..), dur=0.8}
##   {op="hop_to",  node="creature", to=Vector2(..), dur=0.5, arc=30.0}
##   {op="picto", node="samurai", icon=&"alarm", t=1.2}
##   {op="glitch", strength=1.0, dur=0.8}
##   {op="fade", target=black_overlay, to_a=1.0, dur=0.4}
##
## pause (Esc) basinca: kalan adimlar iptal, end_state() cagrilir (varsa),
## finished yayilir. _input'ta yakalanir ki Esc ayar menusunu acmaz.

signal finished
signal step_started(index: int)

var playing := false
var skippable := true

var _steps: Array = []
var _ctx: Dictionary = {}
var _end_state: Callable = Callable()
var _idx := -1
var _active_tween: Tween


func play(steps: Array, ctx: Dictionary, end_state: Callable = Callable()) -> void:
	_steps = steps
	_ctx = ctx
	_end_state = end_state
	playing = true
	_idx = -1
	EventBus.cutscene_started.emit(&"cutscene")
	_advance()


func request_skip() -> void:
	if not playing:
		return
	playing = false
	if _active_tween != null and _active_tween.is_valid():
		_active_tween.kill()
	if _end_state.is_valid():
		_end_state.call()
	_finish()


func _input(event: InputEvent) -> void:
	if playing and skippable and event.is_action_pressed(&"pause"):
		get_viewport().set_input_as_handled()
		request_skip()


func _advance() -> void:
	while playing:
		_idx += 1
		if _idx >= _steps.size():
			_finish()
			return
		step_started.emit(_idx)
		await _run_step(_steps[_idx])
		# Skip sirasinda await icinde durdurulmus olabiliriz.
		if not playing:
			return


func _finish() -> void:
	playing = false
	finished.emit()
	EventBus.cutscene_finished.emit(&"cutscene")


func _run_step(s: Dictionary) -> void:
	match String(s.get("op", "")):
		"wait":
			await _timer(float(s.get("t", 0.0)))
		"call":
			var fn: Callable = s.get("fn", Callable())
			if fn.is_valid():
				fn.call()
		"flag":
			GameState.set_flag(StringName(s.get("key", "")), s.get("value", true))
		"face":
			_face(_node(s), int(s.get("dir", 1)))
		"walk_to":
			var n := _node(s) as Node2D
			if n == null:
				return
			var target_x := float(s.get("x", n.global_position.x))
			var speed: float = maxf(float(s.get("speed", 55.0)), 1.0)
			_face(n, 1 if target_x > n.global_position.x else -1)
			var dur := absf(target_x - n.global_position.x) / speed
			# Tween tasisir: oyuncunun kendi _process'i adim hissi uretmez —
			# kosu animi ve ritmik ayak sesi kesik sahneye taslanir.
			if n is Samurai and n._anims != null:
				n._anims.play(&"run")
				# _sync_anim want'u _anim_name ile karsilastirir; takip
				# degiskeni o anki want'a sabitlenmezse sonraki frame
				# kosu animini idle ile ezer.
				n._anim_name = &"idle"
				# Yavas yaklasma kosu adimi gibi gorunmesin.
				n._anims.speed_scale = clampf(speed / 130.0, 0.6, 1.3)
			_walk_sfx(n, dur)
			await _move(n, Vector2(target_x, n.global_position.y), dur, 0.0)
			if n is Samurai:
				# _anim_name sifirlaninca _sync_anim sonraki frame idle'a doner.
				n._anim_name = &""
				if n._anims != null:
					n._anims.speed_scale = 1.0
		"move_to":
			await _move(_node(s) as Node2D, s.get("to", Vector2.ZERO),
				float(s.get("dur", 0.5)), 0.0)
		"hop_to":
			var n := _node(s) as Node2D
			var dur := float(s.get("dur", 0.5))
			if n is Samurai and n._anims != null:
				# Ark bir sicrayis — idle kayma yerine ziplama pozu.
				n._anims.play(&"jump")
				n._anim_name = &"idle"
			await _move(n, s.get("to", Vector2.ZERO), dur,
				float(s.get("arc", 26.0)))
			if n is Samurai:
				n._anim_name = &""
		"picto":
			var n := _node(s)
			var p := Pictogram.show_on(n, StringName(s.get("icon", &"alarm")),
				float(s.get("t", 1.4)), s.get("offset", Vector2(0, -32)))
			# Balonu cutscene iptalinde de koru — kendi tween'iyle solar.
			if s.get("wait", false):
				await _timer(float(s.get("t", 1.4)))
		"glitch":
			FX.glitch(float(s.get("strength", 1.0)), float(s.get("dur", 0.6)))
		"fade":
			var n := _node(s)
			if n != null:
				var tw := _new_tween()
				tw.tween_property(n, "modulate:a", float(s.get("to_a", 1.0)),
					float(s.get("dur", 0.4)))
				await tw.finished
		_:
			push_warning("CutscenePlayer: bilinmeyen op '%s'" % s.get("op"))


## Kesik-sahne yuruyusunde ritmik ayak sesi — oyuncunun kendi adim
## mekanigi S_CUTSCENE'de calismadigindan burada sayilir.
func _walk_sfx(n: Node2D, dur: float) -> void:
	if not (n is Samurai):
		return
	var t := 0.0
	while t < dur:
		AudioManager.play_sfx(
			StringName("sfx/step_dirt_" + str(randi() % 4 + 1)),
			n.global_position, -13.0, randf_range(0.9, 1.1))
		t += 0.30
		if t < dur:
			await _timer(0.30)


func _move(n: Node2D, to: Vector2, dur: float, arc: float) -> void:
	if n == null or dur <= 0.0:
		if n != null:
			n.global_position = to
		return
	var from := n.global_position
	var tw := _new_tween()
	if arc > 0.0:
		tw.tween_method(func(p: float) -> void:
			n.global_position = Vector2(
				lerpf(from.x, to.x, p),
				lerpf(from.y, to.y, p) - sin(p * PI) * arc), 0.0, 1.0, dur)
	else:
		tw.tween_property(n, "global_position", to, dur)
	await tw.finished


func _face(n: Node, dir: int) -> void:
	if n == null:
		return
	if n is Samurai:
		n.facing = dir
		n.sprite.flip_h = dir < 0
	elif "facing" in n:
		n.facing = dir
	var spr := n.get_node_or_null("sprite") as Sprite2D
	if spr != null:
		spr.flip_h = dir < 0


func _node(s: Dictionary) -> CanvasItem:
	var key := String(s.get("node", ""))
	var n: Variant = _ctx.get(key)
	if n is CanvasItem:
		return n
	push_warning("CutscenePlayer: ctx'te node yok: %s" % key)
	return null


func _new_tween() -> Tween:
	_active_tween = create_tween()
	_active_tween.set_ignore_time_scale(false)
	return _active_tween


func _timer(t: float) -> void:
	if t <= 0.0:
		return
	await get_tree().create_timer(t, false).timeout
