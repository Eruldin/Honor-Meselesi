extends Node
## Muzik + SFX yoneticisi. AssetLoader uzerinden manifest eslemeli
## dis dosyalari calar; dosya yoksa sessizce gecer (asset'siz calisir).
##
## play_music("music/ch4") — seviye muzigi (loop)
## play_sfx("sfx/attack", global_pos) — tek seferlik efekt
## sfx_bus/music_bus uzerinden Settings ile ses ayarlanabilir.

const SFX_POOL := 8

var _music_a: AudioStreamPlayer
var _music_b: AudioStreamPlayer
var _active_music: int = 1
var _music_fade := 0.0
var _amb1: AudioStreamPlayer
var _amb2: AudioStreamPlayer
var _active_amb: int = 1
var _current_amb: StringName = &""
var _amb_fade := 0.0

var _sfx_pool: Array[AudioStreamPlayer] = []
var _sfx_2d_pool: Array[AudioStreamPlayer2D] = []
var _sfx_idx := 0
var _sfx2d_idx := 0
var _current_music: StringName = &""
var _sting_resume: StringName = &""  ## tek-calar parca bitince donecek bolge muzigi


func _ready() -> void:
	_music_a = AudioStreamPlayer.new()
	_music_a.bus = &"Music"
	add_child(_music_a)
	_music_a.finished.connect(_on_music_finished)
	_music_b = AudioStreamPlayer.new()
	_music_b.bus = &"Music"
	add_child(_music_b)
	_music_b.finished.connect(_on_music_finished)
	_amb1 = AudioStreamPlayer.new()
	_amb1.bus = &"Music"
	add_child(_amb1)
	_amb2 = AudioStreamPlayer.new()
	_amb2.bus = &"Music"
	add_child(_amb2)
	for i in SFX_POOL:
		var p := AudioStreamPlayer.new()
		p.bus = &"SFX"
		add_child(p)
		_sfx_pool.append(p)
		var p2 := AudioStreamPlayer2D.new()
		p2.bus = &"SFX"
		p2.max_distance = 400.0
		add_child(p2)
		_sfx_2d_pool.append(p2)


## Seviye muzigi. Ayni parca tekrar istenirse dokunmaz.
## Degisim 1s crossfade ile olur — dinlenme/boss gecisleri yumusak.
func play_music(logical_id: StringName, resume_id: StringName = &"") -> void:
	if logical_id == _current_music:
		return
	var prev := _current_music
	_current_music = logical_id
	_sting_resume = &""
	var stream := AssetLoader.audio(logical_id)
	if stream == null:
		return
	if stream is AudioStreamOggVorbis or stream is AudioStreamMP3:
		var loops := bool(AssetLoader.entry(logical_id).get("loop", true))
		stream.loop = loops
		# Tek-calar parcalar (zafer sting'i gibi): bitince onceki
		# bolge muzigine donulur; yoksa kisa fanfar sonsuz donguye girer.
		if not loops:
			_sting_resume = resume_id if resume_id != &"" else prev
	_active_music = 2 if _active_music == 1 else 1
	var next_p := _music_a if _active_music == 1 else _music_b
	next_p.stream = stream
	next_p.volume_db = -80.0
	next_p.play()
	_music_fade = 1.0


func _on_music_finished() -> void:
	if _sting_resume == &"":
		return
	var resume := _sting_resume
	_sting_resume = &""
	play_music(resume)


func stop_music() -> void:
	_current_music = &""
	_sting_resume = &""
	_music_a.stop()
	_music_b.stop()
	_music_fade = 0.0

func play_ambience(logical_id: StringName) -> void:
	if logical_id == _current_amb:
		return
	_current_amb = logical_id
	var stream := AssetLoader.audio(logical_id)
	
	_active_amb = 2 if _active_amb == 1 else 1
	var next_p := _amb1 if _active_amb == 1 else _amb2
	
	if stream == null:
		next_p.stop()
	else:
		if stream is AudioStreamOggVorbis or stream is AudioStreamMP3:
			stream.loop = true
		next_p.stream = stream
		next_p.volume_db = -80.0
		next_p.play()
	_amb_fade = 1.0

func _process(delta: float) -> void:
	if _music_fade > 0.0:
		_music_fade = maxf(0.0, _music_fade - delta)  # 1s crossfade
		var mt := 1.0 - _music_fade
		var m_act := _music_a if _active_music == 1 else _music_b
		var m_old := _music_b if _active_music == 1 else _music_a
		if m_act.playing:
			m_act.volume_db = linear_to_db(lerpf(0.0, 1.0, mt))
		if m_old.playing:
			m_old.volume_db = linear_to_db(lerpf(1.0, 0.0, mt))
			if _music_fade == 0.0:
				m_old.stop()
	if _amb_fade > 0.0:
		_amb_fade = maxf(0.0, _amb_fade - delta) # 1 saniye crossfade
		var t := 1.0 - _amb_fade
		var p_active := _amb1 if _active_amb == 1 else _amb2
		var p_old := _amb2 if _active_amb == 1 else _amb1
		
		# -80 dB ile -18 dB arasi linear2db crossfade
		if p_active.playing:
			p_active.volume_db = linear_to_db(lerpf(0.0, db_to_linear(-18.0), t))
		if p_old.playing:
			p_old.volume_db = linear_to_db(lerpf(db_to_linear(-18.0), 0.0, t))
			if _amb_fade == 0.0:
				p_old.stop()


## Tek seferlik efekt; pos verilirse 2D konumlu calar.
func play_sfx(logical_id: StringName, pos: Variant = null, volume_db := 0.0, pitch_scale := 1.0) -> void:
	var stream := AssetLoader.audio(logical_id)
	if stream == null:
		return
	if pos is Vector2:
		var p := _sfx_2d_pool[_sfx2d_idx]
		_sfx2d_idx = (_sfx2d_idx + 1) % _sfx_2d_pool.size()
		p.global_position = pos
		p.stream = stream
		p.volume_db = volume_db
		p.pitch_scale = pitch_scale
		p.play()
	else:
		var p := _sfx_pool[_sfx_idx]
		_sfx_idx = (_sfx_idx + 1) % _sfx_pool.size()
		p.stream = stream
		p.volume_db = volume_db
		p.pitch_scale = pitch_scale
		p.play()
