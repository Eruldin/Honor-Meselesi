extends Node
## Calisma zamani oyun durumu. SaveSystem bunu save.json'a serilestirir.
## Bolum ilerlemesi, acilan formlar ve serbest flag'ler burada durur.

const SAVE_VERSION := 1
const SOUL_MAX := 12

var current_chapter: StringName = &"prolog"
var current_form: StringName = &"samurai"
var unlocked_forms: Array[StringName] = [&"samurai"]
var checkpoint_id: StringName = &""
var flags: Dictionary = {}
var play_time: float = 0.0
var soul: int = 0
## Kalp kristalleriyle kazanilan kalici +max can (kaydedilir).
var max_health_bonus: int = 0


func _ready() -> void:
	# Ruh sadece oyuncunun VERDIGI hasardan dolar; alinan hasar sayilmaz.
	EventBus.damage_dealt.connect(func(t: Node, _i) -> void:
		if t == null or not t.is_in_group(&"player"):
			gain_soul(1))
	EventBus.parry_succeeded.connect(func(_p) -> void: gain_soul(2))


func gain_soul(n: int) -> void:
	soul = mini(soul + n, SOUL_MAX)


func try_spend_soul(n: int) -> bool:
	if soul < n:
		return false
	soul -= n
	return true


func _process(delta: float) -> void:
	play_time += delta


func unlock_form(form_id: StringName) -> void:
	if unlocked_forms.has(form_id):
		return
	unlocked_forms.append(form_id)
	EventBus.form_unlocked.emit(form_id)


func set_form(form_id: StringName) -> void:
	if form_id == current_form:
		return
	current_form = form_id
	EventBus.form_changed.emit(form_id)


func set_flag(key: StringName, value: Variant = true) -> void:
	flags[key] = value


func get_flag(key: StringName, default: Variant = false) -> Variant:
	return flags.get(key, default)


## respawn_pos flag'i bolumler arasi tasir: RestPoint respawn_ch'i de
## yazar; sadece ayni bolumde gecerli kabul edilir. Yoksa onceki bolumun
## koordinati (or. x=4050) dar bir bolumde dunya disi spawn uretir.
func respawn_point(default_pos: Vector2) -> Vector2:
	var cp: Variant = get_flag(&"respawn_pos", default_pos)
	if cp is Vector2 and get_flag(&"respawn_ch", current_chapter) == current_chapter:
		return cp
	return default_pos


func reset() -> void:
	current_chapter = &"prolog"
	current_form = &"samurai"
	unlocked_forms = [&"samurai"]
	checkpoint_id = &""
	flags.clear()
	play_time = 0.0
	soul = 0
	max_health_bonus = 0


func to_dict() -> Dictionary:
	var ser_flags := {}
	for k in flags:
		var v: Variant = flags[k]
		if v is Vector2:
			ser_flags[k] = {"__v2": [v.x, v.y]}
		else:
			ser_flags[k] = v
	return {
		"version": SAVE_VERSION,
		"chapter": String(current_chapter),
		"current_form": String(current_form),
		"unlocked_forms": unlocked_forms.map(func(f: StringName) -> String: return String(f)),
		"checkpoint": String(checkpoint_id),
		"flags": ser_flags,
		"play_time": play_time,
		"soul": soul,
		"hp_bonus": max_health_bonus,
	}


func from_dict(data: Dictionary) -> void:
	current_chapter = StringName(data.get("chapter", "prolog"))
	current_form = StringName(data.get("current_form", "samurai"))
	checkpoint_id = StringName(data.get("checkpoint", ""))
	play_time = float(data.get("play_time", 0.0))
	soul = int(data.get("soul", 0))
	max_health_bonus = int(data.get("hp_bonus", 0))
	flags.clear()
	for k in data.get("flags", {}):
		var v: Variant = data["flags"][k]
		if v is Dictionary and v.has("__v2"):
			var arr: Array = v["__v2"]
			v = Vector2(float(arr[0]), float(arr[1]))
		flags[k] = v
	unlocked_forms.clear()
	for f in data.get("unlocked_forms", ["samurai"]):
		unlocked_forms.append(StringName(f))
	if unlocked_forms.is_empty():
		unlocked_forms.append(&"samurai")
