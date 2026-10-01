extends Node
## Gercek asset'leri res://assets_external/ altindan assets_manifest.json
## eslemesine gore yukler. Dosya yoksa otomatik olarak uretilmis
## placeholder texture'a duser — oyun asset'siz de calisir.
##
## Manifest semasi (assets_manifest.json):
## {
##   "version": 1,
##   "assets": {
##     "player/samurai/idle": { "path": "samurai/idle.png", "pack": "FREE_Samurai 2D Pixel Art", "license": "CC0" }
##   }
## }

const MANIFEST_PATH := "res://assets_manifest.json"
const EXTERNAL_ROOT := "res://assets_external/"
const PLACEHOLDER_ROOT := "res://assets_placeholder/"

var _manifest: Dictionary = {}
var _cache: Dictionary = {}


func _ready() -> void:
	_load_manifest()


func _load_manifest() -> void:
	_manifest.clear()
	if not FileAccess.file_exists(MANIFEST_PATH):
		return
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(MANIFEST_PATH))
	if data is Dictionary:
		_manifest = data.get("assets", {})


func reload_manifest() -> void:
	_load_manifest()
	_cache.clear()


## Giris meta verisi (or. "loop": false gibi istege bagli bayraklar).
func entry(logical_id: StringName) -> Dictionary:
	var e: Variant = _manifest.get(logical_id)
	return e if e is Dictionary else {}


## Manifest'te tanimli ve dis dosyasi mevcut mu?
## Dis dosyalar EditorFileSystem import'una guvenmez — diskte varsa sayilir
## (res:// editor'da proje kokune, export'ta exe yanina cozulur).
func has_asset(logical_id: StringName) -> bool:
	var entry: Variant = _manifest.get(logical_id)
	if not entry is Dictionary:
		return false
	var rel: String = entry.get("path", "")
	if rel.is_empty():
		# cok dosyali animasyon: ilk dosya yeterli isaret
		var fl: Variant = entry.get("files")
		if fl is Array and not fl.is_empty():
			rel = fl[0]
		else:
			return false
	return FileAccess.file_exists(_resolve_external(rel))


## res://assets_external/<rel> icin okunabilir gercek yol dondurur.
## Sirayla: 1) res:// dogrudan (editor/import edilmis), 2) proje kok
## globalize, 3) calistirilabilir yanindaki assets_external/ (export).
func _resolve_external(rel: String) -> String:
	var res := EXTERNAL_ROOT.path_join(rel)
	# Mutlak yol tercih et: Image.load_from_file res:// uzerinden
	# "will not work on export" hatasi basar (import'suz dis dosyalar).
	var proj := ProjectSettings.globalize_path(res)
	if FileAccess.file_exists(proj):
		return proj
	if FileAccess.file_exists(res):
		return res
	var beside_exe := OS.get_executable_path().get_base_dir().path_join(
		"assets_external").path_join(rel)
	if FileAccess.file_exists(beside_exe):
		return beside_exe
	return res  # en iyi tahmin — cagiran FileAccess hatasini gorur


## Dis PNG'yi diskten yukler (import gerektirmez).
func _load_image_texture(rel: String) -> Texture2D:
	var img := Image.load_from_file(_resolve_external(rel))
	if img == null:
		return null
	return ImageTexture.create_from_image(img)


## Mantiksal asset icin texture dondurur; yoksa placeholder uretir.
## Manifest "region": [x,y,w,h] varsa atlas bolgesi (AtlasTexture) doner.
## size > 0 verilirse doku o boyuta NEAREST ile olceklenir (sprite'larin
## istenen oyun boyutunda gorunmesi icin); negatif/varsayilan = native boyut.
func texture(logical_id: StringName, size := Vector2i(-1, -1)) -> Texture2D:
	var key := "tex_%s_%dx%d" % [logical_id, size.x, size.y]
	if _cache.has(key):
		return _cache[key]
	if has_asset(logical_id):
		var entry: Dictionary = _manifest[logical_id]
		# cok-kareli girdide tek texture istenirse ilk kareyi ver
		var rel: String = entry["files"][0] if entry.has("files") else entry.get("path", "")
		var full := _load_image_texture(rel)
		if full != null:
			var src: Texture2D = full
			if entry.has("region"):
				var r: Array = entry["region"]
				var at := AtlasTexture.new()
				at.atlas = full
				at.region = Rect2(r[0], r[1], r[2], r[3])
				src = at
			if size.x > 0 and size.y > 0 and Vector2i(src.get_size()) != size:
				var img := src.get_image()
				if img != null:
					img.resize(size.x, size.y, Image.INTERPOLATE_NEAREST)
					src = ImageTexture.create_from_image(img)
			_cache[key] = src
			return src
	var local_path: String = PLACEHOLDER_ROOT.path_join(String(logical_id).replace("/", "_") + ".png")
	if ResourceLoader.exists(local_path):
		return load(local_path)
	return placeholder_texture(String(logical_id), size if size.x > 0 else Vector2i(16, 16))


