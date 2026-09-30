class_name HackTerminal
extends Area2D
## Guvenlik terminali: sadece Drone formu (can_hack) hackleyebilir.
## Drone yaklastiginda otomatik hack baslar; bitince eslik eden
## LaserGate (gate_id) acilir. Metinsiz: yesil->sari->kapali isiklar.

signal hacked(gate_id: StringName)

@export var gate_id: StringName = &"gate"

var _player: Node2D
var _hacking := false
var _done := false
var _prog := 0.0
var _lamp: ColorRect
var _tuning: Tuning


func _ready() -> void:
	_tuning = load("res://config/tuning.tres")
	collision_layer = 0
	collision_mask = 4
	var col := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(30, 30)
	col.shape = rect
	add_child(col)

	var body := ColorRect.new()
	body.color = Color(0.1, 0.15, 0.2)
	body.size = Vector2(14, 22)
	body.position = Vector2(-7, -11)
	add_child(body)
	_lamp = ColorRect.new()
	_lamp.color = Color(0.9, 0.25, 0.3)  # kilitli = kirmizi
	_lamp.size = Vector2(10, 4)
	_lamp.position = Vector2(-5, -9)
	add_child(_lamp)

	add_to_group(&"terminals")
	area_entered.connect(func(a: Area2D) -> void: _check(a))
	area_exited.connect(func(a: Area2D) -> void: _stop(a))


func _player_from(area: Area2D) -> Node:
	var n := area.get_parent()
	while n != null and not n.is_in_group(&"player"):
		n = n.get_parent()
	return n


func _check(area: Area2D) -> void:
	var p := _player_from(area)
	if p != null:
		_player = p


func _stop(area: Area2D) -> void:
	if _player_from(area) == _player:
		_player = null
		_hacking = false


func _process(delta: float) -> void:
	if _done or _player == null:
		return
	# Sadece drone formu hackleyebilir
	var can: bool = _player.form != null and _player.form.can_hack
	if not can:
		if not _hacking:
			# "?" yerine "form degistir" — drone'a bürünmen gerektigi ipucu
			Pictogram.show_on(_player, &"swap", 0.9, Vector2(0, -30))
			_hacking = true  # spam onleme — cikana kadar tekrar gosterme
		return
	_hacking = true
	_lamp.color = Color(0.95, 0.8, 0.2) if int(_prog * 8) % 2 == 0 \
		else Color(0.5, 0.5, 0.3)
	_prog += delta
	if _prog >= _tuning.terminal_hack_time:
		_done = true
		_lamp.color = Color(0.3, 1.0, 0.5)
		Pictogram.show_on(_player, &"note", 0.9, Vector2(0, -30))
		AudioManager.play_sfx(&"sfx/ui", global_position, -2.0)
		hacked.emit(gate_id)
