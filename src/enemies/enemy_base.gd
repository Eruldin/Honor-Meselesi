class_name EnemyBase
extends CharacterBody2D
## Tum dusmanlarin tabani: Health + Hurtbox + placeholder sprite +
## sersemletme (parry sonrasi). Bolum 4.4'teki "telegraph zorunlu"
## kurali gercek saldirilar eklenince uygulanir.

@export var max_hp: int = 3
@export var body_size: Vector2 = Vector2(14, 16)
## Devamli temas hasari veriyorsa true (diken haric; diken kendi sinif).
@export var contact_damage: bool = false
## Manifest'te "enemy/<asset_key>" olan gercek sprite kullanilir; yoksa
## renkli placeholder'a dusulur.
var asset_key: StringName = &""

var tuning: Tuning
var health: Health
var hurtbox: Hurtbox
var sprite: Sprite2D
var anims: AnimatedSprite2D          ## enemy/<key>/<durum> sheet'leri varsa
var contact_hitbox: Hitbox
var stagger_timer: float = 0.0
## Base'in kurdugu temas hitbox'i icin saklanan hasar bilgisi —
## sersemleme bitince ayni payload ile yeniden kurulur.
var _contact_info: DamageInfo
var _contact_managed := false
## Vurus geri tepmesi direnci: 0 = tam tepme, 1 = yerinden kipirdamaz (agir dusmanlar).
@export var knockback_resist: float = 0.0
var using_real_sprite := false
var _anim_lock := 0.0                ## attack/hurt/die oynarken otomatik animi durdurur
var _flash_timer: float = 0.0
var _kb_vel := Vector2.ZERO          ## vurus geri tepmesi — pozisyon itkisi


func _ready() -> void:
	tuning = load("res://config/tuning.tres")
	collision_layer = 64
	collision_mask = 1
	add_to_group(&"enemies")

	var col := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = body_size
	col.shape = rect
	add_child(col)

	sprite = Sprite2D.new()
	if asset_key != &"" and AssetLoader.has_asset(&"enemy/" + String(asset_key)):
		sprite.texture = AssetLoader.texture(&"enemy/" + String(asset_key))
		using_real_sprite = true
		# Sprite'i govde boyutuna gore kucult (atlasmaz destekli).
		var ts := sprite.texture.get_size()
		if ts.x > 0.0 and ts.y > 0.0:
			sprite.scale = (body_size * 1.6) / ts
	else:
		sprite.texture = AssetLoader.placeholder_texture("enemy/%s" % name, Vector2i(body_size))
	add_child(sprite)
	_build_anims()

	health = Health.new()
	health.max_health = max_hp
	add_child(health)
	health.died.connect(_on_died)

	hurtbox = Hurtbox.new()
	hurtbox.collision_layer = 16
	hurtbox.collision_mask = 8  # player hitbox
	var hb_col := CollisionShape2D.new()
	var hb_rect := RectangleShape2D.new()
	hb_rect.size = body_size + Vector2(2, 2)
	hb_col.shape = hb_rect
	hurtbox.add_child(hb_col)
	add_child(hurtbox)

	if contact_damage:
		contact_hitbox = Hitbox.new()
		contact_hitbox.collision_layer = 32
		contact_hitbox.collision_mask = 4
		var ch_col := CollisionShape2D.new()
		var ch_rect := RectangleShape2D.new()
		ch_rect.size = body_size + Vector2(4, 4)
		ch_col.shape = ch_rect
		contact_hitbox.add_child(ch_col)
		add_child(contact_hitbox)
		_contact_info = DamageInfo.make(1, self, Vector2.ZERO, true, true)
		contact_hitbox.activate(_contact_info)
		_contact_managed = true


func _physics_process(delta: float) -> void:
	stagger_timer = maxf(stagger_timer - delta, 0.0)
	# Sersemlemis temas dusmani dokunusla hasar veremez — parry/sersemletme
	# guvenli ceza penceresi acar. Sadece base'in kurdugu hitbox yonetilir
	# (Guard lunge hitbox'i kendi kontrol eder).
	if _contact_managed and contact_hitbox != null:
		if is_staggered() and contact_hitbox.monitoring:
			contact_hitbox.deactivate()
		elif not is_staggered() and not contact_hitbox.monitoring \
				and health.is_alive():
			contact_hitbox.activate(_contact_info)
	velocity.y = minf(velocity.y + 800.0 * delta, 320.0)
	move_and_slide()


## enemy/<key>/<idle|walk|attack|hurt|die|sleep|wake> manifest girdilerinden
## animasyon bankasi kurar; hicbiri yoksa statik sprite kalir.
func _build_anims() -> void:
	if asset_key == &"":
		return
	var bank := SpriteFrames.new()
	var first_anim := StringName()
	for anim in [&"idle", &"walk", &"attack", &"hurt", &"die",
			&"summon", &"appear", &"rise", &"sleep", &"wake", &"jump"]:
		var id := StringName("enemy/%s/%s" % [asset_key, anim])
		if not AssetLoader.has_frames(id):
			continue
		var src := AssetLoader.frames(id)
		if src == null or src.get_frame_count(&"default") == 0:
			continue
		bank.add_animation(anim)
		bank.set_animation_speed(anim, src.get_animation_speed(&"default"))
		bank.set_animation_loop(anim,
			anim in [&"idle", &"walk", &"sleep"])
		for i in src.get_frame_count(&"default"):
			bank.add_frame(anim, src.get_frame_texture(&"default", i))
		if first_anim.is_empty():
			first_anim = anim
	if first_anim.is_empty():
		return
	if not bank.has_animation(&"idle"):
		bank.add_animation(&"idle")
		bank.add_frame(&"idle", bank.get_frame_texture(first_anim, 0))
	anims = AnimatedSprite2D.new()
	anims.sprite_frames = bank
	var ftex := bank.get_frame_texture(first_anim, 0)
	var fs := ftex.get_size()
	if fs.x > 0.0 and fs.y > 0.0:
		anims.scale = (body_size * 1.8) / fs
	anims.position.y = -body_size.y * 0.4   # ayak hizasi
	sprite.visible = false
	using_real_sprite = true
	add_child(anims)
	anims.play(&"idle")


