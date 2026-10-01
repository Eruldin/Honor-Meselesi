class_name HudPlayer
extends Control
## HK-vari oyuncu HUD'i: portre + oni-maske kalpler + katana ruh olceri.
## Butun bolumlerde ayni; actor.health'i takip eder, ruh cubugu
## GameState.soul'u gosterir (vurus/parry ile dolar, focus ile harcanir).
## ui/* asset'leri yoksa cerceveli yedek bara duser.

var _actor: Node2D
var _with_soul := true
var _hearts: Array[TextureRect] = []
var _soul_bar: TextureRect
var _fill: Control
var _use_ref := false
var _form_badge: ColorRect
var _form_icon: TextureRect
var _form_time: ColorRect
var _form_id: StringName = &"samurai"
var _soul_notch: ColorRect
var _save_mark: Control
var _save_tw: Tween


class SaveMark:
	## Kaydedildi isareti — kucuk disket glifi; autosave'de kisa parlar.
	extends Control

	func _draw() -> void:
		var c := Color(0.75, 0.72, 0.55)
		var d := Color(0.14, 0.12, 0.18)
		draw_rect(Rect2(0, 0, 9, 9), c)
		draw_rect(Rect2(2, 0, 5, 3), d)
		draw_rect(Rect2(2, 5, 5, 3), d)
		draw_rect(Rect2(3, 6, 3, 1), c)


var _portrait_id: StringName = &"ui/hud_portrait"


static func make(actor: Node2D, with_soul := true,
		portrait_id: StringName = &"ui/hud_portrait") -> HudPlayer:
	var h := HudPlayer.new()
	h._actor = actor
	h._with_soul = with_soul
	h._portrait_id = portrait_id
	h.set_anchors_preset(Control.PRESET_FULL_RECT)
	h.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return h


func _ready() -> void:
	if _actor == null:
		return
	_use_ref = AssetLoader.has_asset(&"ui/hud_heart")
	if _use_ref and AssetLoader.has_asset(_portrait_id):
		var pr := TextureRect.new()
		pr.texture = AssetLoader.texture(_portrait_id, Vector2i(19, 19))
		pr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		pr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT
		pr.position = Vector2(4, 4)
		pr.size = Vector2(19, 19)
		add_child(pr)

	# Aktif form rozeti — portrenin altinda kucuk ikon; samurayda gizli.
	_form_badge = ColorRect.new()
	_form_badge.color = Color(0.08, 0.08, 0.1, 0.65)
	_form_badge.position = Vector2(4, 25)
	_form_badge.size = Vector2(13, 13)
	_form_badge.visible = false
	add_child(_form_badge)
	_form_icon = TextureRect.new()
	_form_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_form_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_form_icon.position = Vector2(1, 1)
	_form_icon.size = Vector2(11, 11)
	_form_badge.add_child(_form_icon)
	# Gecici form suresi — rozetin dibinde incelik cubuk
	_form_time = ColorRect.new()
	_form_time.color = Color(0.35, 0.8, 0.95, 0.9)
	_form_time.position = Vector2(0, 11.5)
	_form_time.size = Vector2(13, 1.5)
	_form_time.visible = false
	_form_badge.add_child(_form_time)

	if _use_ref:
		_build_hearts()
		if _with_soul and AssetLoader.has_asset(&"ui/hud_katana"):
			var kb := TextureRect.new()
			kb.texture = AssetLoader.texture(&"ui/hud_katana")
			kb.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			kb.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			kb.position = Vector2(27, 17)
			kb.size = Vector2(56, 9)
			kb.modulate = Color(1, 1, 1, 0.35)
			add_child(kb)
			_soul_bar = kb
			# Focus esigi: 6/12 ruh — katananin ortasinda ince centik
			var notch := ColorRect.new()
			notch.size = Vector2(1, 7)
			notch.position = Vector2(27 + 28.0, 17.5)
			notch.color = Color(0.5, 0.95, 1.0, 0.35)
			add_child(notch)
			_soul_notch = notch
	else:
		var pb := HudBars.make(110, 10, Color(0.8, 0.25, 0.3))
		pb.root.position = Vector2(8, 6)
		add_child(pb.root)
		_fill = pb.fill
		if AssetLoader.has_asset(&"ui/bar_frame"):
			var fr := TextureRect.new()
			fr.texture = AssetLoader.texture(&"ui/bar_frame")
			fr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			fr.stretch_mode = TextureRect.STRETCH_SCALE
			fr.size = Vector2(110, 10)
			pb.root.add_child(fr)

	# Kaydedildi isareti — sag ustte kisa parlar (autosave geri bildirimi)
	_save_mark = SaveMark.new()
	_save_mark.position = Vector2(466, 6)
	_save_mark.size = Vector2(9, 9)
	_save_mark.modulate.a = 0.0
	add_child(_save_mark)
	EventBus.game_saved.connect(_on_saved)


