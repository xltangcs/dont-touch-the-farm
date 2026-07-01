extends Node

signal level_started(level_index: int, level_path: String)

const LEVEL_LIST_PATH := "res://data/levels/level_list.json"

var _levels: Array[String] = []
var _level_names: Array[String] = []
var _current_level_index: int = -1


func _ready() -> void:
	_load_level_list()


func _load_level_list() -> void:
	if not FileAccess.file_exists(LEVEL_LIST_PATH):
		push_error("Level list file not found: %s" % LEVEL_LIST_PATH)
		return

	var file := FileAccess.open(LEVEL_LIST_PATH, FileAccess.READ)
	if file == null:
		push_error("Failed to open level list file: %s" % LEVEL_LIST_PATH)
		return

	var text := file.get_as_text()
	file.close()

	var parsed = JSON.parse_string(text)
	if parsed == null or typeof(parsed) != TYPE_DICTIONARY:
		push_error("Failed to parse level list JSON: %s" % LEVEL_LIST_PATH)
		return

	var raw_levels = parsed.get("levels", [])
	if typeof(raw_levels) != TYPE_ARRAY:
		push_error("Level list 'levels' must be an array.")
		return

	_levels.clear()
	_level_names.clear()
	for i in range(raw_levels.size()):
		var entry = raw_levels[i]
		if typeof(entry) == TYPE_STRING:
			_levels.append(entry)
			_level_names.append("关卡 %d" % (i + 1))
		elif typeof(entry) == TYPE_DICTIONARY:
			var path: String = entry.get("path", "")
			var name: String = entry.get("name", "关卡 %d" % (i + 1))
			if path.is_empty():
				push_error("Level entry %d in level_list.json is missing 'path' key." % i)
				continue
			_levels.append(path)
			_level_names.append(name)


func start_level(index: int) -> bool:
	if index < 0 or index >= _levels.size():
		push_error("Invalid level index: %d (total: %d)" % [index, _levels.size()])
		return false

	_current_level_index = index
	level_started.emit(index, _levels[index])
	return true


func get_current_level_path() -> String:
	if _current_level_index < 0 or _current_level_index >= _levels.size():
		return ""
	return _levels[_current_level_index]


func get_current_index() -> int:
	return _current_level_index


func has_next_level() -> bool:
	return _current_level_index + 1 < _levels.size()


func next_level() -> bool:
	if not has_next_level():
		return false
	_current_level_index += 1
	level_started.emit(_current_level_index, _levels[_current_level_index])
	return true


func restart_current_level() -> bool:
	if _current_level_index < 0 or _current_level_index >= _levels.size():
		return false
	level_started.emit(_current_level_index, _levels[_current_level_index])
	return true


func get_level_name(index: int) -> String:
	if index < 0 or index >= _level_names.size():
		return ""
	return _level_names[index]


func get_total_levels() -> int:
	return _levels.size()
