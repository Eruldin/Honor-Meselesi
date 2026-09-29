extends Node
## Muzik + SFX yoneticisi. AssetLoader uzerinden manifest eslemeli
## dis dosyalari calar; dosya yoksa sessizce gecer (asset'siz calisir).
##
## play_music("music/ch4") — seviye muzigi (loop)
## play_sfx("sfx/attack", global_pos) — tek seferlik efekt
## sfx_bus/music_bus uzerinden Settings ile ses ayarlanabilir.

const SFX_POOL := 8

var _music: AudioStreamPlayer
var _sfx_pool: Array[AudioStreamPlayer] = []
var _sfx_2d_pool: Array[AudioStreamPlayer2D] = []
var _sfx_idx := 0
var _sfx2d_idx := 0
var _current_music: StringName = &""


func _ready() -> void:
	_music = AudioStreamPlayer.new()
	_music.bus = &"Music"
	add_child(_music)
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
func play_music(logical_id: StringName) -> void:
	if logical_id == _current_music:
		return
	_current_music = logical_id
	var stream := AssetLoader.audio(logical_id)
	if stream == null:
		return
	if stream is AudioStreamOggVorbis or stream is AudioStreamMP3:
		stream.loop = true
	_music.stream = stream
	if not _music.playing:
		_music.play()
	else:
		_music.play()  # yeniden baslat


func stop_music() -> void:
	_current_music = &""
	_music.stop()


## Tek seferlik efekt; pos verilirse 2D konumlu calar.
func play_sfx(logical_id: StringName, pos: Variant = null, volume_db := 0.0) -> void:
	var stream := AssetLoader.audio(logical_id)
	if stream == null:
		return
	if pos is Vector2:
		var p := _sfx_2d_pool[_sfx2d_idx]
		_sfx2d_idx = (_sfx2d_idx + 1) % _sfx_2d_pool.size()
		p.global_position = pos
		p.stream = stream
		p.volume_db = volume_db
		p.play()
	else:
		var p := _sfx_pool[_sfx_idx]
		_sfx_idx = (_sfx_idx + 1) % _sfx_pool.size()
		p.stream = stream
		p.volume_db = volume_db
		p.play()
