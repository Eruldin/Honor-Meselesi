class_name FormLibrary
extends RefCounted
## FormData kayitlari: config/forms/<id>.tres.

const PATH := "res://config/forms/%s.tres"


static func get_form(id: StringName) -> FormData:
	var p := PATH % id
	if not ResourceLoader.exists(p):
		push_error("Form bulunamadi: %s" % id)
		return null
	return load(p)


static func all_ids() -> Array[StringName]:
	return [&"samurai", &"tavuk", &"robot", &"sovalye", &"drone"]
