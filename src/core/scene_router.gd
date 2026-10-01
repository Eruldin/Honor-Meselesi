extends Node
## Sahne gecisleri + kalici karartma katmani.
## change_scene: karart -> sahne degistir -> ac. Bolumlerin olum/respawn
## akislari da fade_to() ile ayni katmani kullanir.

signal scene_loaded(path: String)

## Bolum giris kartlari: sahne degisiminde (olum respawn'i reload() —
## buraya ugramaz) bolum adini buyuk harfle gosterir. HK bolge adi gibi:
## dunya karartmadan acilirken yazi belirip kaybolur.
const _CHAPTER_TITLES := {
	"res://src/levels/ch1/Ch1.tscn": {
		"tr": ["BÖLÜM I", "ÖFKELİ KÖY"], "en": ["CHAPTER I", "ANGRY VILLAGE"]},
	"res://src/levels/ch2/Ch2.tscn": {
		"tr": ["BÖLÜM II", "SİBERPUNK"], "en": ["CHAPTER II", "CYBERPUNK"]},
	"res://src/levels/ch3/Ch3.tscn": {
		"tr": ["BÖLÜM III", "GOTİK MEZARLIK"], "en": ["CHAPTER III", "GOTHIC GRAVEYARD"]},
	"res://src/levels/ch4/Ch4.tscn": {
		"tr": ["BÖLÜM IV", "RETRO PLATFORM"], "en": ["CHAPTER IV", "RETRO PLATFORM"]},
	"res://src/levels/ch5/Ch5.tscn": {
		"tr": ["BÖLÜM V", "KÜL DİYARI"], "en": ["CHAPTER V", "ASH REALM"]},
	"res://src/levels/ch6/Ch6.tscn": {
		"tr": ["BÖLÜM VI", "PARÇALANMIŞ BELLEK"], "en": ["CHAPTER VI", "SHATTERED MEMORY"]},
	"res://src/levels/ch7/Ch7.tscn": {
		"tr": ["BÖLÜM VII", "BOŞLUK"], "en": ["CHAPTER VII", "THE VOID"]},
}

var _is_transitioning := false
var _fade_rect: ColorRect
var _layer: CanvasLayer


func _ready() -> void:
	EventBus.scene_change_requested.connect(change_scene)
	_layer = CanvasLayer.new()
	_layer.layer = 120
	_fade_rect = ColorRect.new()
	_fade_rect.color = Color.BLACK
	_fade_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fade_rect.modulate.a = 0.0
	_layer.add_child(_fade_rect)
	add_child(_layer)


## Karartma alfasini duration'da hedefe tween'ler; bitince doner (await'lenir).
func fade_to(alpha: float, duration: float) -> void:
	if duration <= 0.0:
		_fade_rect.modulate.a = alpha
		return
	var tw := create_tween()
	tw.tween_property(_fade_rect, "modulate:a", alpha, duration)
	await tw.finished


func change_scene(path: String) -> void:
	if _is_transitioning:
		return
	_is_transitioning = true
	await fade_to(1.0, 0.25)
	var err := get_tree().change_scene_to_file(path)
	if err != OK:
		push_error("Scene change failed (%s): %s" % [path, error_string(err)])
		await fade_to(0.0, 0.2)
		_is_transitioning = false
		return
	await get_tree().process_frame
	await get_tree().process_frame
	_show_chapter_title(path)
	await fade_to(0.0, 0.35)
	_is_transitioning = false
	scene_loaded.emit(path)


## Bolum giris karti: "BÖLÜM N" kucuk, isim buyuk; karartmanin ustune
## biner, dunya acilirken belirir, sonra solarak yok olur. Olmusken
## respawn reload() kullandigi icin kart olumde tekrar etmez.
func _show_chapter_title(path: String) -> void:
	var entry: Array = _CHAPTER_TITLES.get(path, {}).get(
		Settings.language, [])
	if entry.is_empty():
		return
	var wrap := CenterContainer.new()
	wrap.set_anchors_preset(Control.PRESET_FULL_RECT)
	wrap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	wrap.modulate.a = 0.0
	var card := VBoxContainer.new()
	card.alignment = BoxContainer.ALIGNMENT_CENTER
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var num := Label.new()
	num.text = entry[0]
	num.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	num.add_theme_font_size_override("font_size", 10)
	num.add_theme_color_override("font_color", Color(0.85, 0.72, 0.5, 0.9))
	card.add_child(num)
	var name_lbl := Label.new()
	name_lbl.text = entry[1]
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.add_theme_font_size_override("font_size", 22)
	name_lbl.add_theme_color_override("font_color", Color(0.95, 0.88, 0.7))
	name_lbl.add_theme_color_override("font_shadow_color", Color(0.3, 0.04, 0.06))
	name_lbl.add_theme_constant_override("shadow_offset_x", 2)
	name_lbl.add_theme_constant_override("shadow_offset_y", 2)
	card.add_child(name_lbl)
	wrap.add_child(card)
	wrap.position.y = -int(wrap.get_viewport_rect().size.y * 0.08)
	_layer.add_child(wrap)
	var tw := create_tween()
	tw.tween_property(wrap, "modulate:a", 1.0, 0.4)
	tw.tween_interval(1.7)
	tw.tween_property(wrap, "modulate:a", 0.0, 0.6)
	tw.tween_callback(wrap.queue_free)


func reload() -> void:
	get_tree().reload_current_scene()
