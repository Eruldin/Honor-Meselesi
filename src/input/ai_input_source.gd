class_name AIInputSource
extends InputSource
## Kodla surulen girdi. Bolum 7'de samuray boss olunca bu baglanir;
## testlerde deterministik girdi icin de kullanilir.
##
## Model: disaridan tap()/hold()/release() "staged" alana yazar; sahip
## her fizik frame basinda poll() cagirdiginda staged -> aktif gecer.
## Boylece "just_pressed" tam bir fizik frame'i boyunca gorunur.

var _axis: float = 0.0
var _held: Dictionary = {}
var _staged_jp: Dictionary = {}
var _active_jp: Dictionary = {}
var _staged_jr: Dictionary = {}
var _active_jr: Dictionary = {}


func poll() -> void:
	_active_jp = _staged_jp
	_staged_jp = {}
	_active_jr = _staged_jr
	_staged_jr = {}
	# Basili tutulmayan "just pressed" aksiyonu bir sonraki frame'de
	# "just released" olur — tap() dogal olarak tek frame'lik basimdir.
	for a in _active_jp:
		if not _held.get(a, false):
			_staged_jr[a] = true


## Tek frame'lik basim (zipla, saldir, parry...).
func tap(action: StringName) -> void:
	_staged_jp[action] = true


## Basili tut (hareket tusu, asagi vb.).
func hold(action: StringName) -> void:
	_held[action] = true
	_staged_jp[action] = true


func release(action: StringName) -> void:
	_held.erase(action)
	_staged_jr[action] = true


## Sanal analog cubuk -1..1.
func axis(value: float) -> void:
	_axis = clampf(value, -1.0, 1.0)


func move_axis() -> float:
	return _axis


func down_held() -> bool:
	return _held.get(&"move_down", false)


func jump_just_pressed() -> bool:
	return _active_jp.get(&"jump", false)


func jump_just_released() -> bool:
	return _active_jr.get(&"jump", false)


func jump_held() -> bool:
	return _held.get(&"jump", false)


func attack_just_pressed() -> bool:
	return _active_jp.get(&"attack", false)


func parry_just_pressed() -> bool:
	return _active_jp.get(&"parry", false)


func dash_just_pressed() -> bool:
	return _active_jp.get(&"dash", false)


func form_next_just_pressed() -> bool:
	return _active_jp.get(&"form_next", false)


func form_prev_just_pressed() -> bool:
	return _active_jp.get(&"form_prev", false)
