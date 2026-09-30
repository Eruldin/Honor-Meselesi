class_name BossIntro
extends RefCounted
## HK tarzi kisa boss girisi: ofke isareti + kabarma puls'u + hurlama.
## Bolum bunu caldiktan sonra ~1.1sn bekleyip boss.activate() cagirir.


static func play(boss: EnemyBase) -> void:
	if not is_instance_valid(boss):
		return
	Pictogram.show_on(boss, &"anger", 1.3, Vector2(0, -30))
	var s: Node2D = boss.anims if boss.anims != null else boss.sprite
	if s != null:
		var base: Vector2 = s.scale
		var tw := s.create_tween()
		tw.tween_property(s, "scale", base * 1.28, 0.35).set_trans(Tween.TRANS_BACK)
		tw.tween_property(s, "scale", base, 0.25)
	AudioManager.play_sfx(&"sfx/npc_grunt_3", boss.global_position)
