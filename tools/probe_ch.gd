extends Node2D
## Genel bolum probe'u: --probe=chN --spot=<0..1> ile seviye ortasina icer.
## Ornek: --path . tools/ProbeCh.tscn --probe=ch3 --spot=0.5

var _scene
var _cleared := false
var _rest := false


func _ready() -> void:
	var ch := "ch3"
	var spot := 0.5
	var death := false
	var cleared := false
	for a in OS.get_cmdline_args() + OS.get_cmdline_user_args():
		if a.begins_with("--probe="):
			ch = a.get_slice("=", 1)
		if a.begins_with("--spot="):
			spot = float(a.get_slice("=", 1))
		if a == "--death":
			death = true
		if a == "--cleared":
			cleared = true
		if a == "--rest":
			_rest = true
	_cleared = cleared
	var path := "res://src/levels/%s/Ch%s.tscn" % [ch, ch.substr(2)]
	if ch == "prolog" or ch == "test_room":
		path = "res://src/levels/%s/%s.tscn" % [ch, ch.capitalize().replace("_", "")]
	elif ch == "epilog":
		path = "res://src/levels/prolog/Epilog.tscn"
	var scn := load(path)
	if scn == null:
		push_error("no scene for " + ch)
		get_tree().quit(1)
		return
	_scene = scn.instantiate()
	# Cleared modda auto_advance kalir — cikis portali production dalinda
	# kurulur; kapaliysa sahne test patikasina girer.
	if "auto_advance" in _scene and not cleared:
		_scene.auto_advance = false
	if death:
		var lw: float = _scene.get("LEVEL_W") if _scene.get("LEVEL_W") != null else 1600.0
		var fy: float = _scene.get("FLOOR_Y") if _scene.get("FLOOR_Y") != null else 250.0
		GameState.set_flag(&"death_mark_ch", StringName(ch))
		GameState.set_flag(&"death_mark_pos",
			Vector2(lerpf(200.0, lw - 200.0, spot) - 60.0, fy - 14))
		GameState.set_flag(&"death_mark_soul", 8)
	# Boss-olu ama gecis-oynanmamis reload durumu — cleared-exit portali.
	if cleared:
		GameState.set_flag(StringName("%s_boss_dead" % ch))
	add_child(_scene)
	get_tree().create_timer(6.0).timeout.connect(get_tree().quit)
	call_deferred("_shoot", ch, spot)


func _shoot(ch: String, spot: float) -> void:
	await get_tree().create_timer(1.0).timeout
	var sam = _scene.get("samurai")
	var lw: float = _scene.get("LEVEL_W") if _scene.get("LEVEL_W") != null else 1600.0
	var fy: float = _scene.get("FLOOR_Y") if _scene.get("FLOOR_Y") != null else 250.0
	var cam = _scene.get("camera")
	if sam != null:
		var tx := lerpf(200.0, lw - 200.0, spot)
		if _cleared:
			# Cleared portalina girme — girerse sahne degisir ve probe'un
			# viewport'u ile birlikte kare uretimi de olur (no frame rendered).
			var ar: float = _scene.get("ARENA_R") if _scene.get("ARENA_R") != null else lw - 200.0
			tx = ar - 130.0
		sam.global_position = Vector2(tx, fy - 20)
		# Kamera smoothing teleportu takip edemez — probe karesi icin
		# kamerayi da oyuncuya kilitleriz.
		if cam != null:
			cam.global_position.x = clampf(
				sam.global_position.x, 240.0, lw - 240.0)
		# Rest modu: ch6 dinlenme vignette'i — ilk kare yorgunluk
		# pozunu, ikinci kare katana-inceleme pozunu yakar.
		if _rest:
			GameState.current_chapter = StringName(ch)
			sam.sm.change_to(Samurai.S_REST, true)
			await get_tree().create_timer(1.2).timeout
			var img_r := await _snap()
			if img_r != null:
				img_r.save_png(
					"res://.probe_out/%s_%.0f_rest1.png" % [ch, spot * 100])
			await get_tree().create_timer(1.0).timeout
			var img_r2 := await _snap()
			if img_r2 != null:
				img_r2.save_png(
					"res://.probe_out/%s_%.0f_rest2.png" % [ch, spot * 100])
			get_tree().quit()
			return
	await get_tree().create_timer(1.2).timeout
	var img := await _snap()
	if img == null:
		push_error("probe: no frame rendered")
		get_tree().quit(1)
		return
	img.save_png("res://.probe_out/%s_%.0f.png" % [ch, spot * 100])
	get_tree().quit()


func _snap() -> Image:
	for i in 10:
		RenderingServer.force_draw(true)
		await get_tree().process_frame
		var tex := get_viewport().get_texture()
		if tex != null:
			var img := tex.get_image()
			if img != null:
				return img
	return null
