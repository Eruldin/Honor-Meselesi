class_name CrtGame
extends Node2D
## Prolog'daki CRT icinde gercekten oynanan mini 8-bit oyun (DEVIN_PLAN M3).
## Kucuk kosucu: sagdan gelen bloklarin ustunden zipla. Skor metinsizdir —
## gecilen her engel icin ustte bir isaret karesi yanar.
## glitch_out() cagrilinca goruntu parazite burunur ve `glitched` yayilir.

signal obstacle_dodged(count: int)
signal crashed(hits_left: int)
signal glitched

const VIEW := Vector2i(96, 54)
const GROUND_Y := 44.0
const HERO_X := 18.0
const HERO_SIZE := Vector2(5, 8)

@export var tuning: Tuning

var input: InputSource
var dodged := 0
var over := false

var _hero: ColorRect
var _hero_vel_y := 0.0
var _hero_on_floor := true
var _obstacles: Array[ColorRect] = []
var _spawn_left := 0.0
var _pips: Array[ColorRect] = []
var _hits := 0
var _invuln := 0.0
var _glitching := false
var _static_rect: ColorRect


func _ready() -> void:
	if tuning == null:
		tuning = load("res://config/tuning.tres")
	if input == null:
		input = PlayerInputSource.new()
	add_child(input)
	_build()


func _build() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.02, 0.04, 0.05)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var ground := ColorRect.new()
	ground.color = Color(0.2, 0.55, 0.45)
	ground.position = Vector2(0, GROUND_Y)
	ground.size = Vector2(VIEW.x, 2)
	add_child(ground)

	_hero = ColorRect.new()
	_hero.color = Color(0.95, 0.9, 0.3)
	_hero.size = HERO_SIZE
	_hero.position = Vector2(HERO_X, GROUND_Y - HERO_SIZE.y)
	add_child(_hero)

	# Skor isaretleri — metinsiz pip satiri
	for i in 8:
		var pip := ColorRect.new()
		pip.size = Vector2(4, 2)
		pip.position = Vector2(4 + i * 6, 4)
		pip.color = Color(0.25, 0.25, 0.3)
		add_child(pip)
		_pips.append(pip)

	_static_rect = ColorRect.new()
	_static_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_static_rect.visible = false
	add_child(_static_rect)

	_spawn_left = tuning.crt_spawn_interval


func _physics_process(delta: float) -> void:
	if _glitching:
		return
	input.poll()
	_invuln = maxf(_invuln - delta, 0.0)

	# Ziplama
	if input.jump_just_pressed() and _hero_on_floor:
		_hero_vel_y = -tuning.crt_jump_velocity
		_hero_on_floor = false
	if not _hero_on_floor:
		_hero_vel_y += tuning.crt_gravity * delta
		_hero.position.y += _hero_vel_y * delta
		if _hero.position.y >= GROUND_Y - HERO_SIZE.y:
			_hero.position.y = GROUND_Y - HERO_SIZE.y
			_hero_on_floor = true
			_hero_vel_y = 0.0

	# Engel uretimi
	_spawn_left -= delta
	if _spawn_left <= 0.0:
		_spawn_left = tuning.crt_spawn_interval * randf_range(0.8, 1.25)
		_spawn_obstacle()

	# Engel kayma + carpisma
	var hero_rect := Rect2(_hero.position, _hero.size)
	for ob in _obstacles.duplicate():
		ob.position.x -= tuning.crt_obstacle_speed * delta
		var ob_rect := Rect2(ob.position, ob.size)
		if _invuln <= 0.0 and hero_rect.intersects(ob_rect):
			_on_hit()
		elif ob.position.x + ob.size.x < HERO_X and not ob.get_meta("scored", false):
			ob.set_meta("scored", true)
			_on_dodge()
		if ob.position.x < -20.0:
			_obstacles.erase(ob)
			ob.queue_free()

	# Vurus gorsel geri bildirimi
	_hero.color = Color(1.0, 0.4, 0.3) if _invuln > 0.0 else Color(0.95, 0.9, 0.3)


func _spawn_obstacle() -> void:
	var ob := ColorRect.new()
	var h := randf_range(7.0, 13.0)
	ob.size = Vector2(5, h)
	ob.position = Vector2(VIEW.x + 4.0, GROUND_Y - h)
	ob.color = Color(0.9, 0.3, 0.4)
	add_child(ob)
	_obstacles.append(ob)


func _on_dodge() -> void:
	dodged += 1
	if dodged <= _pips.size():
		_pips[dodged - 1].color = Color(0.4, 0.95, 0.55)
	obstacle_dodged.emit(dodged)


func _on_hit() -> void:
	_hits += 1
	_invuln = 0.9
	crashed.emit(_hits)


## CRT goruntusu parazite doner; kisa sure sonra glitched yayilir.
func glitch_out() -> void:
	if _glitching:
		return
	_glitching = true
	_static_rect.visible = true
	var tw := create_tween()
	tw.set_loops(6)
	tw.tween_callback(func() -> void:
		_static_rect.color = Color(randf(), randf(), randf()).darkened(0.6))
	tw.tween_interval(0.08)
	tw.tween_callback(func() -> void: glitched.emit())


## Testler/kayit icin: engelleri hemen temizleyip oyunu dondurur.
func freeze() -> void:
	_glitching = true
	for ob in _obstacles:
		ob.queue_free()
	_obstacles.clear()
