@tool
extends Node2D

const DEFAULT_SCENE_PATH := "res://scenes/env/tile_base.tscn"
const END_POINT_SCENE_PATH := "res://scenes/env/end_point.tscn"
const RAIN_ZONE_SCENE_PATH := "res://scenes/env/rain_zone.tscn"
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
			_spawn_tile(tile_id, origin + Vector2(col * tile_size, row * tile_size), col, row, level_data)

	_spawn_rain_system(level_data, tile_size, origin)
	_handle_level_points(level_data, tile_size, origin)


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


func _spawn_tile(tile_id: int, world_pos: Vector2, col: int, row: int, level_data: Dictionary) -> void:
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
	instance.set_meta("grid_col", col)
	instance.set_meta("grid_row", row)

	if "initial_lit" in instance:
		instance.initial_lit = config.initial_lit

	if not config.texture_path.is_empty() and "sprite" in instance:
		instance.sprite = load(config.texture_path)

	if "rain_target_id" in instance:
		var target_id := config.rain_target_id
		if target_id.is_empty():
			target_id = _resolve_rain_target_for_button(col, row, level_data)
		instance.rain_target_id = target_id

	add_child(instance)
	_apply_tile_collision(instance, config.has_collision)

	if instance.has_method("setup_tile_effect") and not config.disabled_action.is_empty():
		instance.setup_tile_effect(config.disabled_action, config.disabled_key_label)

	if Engine.is_editor_hint():
		instance.owner = get_tree().edited_scene_root


func _spawn_rain_system(level_data: Dictionary, tile_size: float, origin: Vector2) -> void:
	var rain_zones: Array = level_data.get("rain_zones", [])
	for zone_data in rain_zones:
		if typeof(zone_data) != TYPE_DICTIONARY:
			continue
		_spawn_rain_zone(zone_data, tile_size, origin)


func _resolve_rain_target_for_button(col: int, row: int, level_data: Dictionary) -> String:
	for zone_data in level_data.get("rain_zones", []):
		if typeof(zone_data) != TYPE_DICTIONARY:
			continue
		var btn = zone_data.get("button", [])
		if typeof(btn) != TYPE_ARRAY or btn.size() < 2:
			continue
		if int(btn[0]) == col and int(btn[1]) == row:
			return str(zone_data.get("id", ""))

	for button_data in level_data.get("rain_buttons", []):
		if typeof(button_data) != TYPE_DICTIONARY:
			continue
		if int(button_data.get("col", -1)) == col and int(button_data.get("row", -1)) == row:
			return str(button_data.get("target_rain_id", ""))

	return "rain_01"


func _spawn_rain_zone(zone_data: Dictionary, tile_size: float, origin: Vector2) -> void:
	var zone_id := str(zone_data.get("id", ""))
	if zone_id.is_empty():
		push_warning("Rain zone missing id, skipped.")
		return

	var cells: Array = zone_data.get("cells", [])
	if cells.is_empty():
		push_warning("Rain zone '%s' has no cells, skipped." % zone_id)
		return

	var scene: PackedScene = load(RAIN_ZONE_SCENE_PATH)
	if scene == null:
		push_error("Failed to load rain zone scene: %s" % RAIN_ZONE_SCENE_PATH)
		return

	var active: bool = bool(zone_data.get("active", true))
	var instance := scene.instantiate()
	instance.set_meta("rain_zone_setup", {
		"id": zone_id,
		"cells": cells,
		"tile_size": tile_size,
		"origin": origin,
		"active": active,
	})
	add_child(instance)
	instance.add_to_group(GENERATED_GROUP)
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


func _handle_level_points(level_data: Dictionary, tile_size: float, origin: Vector2) -> void:
	if Engine.is_editor_hint():
		return

	var grid: Array = level_data.get("grid", [])

	var start_point: Array = level_data.get("start_point", [])
	if start_point.size() >= 2:
		var start_col: int = int(start_point[0])
		var start_row: int = int(start_point[1])
		_check_start_collision(grid, start_col, start_row)
		var start_world_pos := origin + Vector2(start_col * tile_size, start_row * tile_size)
		var player := get_node_or_null("../MainCharacter")
		if player:
			player.position = start_world_pos
		else:
			push_error("MainCharacter not found - cannot place player at start point.")
	else:
		push_warning("Level missing start_point.")

	var end_point: Array = level_data.get("end_point", [])
	if end_point.size() >= 2:
		var end_col: int = int(end_point[0])
		var end_row: int = int(end_point[1])
		var end_world_pos := origin + Vector2(end_col * tile_size, end_row * tile_size)
		_spawn_end_point(end_world_pos)
	else:
		push_warning("Level missing end_point.")


func _check_start_collision(grid: Array, col: int, row: int) -> void:
	if row < 0 or row >= grid.size():
		push_warning("Start point row %d out of grid bounds." % row)
		return
	var cols = grid[row]
	if typeof(cols) != TYPE_ARRAY or col < 0 or col >= cols.size():
		push_warning("Start point col %d out of grid bounds." % col)
		return
	var tile_id: int = int(cols[col])
	var config := TileMapConfigManager.get_config(tile_id)
	if config and config.has_collision:
		push_warning("Start point at [%d, %d] has collision (tile: %s, id: %d)." % [col, row, config.display_name, tile_id])


func _spawn_end_point(world_pos: Vector2) -> void:
	var scene: PackedScene = load(END_POINT_SCENE_PATH)
	if scene == null:
		push_error("Failed to load end point scene: %s" % END_POINT_SCENE_PATH)
		return

	var instance := scene.instantiate()
	instance.position = world_pos
	instance.level_reached.connect(_on_level_reached)
	instance.add_to_group(GENERATED_GROUP)
	add_child(instance)


func _on_level_reached() -> void:
	var panel := get_node_or_null("../LevelCompletePanel")
	if panel and panel.has_method("show_panel"):
		panel.show_panel()
