class_name MusicDirector
extends Node
## M10: sakin/savas muzik katmani — yakin canli dusman varken bolum
## muzigi combat temaya crossfade eder; tehdit gecince calm'a doner.
## Sadece AudioManager._current_music == calm_track iken devreye girer:
## boss/dinlenme/galip parcalari chapter'in elindedir, director karismaz.

var player: Node2D
var calm_track: StringName
var combat_track := &"music/combat"
var engage_range := 150.0    ## bu menzilde canli dusman -> savas
var leave_range := 215.0     ## histeresis: ayrilis daha genis
var leave_delay := 2.5       ## tehdit bitince beklenen sakinlik suresi

var _t := 0.0
var _clear_t := 0.0
var _combat := false


func _process(delta: float) -> void:
	if player == null or not is_instance_valid(player):
		return
	_t -= delta
	if _t > 0.0:
		return
	_t = 0.35
	var threat := _nearest_enemy_dist()
	if not _combat:
		if threat < engage_range \
				and AudioManager._current_music == calm_track:
			_combat = true
			AudioManager.play_music(combat_track)
		_clear_t = 0.0
	else:
		if threat < leave_range:
			_clear_t = 0.0
		else:
			_clear_t += 0.35
			if _clear_t >= leave_delay:
				_combat = false
				# Director yalniz kendi caldigi parcayi geri alir;
				# bu arada baska bir parca basladiysa (boss vs) dokunmaz.
				if AudioManager._current_music == combat_track:
					AudioManager.play_music(calm_track)


func _nearest_enemy_dist() -> float:
	var best := INF
	for e in get_tree().get_nodes_in_group(&"enemies"):
		var n := e as Node2D
		if n == null:
			continue
		var h: Variant = n.get("health")
		if h != null and h.has_method("is_alive") and not h.is_alive():
			continue
		best = minf(best, n.global_position.distance_to(player.global_position))
	return best
