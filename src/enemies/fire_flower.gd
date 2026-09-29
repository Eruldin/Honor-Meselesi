class_name FireFlower
extends Node2D
## Bolum 4 ates cicegi: borudan cikar, ates topu firlatir, geri cekilir.
## Parry'lenebilir mermi.

var _t := 0.0
var _phase := 0  # 0 gizli, 1 disarida
var _stem: CanvasItem


func _ready() -> void:
	var t: Tuning = load("res://config/tuning.tres")
	_t = t.flower_interval * 0.6
	if AssetLoader.has_asset(&"enemy/flower"):
		var spr := Sprite2D.new()
		spr.texture = AssetLoader.texture(&"enemy/flower")
		var ts := spr.texture.get_size()
		spr.scale = Vector2(14, 18) / ts
		spr.position = Vector2(0, -4)
		spr.visible = false
		add_child(spr)
		_stem = spr
	else:
		var cr := ColorRect.new()
		cr.color = Color(0.9, 0.5, 0.2)
		cr.size = Vector2(8, 16)
		cr.position = Vector2(-4, 0)
		cr.visible = false
		add_child(cr)
		_stem = cr


func _physics_process(delta: float) -> void:
	var t: Tuning = load("res://config/tuning.tres")
	_t -= delta
	match _phase:
		0:
			if _t <= 0.0:
				_phase = 1
				_stem.visible = true
				_t = 0.5
				position.y -= 16
		1:
			if _t <= 0.0:
				_spit()
				_phase = 0
				_t = t.flower_interval
				_stem.visible = false
				position.y += 16


func _spit() -> void:
	var p := Projectile.new()
	p.direction = -1 if randf() < 0.5 else 1
	p.speed = 90.0
	p.global_position = global_position + Vector2(0, -12)
	get_parent().add_child(p)