func _on_saved() -> void:
	if _save_mark == null:
		return
	if _save_tw != null and _save_tw.is_running():
		_save_tw.kill()
	_save_mark.modulate.a = 0.9
	_save_tw = create_tween()
	_save_tw.tween_interval(1.0)
	_save_tw.tween_property(_save_mark, "modulate:a", 0.0, 0.5)


## Aktif form rozeti: samuray disi formlarda form sprite'ini gosterir.
func _update_form_badge() -> void:
	if _form_badge == null:
		return
	var form: FormData = _actor.form if _actor is Samurai else null
	var fid: StringName = form.id if form != null else &"samurai"
	if fid == &"samurai" or fid == &"":
		_form_badge.visible = false
		_form_id = &"samurai"
		return
	_form_badge.visible = true
	if fid != _form_id:
		_form_id = fid
		var tex_id := form.sprite_asset
		if tex_id == &"":
			tex_id = &"player/%s/idle" % fid
		_form_icon.texture = AssetLoader.texture(tex_id, Vector2i(11, 11))
		_form_icon.modulate = form.sprite_color
	if form.duration > 0.0:
		_form_time.visible = true
		_form_time.size.x = 13.0 * clampf(
			_actor.form_time_left / form.duration, 0.0, 1.0)
	else:
		_form_time.visible = false


func _build_hearts() -> void:
	for h in _hearts:
		h.queue_free()
	_hearts.clear()
	var hx := 27.0
	for i in _actor.health.max_health:
		var ht := TextureRect.new()
		ht.texture = AssetLoader.texture(&"ui/hud_heart")
		ht.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		ht.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT
		ht.position = Vector2(hx, 6)
		ht.size = Vector2(9, 9)
		ht.pivot_offset = Vector2(4.5, 4.5)
		add_child(ht)
		_hearts.append(ht)
		hx += 11.0


func _process(_delta: float) -> void:
	if _actor == null or not is_instance_valid(_actor):
		return
	_update_form_badge()
	if _use_ref and _hearts.size() != _actor.health.max_health:
		_build_hearts()   # kalp kristali: sahnede max can artti
	for i in _hearts.size():
		_hearts[i].modulate = Color(1.25, 1.15, 1.1, 1.0) \
			if i < _actor.health.current \
			else Color(0.5, 0.42, 0.48, 0.55)
		_hearts[i].scale = Vector2.ONE
	# Kritik can: son kalp kipkirmizi nabiz atar — kelimesiz uyari
	if _actor.health.current == 1 and not _hearts.is_empty():
		var pulse := 0.5 + 0.5 * sin(Time.get_ticks_msec() / 140.0)
		_hearts[0].modulate = Color(1.3 + pulse * 0.4, 0.55, 0.5, 1.0)
		_hearts[0].scale = Vector2.ONE * (1.0 + pulse * 0.3)
	if _soul_bar != null:
		var f := float(GameState.soul) / GameState.SOUL_MAX
		_soul_bar.modulate = Color(1.0 + f * 0.6, 1.0 + f * 0.4,
			1.0 + f * 0.2, 0.35 + f * 0.65)
		# Ilk focus'a kadar ipucu: ruh bir iyilesmeye yetiyorsa bar nabiz atar
		if GameState.soul >= 6 and not GameState.get_flag(&"focus_used", false):
			var pulse := 0.5 + 0.5 * sin(Time.get_ticks_msec() / 180.0)
			_soul_bar.modulate.a = 0.45 + 0.55 * pulse
		if _soul_notch != null:
			_soul_notch.color.a = 0.85 if GameState.soul >= 6 else 0.3
	if _fill != null:
		_fill.size.x = 110.0 * float(_actor.health.current) \
			/ maxf(_actor.health.max_health, 1)

