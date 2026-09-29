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


## Manifest'te tanimli ve dis dosyasi mevcut mu?
func has_asset(logical_id: StringName) -> bool:
	var entry: Variant = _manifest.get(logical_id)
	if not entry is Dictionary:
		return false
	var rel: String = entry.get("path", "")
	if rel.is_empty():
		return false
	return ResourceLoader.exists(EXTERNAL_ROOT.path_join(rel))


## Mantiksal asset icin texture dondurur; yoksa placeholder uretir.
func texture(logical_id: StringName, size := Vector2i(16, 16)) -> Texture2D:
	if has_asset(logical_id):
		return load(EXTERNAL_ROOT.path_join(_manifest[logical_id]["path"]))
	var local_path: String = PLACEHOLDER_ROOT.path_join(String(logical_id).replace("/", "_") + ".png")
	if ResourceLoader.exists(local_path):
		return load(local_path)
	return placeholder_texture(String(logical_id), size)


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
