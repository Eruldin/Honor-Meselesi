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


static func make(actor: Node2D, with_soul := true) -> HudPlayer:
	var h := HudPlayer.new()
	h._actor = actor
	h._with_soul = with_soul
	h.set_anchors_preset(Control.PRESET_FULL_RECT)
	h.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return h


func _ready() -> void:
	if _actor == null:
		return
	_use_ref = AssetLoader.has_asset(&"ui/hud_heart")
	if _use_ref and AssetLoader.has_asset(&"ui/hud_portrait"):
		var pr := TextureRect.new()
		pr.texture = AssetLoader.texture(&"ui/hud_portrait")
		pr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		pr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT
		pr.position = Vector2(4, 4)
		pr.size = Vector2(19, 19)
		add_child(pr)

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
		add_child(ht)
		_hearts.append(ht)
		hx += 11.0


func _process(_delta: float) -> void:
	if _actor == null or not is_instance_valid(_actor):
		return
	if _use_ref and _hearts.size() != _actor.health.max_health:
		_build_hearts()   # kalp kristali: sahnede max can artti
	for i in _hearts.size():
		_hearts[i].modulate = Color(1.25, 1.15, 1.1, 1.0) \
			if i < _actor.health.current \
			else Color(0.5, 0.42, 0.48, 0.55)
	if _soul_bar != null:
		var f := float(GameState.soul) / GameState.SOUL_MAX
		_soul_bar.modulate = Color(1.0 + f * 0.6, 1.0 + f * 0.4,
			1.0 + f * 0.2, 0.35 + f * 0.65)
		# Ilk focus'a kadar ipucu: ruh bir iyilesmeye yetiyorsa bar nabiz atar
		if GameState.soul >= 6 and not GameState.get_flag(&"focus_used", false):
			var pulse := 0.5 + 0.5 * sin(Time.get_ticks_msec() / 180.0)
			_soul_bar.modulate.a = 0.45 + 0.55 * pulse
	if _fill != null:
		_fill.size.x = 110.0 * float(_actor.health.current) \
			/ maxf(_actor.health.max_health, 1)

