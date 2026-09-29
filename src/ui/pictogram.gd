class_name Pictogram
extends Node2D
## Metinsiz anlatim balonu (DEVIN_PLAN §2: dilsiz anlatim). Aktorun basi
## ustunde belirir, primitif sekillerle cizilen ikon gosterir, solarak yok olur.
##
## Kullanim: Pictogram.show_on(node, &"alarm", 1.2)

const BUBBLE_SIZE := Vector2(20, 16)
const ICONS: Array[StringName] = [
	&"alarm", &"question", &"hat", &"sword", &"anger", &"note", &"sleep", &"dots",
	&"jump", &"move", &"mouse", &"shield", &"down", &"arrow_right",
]

var icon: StringName = &"alarm"
var hold_time: float = 1.4


## Aktor (ya da herhangi bir Node2D) ustunde balon gosterir.
static func show_on(host: Node2D, icon_id: StringName,
		dur: float = 1.4, offset := Vector2(0, -32)) -> Pictogram:
	var p := Pictogram.new()
	p.icon = icon_id
	p.hold_time = dur
	p.position = offset
	host.add_child(p)
	return p


func _ready() -> void:
	scale = Vector2.ZERO
	var tw := create_tween()
	tw.set_ignore_time_scale(true)
	tw.tween_property(self, "scale", Vector2.ONE, 0.15).set_trans(Tween.TRANS_BACK)
	tw.tween_interval(hold_time)
	tw.tween_property(self, "modulate:a", 0.0, 0.25)
	tw.finished.connect(queue_free)


func _draw() -> void:
	var half := BUBBLE_SIZE / 2.0
	# Kuyruk (asagi konusan ucgen)
	draw_colored_polygon(
		PackedVector2Array([Vector2(-3, half.y - 2), Vector2(3, half.y - 2), Vector2(0, half.y + 6)]),
		Color(0.95, 0.95, 0.95))
	# Balon govdesi
	draw_rect(Rect2(-half, BUBBLE_SIZE), Color(0.12, 0.12, 0.14))
	draw_rect(Rect2(-half + Vector2.ONE, BUBBLE_SIZE - Vector2(2, 2)),
		Color(0.95, 0.95, 0.95))
	_draw_icon()


func _draw_icon() -> void:
	var c := Color(0.12, 0.12, 0.14)
	match icon:
		&"alarm":  # !
			draw_line(Vector2(0, -5), Vector2(0, 0), c, 2.0)
			draw_circle(Vector2(0, 4), 1.4, c)
		&"question":  # ?
			draw_arc(Vector2(0, -2), 3.5, -PI * 0.9, PI * 0.6, 8, c, 1.6)
			draw_line(Vector2(2.4, 1.0), Vector2(0.5, 2.6), c, 1.6)
			draw_circle(Vector2(0, 5), 1.2, c)
		&"hat":  # hasir sapka (senaryo: calinan sapka)
			draw_line(Vector2(-6, 3), Vector2(6, 3), c, 2.0)
			draw_colored_polygon(PackedVector2Array([
				Vector2(-3.5, 3), Vector2(0, -4.5), Vector2(3.5, 3)]), c)
		&"sword":  # capraz katana
			draw_line(Vector2(-5, 5), Vector2(5, -5), c, 1.8)
			draw_line(Vector2(-3.5, 0.5), Vector2(-0.5, 3.5), c, 1.6)
		&"anger":  # kirmizi hiz cizgileri
			var r := Color(0.85, 0.2, 0.25)
			draw_line(Vector2(-4, -4), Vector2(-1, -1), r, 1.8)
			draw_line(Vector2(4, -4), Vector2(1, -1), r, 1.8)
			draw_line(Vector2(-4, 4), Vector2(-1, 1), r, 1.8)
			draw_line(Vector2(4, 4), Vector2(1, 1), r, 1.8)
		&"note":  # muzik notasi
			draw_circle(Vector2(-2, 3), 2.2, c)
			draw_line(Vector2(0, 3), Vector2(0, -5), c, 1.6)
			draw_line(Vector2(0, -5), Vector2(3.5, -3), c, 1.6)
		&"sleep":  # Z
			draw_polyline(PackedVector2Array([
				Vector2(-3, -4), Vector2(3, -4), Vector2(-3, 2), Vector2(3, 2)]), c, 1.6)
		&"dots":  # dusunce
			for i in 3:
				draw_circle(Vector2(-5 + i * 5, 0), 1.4, c)
		&"jump":  # cift ok yukari (piksel sicramasi)
			draw_polyline(PackedVector2Array([
				Vector2(-4, -1), Vector2(0, -5), Vector2(4, -1)]), c, 1.8)
			draw_polyline(PackedVector2Array([
				Vector2(-4, 4), Vector2(0, 0), Vector2(4, 4)]), c, 1.8)
		&"move":  # cift yonlu yatay ok (AD / ok tuslari)
			draw_line(Vector2(-7, 0), Vector2(7, 0), c, 1.8)
			draw_polyline(PackedVector2Array([
				Vector2(-4, -3), Vector2(-7, 0), Vector2(-4, 3)]), c, 1.8)
			draw_polyline(PackedVector2Array([
				Vector2(4, -3), Vector2(7, 0), Vector2(4, 3)]), c, 1.8)
		&"mouse":  # fare + sol tus vurgusu (saldiri)
			draw_rect(Rect2(Vector2(-4, -6), Vector2(8, 12)), c, false, 1.6)
			draw_line(Vector2(-4, -2), Vector2(4, -2), c, 1.4)
			draw_line(Vector2(0, -6), Vector2(0, -2), c, 1.4)
			draw_rect(Rect2(Vector2(-3, -5), Vector2(3, 3)), c)
		&"shield":  # kalkan — parry
			draw_colored_polygon(PackedVector2Array([
				Vector2(-5, -5), Vector2(5, -5), Vector2(5, 1),
				Vector2(0, 6), Vector2(-5, 1)]), c)
			draw_rect(Rect2(Vector2(-2.5, -3), Vector2(5, 4)),
				Color(0.95, 0.95, 0.95))
		&"arrow_right":  # saga ok — yon gosterme
			draw_line(Vector2(-6, 0), Vector2(5, 0), c, 1.8)
			draw_polyline(PackedVector2Array([
				Vector2(1, -4), Vector2(6, 0), Vector2(1, 4)]), c, 1.8)
		&"down":  # asagi kilic + ok (pogo)
			draw_line(Vector2(-3, -5), Vector2(-3, 2), c, 1.8)
			draw_polyline(PackedVector2Array([
				Vector2(-5.5, 0), Vector2(-3, 3), Vector2(-0.5, 0)]), c, 1.8)
			draw_polyline(PackedVector2Array([
				Vector2(1, 0), Vector2(4, 4), Vector2(7, 0)]), c, 1.8)
			draw_line(Vector2(4, -4), Vector2(4, 4), c, 1.6)
