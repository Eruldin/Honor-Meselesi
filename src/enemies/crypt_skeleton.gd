class_name CryptSkeleton
extends EnemyBase
## Bolum 1 mahzen iskeleti: gomulu baslar; oyuncu yaklasinca yerden
## yukselir (rise animasyonu), sonra devriye gezer. Temas hasari.

@export var patrol_range := 60.0
@export var rise_range := 70.0

var _risen := false
var _rising := false
var _home_x: float
var _dir := 1.0
var _player: Node2D


func _init() -> void:
	max_hp = 2
	body_size = Vector2(12, 18)
	asset_key = &"skeleton"
	contact_damage = true


func _ready() -> void:
	super._ready()
	_home_x = position.x
	# Rise animasyonu _build_anims bankasina girer; eski manifestlerde yoksa
	# elle eklenir.
	if anims != null and not anims.sprite_frames.has_animation(&"rise") \
			and AssetLoader.has_frames(&"enemy/skeleton/rise"):
		var src := AssetLoader.frames(&"enemy/skeleton/rise")
		if src != null and src.get_frame_count(&"default") > 0:
			anims.sprite_frames.add_animation(&"rise")
			anims.sprite_frames.set_animation_speed(&"rise",
				src.get_animation_speed(&"default"))
			anims.sprite_frames.set_animation_loop(&"rise", false)
			for i in src.get_frame_count(&"default"):
				anims.sprite_frames.add_frame(&"rise",
					src.get_frame_texture(&"default", i))
	# Gomulu: gorunmez, zararsiz, dokunulmaz
	visible = false
	if hurtbox != null:
		hurtbox.set_deferred("monitoring", false)
		hurtbox.set_deferred("monitorable", false)
	if contact_hitbox != null:
		contact_hitbox.set_deferred("monitoring", false)


func _physics_process(delta: float) -> void:
	if not _risen:
		if _rising:
			return
		if _player == null:
			_player = get_tree().get_first_node_in_group(&"player")
			return
		if absf(_player.global_position.x - global_position.x) < rise_range \
				and absf(_player.global_position.y - global_position.y) < 40.0:
			_rise()
		return
	super._physics_process(delta)
	if is_staggered() or not health.is_alive():
		return
	# Devriye: ev konumundan patrol_range kadar saga-sola
	velocity.x = _dir * tuning.villager_speed * 0.7
	if position.x > _home_x + patrol_range:
		_dir = -1.0
	elif position.x < _home_x - patrol_range:
		_dir = 1.0
	if _player != null:
		sprite.flip_h = _player.global_position.x < global_position.x


func _rise() -> void:
	_rising = true
	visible = true
	_anim_lock = 0.6   # yukselis sirasinda otomatik anim degismesin
	if anims != null and anims.sprite_frames.has_animation(&"rise"):
		anims.play(&"rise")
		await anims.animation_finished
	else:
		# gercek kareler yoksa yerden hafif yukselme efekti
		var tw := create_tween()
		tw.tween_property(self, "position:y", position.y - 6.0, 0.35)
		await tw.finished
	if not health.is_alive():
		return
	_risen = true
	_rising = false
	if hurtbox != null:
		hurtbox.monitoring = true
		hurtbox.monitorable = true
	if contact_hitbox != null:
		contact_hitbox.monitoring = true