## Spritesheet'ten SpriteFrames uretir: manifest "frame": [w,h], "fps": n.
## Manifest yoksa veya sheet okunamiyorsa bos SpriteFrames doner.
func frames(logical_id: StringName) -> SpriteFrames:
	var key := "anim_" + String(logical_id)
	if _cache.has(key):
		return _cache[key]
	var sf := SpriteFrames.new()
	if has_asset(logical_id):
		var entry: Dictionary = _manifest[logical_id]
		sf.set_animation_speed(&"default", float(entry.get("fps", 8)))
		sf.set_animation_loop(&"default", true)
		if entry.has("files"):
			# cok dosyali animasyon: her dosya bir cerceve
			for rel in entry["files"]:
				var ftex := _load_image_texture(rel)
				if ftex != null:
					sf.add_frame(&"default", ftex)
		elif entry.has("frame"):
			var sheet := _load_image_texture(entry["path"])
			if sheet != null:
				var fw: int = entry["frame"][0]
				var fh: int = entry["frame"][1]
				var cols := int(sheet.get_width() / fw)
				var rows := int(sheet.get_height() / fh)
				for ry in rows:
					for cx in cols:
						var at := AtlasTexture.new()
						at.atlas = sheet
						at.region = Rect2(cx * fw, ry * fh, fw, fh)
						sf.add_frame(&"default", at)
	_cache[key] = sf
	return sf


## Kaynak dokuyu (region dahil) yatayda döşeyerek istenen boyutta
## tek ImageTexture üretir — geniş zemin/parallax katmanları için.
func tiled_texture(logical_id: StringName, size: Vector2i) -> Texture2D:
	var key := "tile_%s_%dx%d" % [logical_id, size.x, size.y]
	if _cache.has(key):
		return _cache[key]
	var src: Texture2D = texture(logical_id)
	if src == null:
		return null
	var t := src.get_image()
	if t == null or t.get_width() <= 0 or t.get_height() <= 0:
		return src
	if t.get_format() != Image.FORMAT_RGBA8:
		t.convert(Image.FORMAT_RGBA8)
	var img := Image.create(size.x, size.y, false, Image.FORMAT_RGBA8)
	img.fill(Color.TRANSPARENT)
	var tw := t.get_width()
	var th := t.get_height()
	for y in range(0, size.y, th):
		for x in range(0, size.x, tw):
			img.blit_rect(t, Rect2i(0, 0, tw, th), Vector2i(x, y))
	var out := ImageTexture.create_from_image(img)
	_cache[key] = out
	return out


## Manifest'te tanimli ve animasyonlu sheet'i var mi?
func has_frames(logical_id: StringName) -> bool:
	var entry: Variant = _manifest.get(logical_id)
	return (entry is Dictionary
		and (entry.has("frame") or entry.has("files"))
		and has_asset(logical_id))


## Ses/muzik akisi (ogg/mp3/wav dis dosyasi, import gerektirmez).
func audio(logical_id: StringName) -> AudioStream:
	var key := "snd_" + String(logical_id)
	if _cache.has(key):
		return _cache[key]
	if not has_asset(logical_id):
		return null
	var path := _resolve_external(_manifest[logical_id]["path"])
	var ext := path.get_extension().to_lower()
	var s: AudioStream = null
	match ext:
		"ogg":
			s = AudioStreamOggVorbis.load_from_file(path)
		"mp3":
			s = AudioStreamMP3.load_from_file(path)
		"wav":
			s = _load_wav(path)
	_cache[key] = s
	return s


## Minimal WAV okuyucu (PCM 8/16-bit mono/stereo) — AudioStreamWAV.
func _load_wav(path: String) -> AudioStream:
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return null
	var riff := f.get_buffer(12)
	if riff.size() < 12 or riff.get_string_from_ascii().substr(0, 4) != "RIFF":
		return null
	var channels := 1
	var rate := 44100
	var bits := 16
	var data := PackedByteArray()
	while not f.eof_reached():
		var cid := f.get_buffer(4).get_string_from_ascii()
		var csize := f.get_32()
		if cid == "fmt ":
			f.get_16()  # audio format
			channels = f.get_16()
			rate = f.get_32()
			f.get_32()  # byte rate
			f.get_16()  # block align
			bits = f.get_16()
			f.get_buffer(maxi(csize - 16, 0))
		elif cid == "data":
			data = f.get_buffer(csize)
		else:
			f.get_buffer(csize)
	if data.is_empty():
		return null
	var s := AudioStreamWAV.new()
	s.format = AudioStreamWAV.FORMAT_16_BITS if bits == 16 else AudioStreamWAV.FORMAT_8_BITS
	s.mix_rate = rate
	s.stereo = channels > 1
	s.data = data
	return s


func placeholder_texture(tag: String, size := Vector2i(16, 16)) -> ImageTexture:
	var key := "%s_%dx%d" % [tag, size.x, size.y]
	if _cache.has(key):
		return _cache[key]
	var tex := _generate_placeholder(size, _color_for_tag(tag))
	_cache[key] = tex
	return tex


func _generate_placeholder(size: Vector2i, color: Color) -> ImageTexture:
	var img := Image.create(size.x, size.y, false, Image.FORMAT_RGBA8)
	img.fill(color)
	var dark := color.darkened(0.55)
	for x in range(size.x):
		img.set_pixel(x, 0, dark)
		img.set_pixel(x, size.y - 1, dark)
	for y in range(size.y):
		img.set_pixel(0, y, dark)
		img.set_pixel(size.x - 1, y, dark)
	# capraz glitc cizgisi — "burasi placeholder" hissi icin
	for i in range(mini(size.x, size.y)):
		if i % 2 == 0:
			img.set_pixel(i, i, Color.WHITE)
	return ImageTexture.create_from_image(img)


## Ayni mantiksal id hep ayni rengi uretsin (deterministik).
func _color_for_tag(tag: String) -> Color:
	var h := tag.hash()
	return Color.from_hsv(float(h % 360) / 360.0, 0.65, 0.85)


## Sprite2D'ye tek satirda asset/placeholder baglar.
func apply_to_sprite(sprite: Sprite2D, logical_id: StringName, size := Vector2i(16, 16)) -> void:
	sprite.texture = texture(logical_id, size)
