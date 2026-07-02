@tool
extends Node

const CONFIG_PATH := "res://data/tilemap_configs.json"

var _configs: Dictionary = {}


func _ready() -> void:
	load_configs()


func load_configs() -> void:
	_configs.clear()

	if not FileAccess.file_exists(CONFIG_PATH):
		push_error("TileMap config file not found: %s" % CONFIG_PATH)
		return

	var file := FileAccess.open(CONFIG_PATH, FileAccess.READ)
	if file == null:
		push_error("Failed to open tilemap config file: %s" % CONFIG_PATH)
		return

	var text := file.get_as_text()
	file.close()

	var parsed = JSON.parse_string(text)
	if parsed == null:
		push_error("Failed to parse tilemap config JSON: %s" % CONFIG_PATH)
		return

	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("TileMap config JSON root must be a dictionary.")
		return

	for id_str in parsed.keys():
		var entry = parsed[id_str]
		if typeof(entry) != TYPE_DICTIONARY:
			push_warning("Skipping invalid tilemap config entry: %s" % id_str)
			continue

		var id: int = int(id_str)
		_configs[id] = _parse_config(id, entry)


func get_config(id: int) -> TileMapConfigData:
	return _configs.get(id)


func has_config(id: int) -> bool:
	return _configs.has(id)


func _parse_config(id: int, data: Dictionary) -> TileMapConfigData:
	var config: TileMapConfigData = TileMapConfigData.new()
	config.id = id
	config.display_name = str(data.get("display_name", str(id)))
	config.scene_path = str(data.get("scene", ""))
	config.texture_path = str(data.get("texture", ""))
	config.has_collision = bool(data.get("has_collision", true))
	config.disabled_action = str(data.get("disabled_action", ""))
	config.disabled_key_label = DisabledKeyConfig.resolve_label(
		config.disabled_action,
		str(data.get("disabled_key_label", ""))
	)
	config.z_index = int(data.get("z_index", 0))
	config.initial_lit = bool(data.get("initial_lit", false))
	config.rain_target_id = str(data.get("rain_target_id", ""))
	return config
