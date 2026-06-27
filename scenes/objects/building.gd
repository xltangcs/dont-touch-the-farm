extends Node2D

const BuildingConfigData = preload("res://scripts/building_config_data.gd")

@export var config_id: String = "small_shrine"

var _config: BuildingConfigData
var _player_in_range: bool = false
var _nearby_player: Node2D = null
var _interact_panel_home_parent: Node
var _interact_panel_home_position: Vector2

@onready var _sprite: Sprite2D = $Sprite2D
@onready var _interact_area: Area2D = $InteractArea
@onready var _interact_panel: InteractPanel = $InteractPanel


func _ready() -> void:
	_interact_panel_home_parent = _interact_panel.get_parent()
	_interact_panel_home_position = _interact_panel.position
	_interact_area.monitoring = true
	_apply_config()
	if _config != null:
		_interact_panel.setup(_config.get_interact_config())
	_hide_interact_panel()
	_interact_panel.action_pressed.connect(_on_interact_panel_action_pressed)
	call_deferred("_connect_game_ui")


func _process(_delta: float) -> void:
	if _interact_panel.visible and _is_interact_panel_mounted_on_ui():
		_update_interact_panel_screen_position()


func _connect_game_ui() -> void:
	var game_ui := _get_game_ui()
	if game_ui == null:
		return
	if not game_ui.building_production_closed.is_connected(_on_production_panel_closed):
		game_ui.building_production_closed.connect(_on_production_panel_closed)


func _on_production_panel_closed() -> void:
	if _player_in_range:
		_show_interact_panel()


func _apply_config() -> void:
	_config = BuildingConfigManager.get_config(config_id)
	if _config == null:
		push_warning("Building config not found: %s" % config_id)
		return

	if _config.building_texture != null:
		_sprite.texture = _config.building_texture


func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return

	_nearby_player = body
	_player_in_range = true
	if not _is_production_panel_open():
		_show_interact_panel()


func _on_body_exited(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return

	if _nearby_player == body:
		_nearby_player = null

	_player_in_range = false
	_hide_interact_panel()

	var game_ui := _get_game_ui()
	if game_ui != null and game_ui.is_building_production_open():
		game_ui.close_building_production()


func _on_interact_panel_action_pressed() -> void:
	if not _player_in_range:
		return

	var game_ui := _get_game_ui()
	if game_ui == null:
		push_warning("GameScreen not found.")
		return

	_hide_interact_panel()
	var opened := game_ui.open_building_production(config_id)
	if not opened:
		push_warning("BuildingProductionPanel failed to open for: %s" % config_id)
		_show_interact_panel()


func _unhandled_input(event: InputEvent) -> void:
	if not _player_in_range:
		return
	if _is_production_panel_open():
		return
	if event.is_action_pressed("interact"):
		_on_interact_panel_action_pressed()
		get_viewport().set_input_as_handled()


func _show_interact_panel() -> void:
	var game_ui := _get_game_ui()
	if game_ui != null and _interact_panel.get_parent() != game_ui:
		_interact_panel.reparent(game_ui)
		_interact_panel.top_level = true
	_update_interact_panel_screen_position()
	_interact_panel.show_panel()
	if game_ui != null and _interact_panel.get_parent() == game_ui:
		_interact_panel.move_to_front()


func _hide_interact_panel() -> void:
	_interact_panel.hide_panel()
	if _interact_panel.get_parent() != _interact_panel_home_parent:
		_interact_panel.reparent(_interact_panel_home_parent)
		_interact_panel.top_level = false
		_interact_panel.position = _interact_panel_home_position


func _is_interact_panel_mounted_on_ui() -> bool:
	var game_ui := _get_game_ui()
	return game_ui != null and _interact_panel.get_parent() == game_ui


func _update_interact_panel_screen_position() -> void:
	var world_pos := global_transform * _interact_panel_home_position
	_interact_panel.global_position = get_viewport().get_canvas_transform() * world_pos


func _get_game_ui() -> GameUi:
	var parent := get_parent()
	if parent != null:
		var screen := parent.get_node_or_null("GameScreen")
		if screen is GameUi:
			return screen

	var game_uis := get_tree().get_nodes_in_group("game_ui")
	for node in game_uis:
		if node is GameUi:
			return node
	return null


func _is_production_panel_open() -> bool:
	var game_ui := _get_game_ui()
	if game_ui == null:
		return false
	return game_ui.is_building_production_open()