## Tek seferlik animasyon (attack/hurt); otomatik idle/walk'i kilitler.
func play_anim(anim: StringName, lock_sec := 0.4) -> void:
	if anims == null or not anims.sprite_frames.has_animation(anim):
		return
	_anim_lock = lock_sec
	anims.play(anim)


func _process(delta: float) -> void:
	# vurus geri tepmesi: altsinif hareketinden bagimsiz pozisyon itkisi
	if _kb_vel.length() > 0.5:
		position += _kb_vel * delta
		_kb_vel = _kb_vel.move_toward(Vector2.ZERO, 900.0 * delta)
	_anim_lock = maxf(_anim_lock - delta, 0.0)
	if anims != null and _anim_lock <= 0.0 and health != null and health.is_alive():
		var want := &"walk" if absf(velocity.x) > 4.0 else &"idle"
		if anims.sprite_frames.has_animation(want) and anims.animation != want:
			anims.play(want)
		anims.flip_h = sprite.flip_h
	if _flash_timer > 0.0:
		_flash_timer -= delta
		if _flash_timer <= 0.0:
			sprite.modulate = Color.WHITE
			if anims != null:
				anims.modulate = Color.WHITE


func is_staggered() -> bool:
	return stagger_timer > 0.0


func take_damage(info: DamageInfo) -> void:
	if not health.is_alive():
		return
	health.take(info.damage)
	sprite.modulate = Color(2.0, 2.0, 2.0)
	if anims != null:
		anims.modulate = Color(2.0, 2.0, 2.0)
		play_anim(&"hurt", 0.25)
	_flash_timer = 0.08
	_kb_vel += info.knockback * 0.6 * (1.0 - knockback_resist)
	# Zirhli dusmanlar (knockback_resist yuksek) vurusa kesintisiz devam
	# eder; hafif dusmanlar kisa sersemler — vurmak hissedilir olsun.
	stagger_timer = maxf(stagger_timer,
		tuning.hit_stagger * (1.0 - knockback_resist))
	EventBus.damage_dealt.emit(self, info)


func on_parried() -> void:
	stagger_timer = tuning.parry_stagger
	sprite.modulate = Color(1.0, 0.9, 0.3)
	if anims != null:
		anims.modulate = Color(1.0, 0.9, 0.3)
	_flash_timer = stagger_timer


func _on_died() -> void:
	EventBus.actor_died.emit(self)
	AudioManager.play_sfx(&"sfx/death_squish" if randf() < 0.5 else &"sfx/slime_death",
		global_position, -6.0, randf_range(0.92, 1.08))
	_death_debris()
	# Olu beden artik zarar vermez/vurulamaz — solma suresince hayalet
	# temas hasari ve lutfen pogo yok.
	if contact_hitbox != null:
		contact_hitbox.deactivate()
	hurtbox.set_deferred(&"monitoring", false)
	if anims != null and anims.sprite_frames.has_animation(&"die"):
		_anim_lock = 10.0
		anims.play(&"die")
		# animasyon bitsin sonra solar
		var tw := create_tween()
		tw.tween_interval(maxi(anims.sprite_frames.get_frame_count(&"die"), 1)
			/ maxf(anims.sprite_frames.get_animation_speed(&"die"), 1.0))
		tw.tween_property(anims, "modulate:a", 0.0, 0.3)
		tw.finished.connect(queue_free)
	else:
		var tw := create_tween()
		var target: CanvasItem = anims if anims != null else sprite
		tw.tween_property(target, "modulate:a", 0.0, 0.3)
		tw.finished.connect(queue_free)


## Olumde kucuk parcacik patlamasi — vucut renklerinden 4 kare sacilir.
func _death_debris() -> void:
	var col := Color(0.9, 0.85, 0.7)
	if anims != null:
		col = anims.modulate
	elif sprite != null:
		col = sprite.modulate
	var parent := get_parent()
	if parent == null:
		return
	for i in 4:
		var d := ColorRect.new()
		d.size = Vector2(3, 3)
		d.color = col.lightened(0.25)
		d.position = global_position + Vector2(-2, -8)
		parent.add_child(d)
		var dir := Vector2(randf_range(-1.0, 1.0), randf_range(-1.4, -0.5))
		var tw := d.create_tween()
		tw.tween_property(d, "position",
			d.position + dir * randf_range(9.0, 16.0), 0.28)
		tw.parallel().tween_property(d, "modulate:a", 0.0, 0.34)
		tw.finished.connect(d.queue_free)
