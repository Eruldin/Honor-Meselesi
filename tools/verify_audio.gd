extends Node
## Tum music/amb/sfx manifest girdilerinin AssetLoader.audio ile yuklendigini dogrular.
func _ready() -> void:
	var keys := []
	for k in AssetLoader._manifest:
		var ks := String(k)
		if ks.begins_with("music/") or ks.begins_with("amb/") or ks.begins_with("sfx/"):
			keys.append(k)
	var bad := []
	for k in keys:
		var s = AssetLoader.audio(k)
		if s == null:
			bad.append(k)
	print("[AUDIO] checked=", keys.size(), " failed=", bad.size())
	for b in bad:
		print("[AUDIO-MISS] ", b)
	get_tree().quit(1 if bad.size() > 0 else 0)
