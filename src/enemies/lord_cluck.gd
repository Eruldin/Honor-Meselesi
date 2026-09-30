class_name LordCluck
extends BossBase
## Bolum 1 boss'u: dev ofkeli tavuk. Faz 1: yaklas, yer sars (sok dalgasi),
## patlayan yumurta birak. Faz 2 (can <= %50): daha hizli, cift yumurta.
## Yumurtalar kilicla geri yollanir -> boss'a hasar. Olum -> Tavuk formu.

enum State { SLEEP, APPROACH, TELEGRAPH, SLAM_AIR, LAND, LAY, GAP }

var bstate := State.SLEEP
var _t := 0.0
var _player: Node2D
var facing := -1
var _laid_count := 0

var arena_root: Node2D  ## yumurtalar/sok dalgalari buraya eklenir
var _base_scale := Vector2.ONE  ## telegraph kabarmasi buna gore carpilir


func _init() -> void:
	max_hp = 14
	body_size = Vector2(26, 30)
	contact_damage = true
	asset_key = &"rooster"
	phase_thresholds = [0.5]


func _ready() -> void:
	super._ready()
	if anims != null:
		# Dev kasuari-horoz — boss olcegi; ayaklari tam govde dibinde
		anims.scale *= 2.4
		_base_scale = anims.scale
		var fs := anims.sprite_frames.get_frame_texture(anims.animation, 0).get_size()
		anims.position.y = body_size.y * 0.5 - fs.y * anims.scale.y
	elif using_real_sprite:
		sprite.scale *= 2.0
		var vis_h := sprite.texture.get_size().y * sprite.scale.y
		sprite.position.y = body_size.y * 0.5 - vis_h * 0.5
	else:
		sprite.modulate = Color(0.95, 0.85, 0.5)
	contact_hitbox.activate(DamageInfo.make(1, self, Vector2.ZERO, true, true))


func on_activated() -> void:
	bstate = State.APPROACH
	Pictogram.show_on(self, &"anger", 1.2, Vector2(0, -26))


func on_phase_changed(_p: int) -> void:
	sprite.modulate = Color(1.0, 0.5, 0.4)
	if anims != null:
		anims.modulate = Color(1.0, 0.5, 0.4)
	Pictogram.show_on(self, &"anger", 1.0, Vector2(0, -26))
	FX.shake(3.0, 0.4)
	FX.glitch(0.6, 0.5)


func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	if not active or not health.is_alive():
		return
	if _player == null:
		_player = get_tree().get_first_node_in_group(&"player")
		return
	var dx: float = _player.global_position.x - global_position.x
	facing = 1 if dx > 0 else -1
	sprite.flip_h = facing < 0
	_t -= delta
	var speed := tuning.cluck_p2_speed if phase >= 1 else tuning.cluck_speed
	var gap := tuning.cluck_attack_gap_p2 if phase >= 1 else tuning.cluck_attack_gap

	match bstate:
		State.APPROACH:
			velocity.x = facing * speed
			if absf(dx) < 46.0 or _t <= 0.0:
				_choose_attack()
				if bstate == State.APPROACH:
					_t = 0.6
		State.TELEGRAPH:
			velocity.x = 0.0
			_puff_scale(Vector2(1.15, 0.85))  # kabarma = telegraph
			if _t <= 0.0:
				bstate = State.SLAM_AIR
				_puff_scale(Vector2.ONE)
				velocity.y = -tuning.cluck_slam_rise
		State.SLAM_AIR:
			if velocity.y > 0.0:
				velocity.y += tuning.cluck_slam_fall * 2.0 * delta
			if is_on_floor() and velocity.y > -10.0:
				_land_slam()
		State.LAY:
			velocity.x = 0.0
			if _t <= 0.0:
				_lay_egg()
				bstate = State.GAP
				_t = gap
		State.GAP:
			velocity.x = move_toward(velocity.x, 0.0, 600.0 * delta)
			if _t <= 0.0:
				bstate = State.APPROACH
				_t = 2.5  # approach ust siniri


func _choose_attack() -> void:
	# Donusumlu: slam -> lay -> slam (faz 2'de lay cift yumurta atar)
	if _laid_count % 2 == 1:
		bstate = State.TELEGRAPH
		_t = tuning.cluck_telegraph
	else:
		bstate = State.LAY
		_t = 0.35
	_laid_count += 1


func _land_slam() -> void:
	bstate = State.GAP
	_t = tuning.cluck_attack_gap_p2 if phase >= 1 else tuning.cluck_attack_gap
	velocity = Vector2.ZERO
	FX.shake(tuning.shake_heavy, 0.35)
	# Iki yone sok dalgasi
	for dir in [-1, 1]:
		var w := Shockwave.new()
		w.direction = dir
		w.global_position = global_position + Vector2(dir * 14, 8)
		_parent_for(w).add_child(w)


func _lay_egg() -> void:
	var count := 2 if phase >= 1 else 1
	for i in count:
		var egg := ExplodingEgg.new()
		egg.boss = self
		egg.global_position = global_position + Vector2(facing * (10 + i * 14), -8)
		egg.velocity = Vector2(facing * 50.0, -80.0)
		_parent_for(egg).add_child(egg)


func _parent_for(n: Node) -> Node:
	return arena_root if arena_root != null else get_parent()


func _puff_scale(s: Vector2) -> void:
	if anims != null:
		anims.scale = _base_scale * s
	else:
		sprite.scale = s
