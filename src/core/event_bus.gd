extends Node
## Global sinyal merkezi. Sistemleri birbirinden ayirir:
## hit-stop, ekran sarsintisi, parry kivilcimi, checkpoint, form degisimi vb.

signal hitstop_requested(duration: float)
signal screenshake_requested(strength: float, duration: float)
signal spark_emitted(position: Vector2)
signal glitch_requested(strength: float, duration: float)

signal damage_dealt(target: Node, info)
signal actor_died(actor: Node)
signal parry_succeeded(position: Vector2)
signal parry_whiffed(actor: Node)

signal checkpoint_reached(id: StringName)
signal form_unlocked(form_id: StringName)
signal form_changed(form_id: StringName)

signal scene_change_requested(path: String)
signal cutscene_started(id: StringName)
signal cutscene_finished(id: StringName)

## SaveSystem basarili kayit sonrasi — HUD kucuk kayit isareti yakip soner.
signal game_saved
