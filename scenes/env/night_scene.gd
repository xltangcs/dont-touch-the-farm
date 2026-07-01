@tool
extends Node2D

const DEFAULT_SCENE_PATH := "res://scenes/env/tile_base.tscn"
const GENERATED_GROUP := "generated_tile"

@export var level_config_path: String = "res://data/levels/level_01.json"
@export var enable_tile_generation: bool = false
@export var default_tile_size: float = 66.0

@export_tool_button("生成关卡", "Callable") var editor_generate_action = editor_generate

func editor_generate() -> void:
	if not Engine.is_editor_hint():
		return
	_clear_old_tiles()
	_generate_from_level_json()
	print("关卡已生成: %s" % level_config_path)


func _ready() -> void:
	if Engine.is_editor_hint():
		return

	var manager_path := LevelManager.get_current_level_path()
	if not manager_path.is_empty():
		level_config_path = manager_path

	if enable_tile_generation:
		_clear_old_tiles()
		_generate_from_level_json()


func _generate_from_level_json() -> void:
	TileMapConfigManager.load_configs()

	if level_config_path.is_empty():
		return

	var level_data := _load_level_json()
	if level_data.is_empty():
		return

	var tile_size: float = level_data.get("tile_size", default_tile_size)
	var origin: Vector2 = _parse_origin(level_data.get("origin", [0, 0]))
	var grid: Array = level_data.get("grid", [])
	if grid.is_empty():
		return

	for row in grid.size():
		var cols = grid[row]
		if typeof(cols) != TYPE_ARRAY:
			continue
		for col in cols.size():
			var tile_id: int = cols[col]
			if tile_id == 0:
				continue
			_spawn_tile(tile_id, origin + Vector2(col * tile_size, row * tile_size))


func _clear_old_tiles() -> void:
	for child in get_children():
		child.queue_free()
	#var children := get_children()
	#for i in range(children.size() - 1, -1, -1):
		#var child := children[i]
		#if child.is_in_group(GENERATED_GROUP):
			#remove_child(child)
			#child.queue_free()


func _load_level_json() -> Dictionary:
	if not FileAccess.file_exists(level_config_path):
		push_error("Level config file not found: %s" % level_config_path)
		return {}

	var file := FileAccess.open(level_config_path, FileAccess.READ)
	if file == null:
		push_error("Failed to open level config file: %s" % level_config_path)
		return {}

	var text := file.get_as_text()
	file.close()

	var parsed = JSON.parse_string(text)
	if parsed == null:
		push_error("Failed to parse level config JSON: %s" % level_config_path)
		return {}

	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("Level config JSON root must be a dictionary.")
		return {}

	return parsed


func _parse_origin(data) -> Vector2:
	if typeof(data) == TYPE_ARRAY and data.size() >= 2:
		return Vector2(float(data[0]), float(data[1]))
	return Vector2.ZERO


func _spawn_tile(tile_id: int, world_pos: Vector2) -> void:
	var config: TileMapConfigData = TileMapConfigManager.get_config(tile_id)
	if config == null:
		push_warning("No tile config found for id: %d" % tile_id)
		return

	var scene_path := config.scene_path
	if scene_path.is_empty():
		scene_path = DEFAULT_SCENE_PATH

	var scene: PackedScene = load(scene_path)
	if scene == null:
		push_error("Failed to load tile scene: %s" % scene_path)
		return

	var instance: Node2D = scene.instantiate()
	instance.position = world_pos
	instance.z_index = config.z_index
	instance.y_sort_enabled = true
	instance.add_to_group(GENERATED_GROUP)

	if not config.texture_path.is_empty() and "sprite" in instance:
		instance.sprite = load(config.texture_path)

	if instance.has_method("setup_tile_effect") and not config.disabled_action.is_empty():
		instance.setup_tile_effect(config.disabled_action, config.disabled_key_label)

	add_child(instance)
	_apply_tile_collision(instance, config.has_collision)

	if Engine.is_editor_hint():
		instance.owner = get_tree().edited_scene_root


func _apply_tile_collision(instance: Node2D, has_collision: bool) -> void:
	var body: StaticBody2D = instance.get_node_or_null("StaticBody2D")
	if not body:
		return
	if has_collision:
		body.collision_layer = 1
		body.collision_mask = 1
	else:
		body.collision_layer = 0
		body.collision_mask = 0
