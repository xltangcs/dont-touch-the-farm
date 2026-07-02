@tool
extends Node2D

const RAIN_CELL_SCENE := preload("res://scenes/env/rain_zone_cell.tscn")

signal rain_stopped(zone_id: String)

var zone_id: String = ""
var _active: bool = true
var _cells: Array[Vector2i] = []


func _ready() -> void:
	if not has_meta("rain_zone_setup"):
		return
	var data: Dictionary = get_meta("rain_zone_setup")
	remove_meta("rain_zone_setup")
	setup(
		str(data.get("id", "")),
		data.get("cells", []),
		float(data.get("tile_size", 66.0)),
		data.get("origin", Vector2.ZERO),
		bool(data.get("active", true))
	)


func setup(id: String, cells: Array, tile_size: float, origin: Vector2, active: bool = true) -> void:
	zone_id = id
	_active = active
	_cells.clear()

	for cell in cells:
		if typeof(cell) != TYPE_ARRAY or cell.size() < 2:
			continue
		var col := int(cell[0])
		var row := int(cell[1])
		_cells.append(Vector2i(col, row))
		_spawn_cell(col, row, tile_size, origin)

	set_active(_active)
	if not Engine.is_editor_hint():
		RainManager.register_zone(self)


func _exit_tree() -> void:
	if Engine.is_editor_hint():
		return
	RainManager.unregister_zone(self)


func get_zone_id() -> String:
	return zone_id


func is_active() -> bool:
	return _active


func contains_cell(col: int, row: int) -> bool:
	return Vector2i(col, row) in _cells


func stop_rain() -> void:
	if not _active:
		return
	set_active(false)
	rain_stopped.emit(zone_id)


func set_active(active: bool) -> void:
	_active = active
	visible = active
	for child in get_children():
		if child.has_method("set_zone_active"):
			child.set_zone_active(active)
	_update_campfires(active)


func on_player_entered() -> void:
	if not _active:
		return

	var tree := get_tree()
	if tree == null:
		return

	var player := tree.get_first_node_in_group("player")
	if player and player.has_method("extinguish_torch"):
		player.extinguish_torch()


func _spawn_cell(col: int, row: int, tile_size: float, origin: Vector2) -> void:
	var cell := RAIN_CELL_SCENE.instantiate()
	cell.position = origin + Vector2(col * tile_size, row * tile_size)
	add_child(cell)
	cell.call_deferred("setup", self)


func _update_campfires(raining: bool) -> void:
	if Engine.is_editor_hint():
		return
	var tree := get_tree()
	if tree == null:
		return

	for campfire in tree.get_nodes_in_group("campfire"):
		if not campfire.has_method("set_raining"):
			continue
		var col: int = campfire.get_meta("grid_col", -1)
		var row: int = campfire.get_meta("grid_row", -1)
		if col < 0 or row < 0:
			continue
		if contains_cell(col, row):
			campfire.set_raining(raining)
