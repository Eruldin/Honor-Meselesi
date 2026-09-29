class_name StateMachine
extends Node
## Minimal FSM: durumlar PlayerState nesneleri; physics_process sonraki
## durumu dondurur. force ile ayni duruma yeniden girilebilir (HURT'da
## tekrar vurulma gibi).

var states: Dictionary = {}
var current: PlayerState = null
var current_name: StringName = &""


func register_state(id: StringName, state: PlayerState) -> void:
	states[id] = state


func change_to(id: StringName, force := false) -> void:
	if id == current_name and not force:
		return
	if not states.has(id):
		push_error("Unknown state: %s" % id)
		return
	if current != null:
		current.exit()
	current_name = id
	current = states[id]
	current.enter()


func physics_process(delta: float) -> void:
	if current == null:
		return
	current.t += delta
	var next: StringName = current.physics_process(delta)
	if next != &"":
		change_to(next)
