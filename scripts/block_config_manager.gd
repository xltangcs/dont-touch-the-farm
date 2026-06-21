extends Node

const BlockConfigData = preload("res://scripts/block_config_data.gd")
const CONFIG_PATH := "res://data/block_configs.json"

var _configs: Dictionary = {}


func _ready() -> void:
	load_configs()


func load_configs() -> void:
	_configs.clear()

	if not FileAccess.file_exists(CONFIG_PATH):
		push_error("Block config file not found: %s" % CONFIG_PATH)
		return

	var file := FileAccess.open(CONFIG_PATH, FileAccess.READ)
	if file == null:
		push_error("Failed to open block config file: %s" % CONFIG_PATH)
		return

	var text := file.get_as_text()
	file.close()

	var parsed = JSON.parse_string(text)
	if parsed == null:
		push_error("Failed to parse block config JSON: %s" % CONFIG_PATH)
		return

	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("Block config JSON root must be a dictionary.")
		return

	for id in parsed.keys():
		var entry = parsed[id]
		if typeof(entry) != TYPE_DICTIONARY:
			push_warning("Skipping invalid block config entry: %s" % id)
			continue

		_configs[id] = _parse_config(str(id), entry)


func get_config(id: String) -> BlockConfigData:
	return _configs.get(id)


func has_config(id: String) -> bool:
	return _configs.has(id)


func _parse_config(id: String, data: Dictionary) -> BlockConfigData:
	var config: BlockConfigData = BlockConfigData.new()
	config.id = id
	config.display_name = str(data.get("display_name", id))
	config.resource_id = str(data.get("resource_id", ""))
	config.resource_amount = int(data.get("resource_amount", 1))
	config.max_mine_count = int(data.get("max_mine_count", 1))
	config.requires_force_mining = bool(data.get("requires_force_mining", false))
	config.debuff_id = str(data.get("debuff_id", ""))
	config.block_texture = _make_texture(
		str(data.get("block_texture", "")),
		data.get("block_region", null)
	)
	config.resource_icon = _make_texture(
		str(data.get("resource_icon", "")),
		data.get("resource_icon_region", null)
	)
	return config


func _make_texture(path: String, region_data: Variant) -> Texture2D:
	if path.is_empty():
		return null

	var texture := load(path) as Texture2D
	if texture == null:
		push_warning("Failed to load texture: %s" % path)
		return null

	if region_data == null:
		return texture

	if typeof(region_data) != TYPE_ARRAY or region_data.size() < 4:
		push_warning("Invalid region for texture: %s" % path)
		return texture

	var atlas := AtlasTexture.new()
	atlas.atlas = texture
	atlas.region = Rect2(
		float(region_data[0]),
		float(region_data[1]),
		float(region_data[2]),
		float(region_data[3])
	)
	return atlas
