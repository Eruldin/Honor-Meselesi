class_name Turtle
extends EnemyBase
## Bolum 4 kaplumbaga: vurulunca icine cekilip sekme yapan KABUK olur —
## kabuk duvardan duvardan seker, oyuncuya VE dusmanlara hasar verir.

var _player: Node2D
var shelled := false


func _init() -> void:
	max_hp = 2
	body_size = Vector2(14, 12)
	contact_damage = true


func _ready() -> void:
	asset_key = &"slug"
	super._ready()
	if not using_real_sprite:
		sprite.modulate = Color(0.4, 0.7, 0.4)


func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	if is_staggered() or not health.is_alive() or shelled:
		return
	if _player == null:
		_player = get_tree().get_first_node_in_group(&"player")
		return
	var dx: float = _player.global_position.x - global_position.x
	if absf(dx) < 120.0:
		velocity.x = signf(dx) * 20.0


## Ilk vurus: kabuga donusur ve Shell firlatir.
func take_damage(info: DamageInfo) -> void:
	if shelled:
		return
	shelled = true
	var shell := TurtleShell.new()
	shell.global_position = global_position
	if info.source != null:
		shell.launch_dir = int(signf(global_position.x - info.source.global_position.x))
	get_parent().call_deferred("add_child", shell)
	_on_died()


class TurtleShell:
	extends CharacterBody2D
	## Sekme yapan kabuk: yatay hizla gider, duvardan seker; hem oyuncuya
	## hem dusmanlara dokunan hitbox (maske her ikisi).
	var launch_dir := 1
	var _life := 0.0
	var hitbox: Hitbox
	var _tuning: Tuning

	func _ready() -> void:
		_tuning = load("res://config/tuning.tres")
		collision_layer = 0
		collision_mask = 1
		var col := CollisionShape2D.new()
		var r := RectangleShape2D.new()
		r.size = Vector2(10, 8)
		col.shape = r
		add_child(col)
		var spr := Sprite2D.new()
		spr.texture = AssetLoader.texture(&"enemy/shell", Vector2i(10, 8))
		var ts := spr.texture.get_size()
		if ts.x > 10.0:
			spr.scale = Vector2(12, 10) / ts
		else:
			spr.modulate = Color(0.3, 0.8, 0.3)
		add_child(spr)
		hitbox = Hitbox.new()
		hitbox.collision_layer = 32
		hitbox.collision_mask = 4 | 16  # oyuncu + dusman
		var hc := CollisionShape2D.new()
		var hr := RectangleShape2D.new()
		hr.size = Vector2(12, 10)
		hc.shape = hr
		hitbox.add_child(hc)
		add_child(hitbox)
		hitbox.activate(DamageInfo.make(1, self, Vector2(launch_dir * 80, -40), true, true))

	func _physics_process(delta: float) -> void:
		_life += delta
		if _life > _tuning.shell_life:
			queue_free()
			return
		velocity.y = minf(velocity.y + 800.0 * delta, 320.0)
		velocity.x = launch_dir * _tuning.shell_speed
		move_and_slide()
		if is_on_wall():
			launch_dir = -launch_dir
