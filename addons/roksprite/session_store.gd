@tool
class_name RokSpriteSessionStore
extends RefCounted

const FORMAT_VERSION := 2
const DEFAULT_PATH := "user://roksprite/session-v2.dat"
const MAGIC := "ROKSPRITE_SESSION"


static func save_atomic(metadata: Dictionary, png_data: PackedByteArray, path: String = DEFAULT_PATH) -> Error:
	if png_data.is_empty():
		return ERR_INVALID_DATA
	var absolute_path := ProjectSettings.globalize_path(path)
	var directory := absolute_path.get_base_dir()
	var mkdir_error := DirAccess.make_dir_recursive_absolute(directory)
	if mkdir_error != OK and mkdir_error != ERR_ALREADY_EXISTS:
		return mkdir_error
	var temp_path := "%s.tmp" % absolute_path
	var file := FileAccess.open(temp_path, FileAccess.WRITE)
	if file == null:
		return FileAccess.get_open_error()
	var json_data := JSON.stringify(metadata).to_utf8_buffer()
	file.store_line(MAGIC)
	file.store_32(FORMAT_VERSION)
	file.store_32(json_data.size())
	file.store_buffer(json_data)
	file.store_32(png_data.size())
	file.store_buffer(png_data)
	file.flush()
	file.close()
	var rename_error := DirAccess.rename_absolute(temp_path, absolute_path)
	if rename_error != OK:
		DirAccess.remove_absolute(temp_path)
	return rename_error


static func load_session(path: String = DEFAULT_PATH) -> Dictionary:
	var absolute_path := ProjectSettings.globalize_path(path)
	if not FileAccess.file_exists(absolute_path):
		return {}
	var file := FileAccess.open(absolute_path, FileAccess.READ)
	if file == null or file.get_line() != MAGIC:
		return {}
	if file.get_32() != FORMAT_VERSION:
		return {}
	var json_size := file.get_32()
	if json_size <= 0 or json_size > file.get_length() - file.get_position():
		return {}
	var metadata_value := JSON.parse_string(file.get_buffer(json_size).get_string_from_utf8())
	if not metadata_value is Dictionary:
		return {}
	var png_size := file.get_32()
	if png_size <= 0 or png_size > file.get_length() - file.get_position():
		return {}
	var png_data := file.get_buffer(png_size)
	if png_data.size() != png_size:
		return {}
	return {"metadata": metadata_value, "png_data": png_data}
