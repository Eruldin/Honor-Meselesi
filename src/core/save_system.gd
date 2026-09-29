extends Node
## user://save.json tabanli kayit sistemi. Surum alani ileride
## eski kayitlari migrate etmek icin kullanilir.

const SAVE_PATH := "user://save.json"


func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)


func save_game() -> Error:
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f == null:
		return FileAccess.get_open_error()
	f.store_string(JSON.stringify(GameState.to_dict(), "\t"))
	return OK


func load_game() -> Error:
	if not has_save():
		return ERR_FILE_NOT_FOUND
	var text := FileAccess.get_file_as_string(SAVE_PATH)
	var data: Variant = JSON.parse_string(text)
	if not data is Dictionary:
		return ERR_PARSE_ERROR
	var version := int(data.get("version", 0))
	if version > GameState.SAVE_VERSION:
		push_warning("Save version %d is newer than game version %d" % [version, GameState.SAVE_VERSION])
	GameState.from_dict(data)
	return OK


func wipe() -> void:
	if has_save():
		DirAccess.remove_absolute(SAVE_PATH)
