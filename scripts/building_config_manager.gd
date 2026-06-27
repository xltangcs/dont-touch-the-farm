extends Node

const BuildingConfigData = preload("res://scripts/building_config_data.gd")
const BuildingRecipeData = preload("res://scripts/building_recipe_data.gd")
const BuildingRecipeInputData = preload("res://scripts/building_recipe_input_data.gd")
const CONFIG_PATH := "res://data/building_configs.json"

var _configs: Dictionary = {}


func _ready() -> void:
	load_configs()


func load_configs() -> void:
	_configs.clear()

	if not FileAccess.file_exists(CONFIG_PATH):
		push_error("Building config file not found: %s" % CONFIG_PATH)
		return

	var file := FileAccess.open(CONFIG_PATH, FileAccess.READ)
	if file == null:
		push_error("Failed to open building config file: %s" % CONFIG_PATH)
		return

	var text := file.get_as_text()
	file.close()

	var parsed = JSON.parse_string(text)
	if parsed == null:
		push_error("Failed to parse building config JSON: %s" % CONFIG_PATH)
		return

	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("Building config JSON root must be a dictionary.")
		return

	for id in parsed.keys():
		var entry = parsed[id]
		if typeof(entry) != TYPE_DICTIONARY:
			push_warning("Skipping invalid building config entry: %s" % id)
			continue

		_configs[id] = _parse_config(str(id), entry)


func get_config(id: String) -> BuildingConfigData:
	return _configs.get(id)


func has_config(id: String) -> bool:
	return _configs.has(id)


func _parse_config(id: String, data: Dictionary) -> BuildingConfigData:
	var config: BuildingConfigData = BuildingConfigData.new()
	config.id = id
	config.display_name = str(data.get("display_name", id))
	config.building_texture = _make_texture(
		str(data.get("building_texture", "")),
		data.get("building_region", null)
	)
	config.action_text = str(data.get("action_text", "upgrade"))
	config.button_variation = StringName(str(data.get("button_variation", "BuildingBuildButton")))
	config.recipe = _parse_recipe_data(data.get("recipe", null))
	return config


func _parse_recipe_data(recipe_data: Variant) -> BuildingRecipeData:
	if typeof(recipe_data) != TYPE_DICTIONARY:
		push_warning("Skipping invalid building recipe.")
		return null
	return _parse_recipe(recipe_data)


func _parse_recipe(data: Dictionary) -> BuildingRecipeData:
	var recipe := BuildingRecipeData.new()
	recipe.output_id = str(data.get("output_id", ""))
	recipe.output_amount = int(data.get("output_amount", 1))
	recipe.display_name = str(data.get("display_name", recipe.output_id))
	recipe.description = str(data.get("description", ""))
	recipe.product_texture = _make_texture(
		str(data.get("product_texture", "")),
		data.get("product_region", null)
	)
	recipe.inputs = _parse_recipe_inputs(data.get("inputs", []))
	return recipe


func _parse_recipe_inputs(inputs_data: Variant) -> Array:
	var inputs: Array = []

	if typeof(inputs_data) != TYPE_ARRAY:
		return inputs

	for entry in inputs_data:
		if typeof(entry) != TYPE_DICTIONARY:
			push_warning("Skipping invalid recipe input entry.")
			continue

		var input := BuildingRecipeInputData.new()
		input.item_id = str(entry.get("item_id", ""))
		input.amount = int(entry.get("amount", 1))
		inputs.append(input)

	return inputs


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
