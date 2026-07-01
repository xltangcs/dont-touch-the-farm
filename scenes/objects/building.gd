extends Node2D

const BuildingConfigData = preload("res://scripts/building_config_data.gd")

@export var config_id: String = "small_shrine"

var _config: BuildingConfigData
var _player_in_range: bool = false
var _nearby_player: Node2D = null

@onready var _sprite: Sprite2D = $Sprite2D
@onready var _interact_area: Area2D = $InteractArea
@onready var _interact_panel: InteractPanel = $InteractPanel


func _ready() -> void:
	_interact_area.monitoring = true
	_apply_config()
	if _config != null:
		_interact_panel.setup(_config.get_interact_config())
	_interact_panel.hide_panel()
	_interact_panel.action_pressed.connect(_on_interact_panel_action_pressed)


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
	_interact_panel.show_panel()


func _on_body_exited(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return

	if _nearby_player == body:
		_nearby_player = null

	_player_in_range = false
	_interact_panel.hide_panel()


func _on_interact_panel_action_pressed() -> void:
	if not _player_in_range:
		return

	push_warning("Building interaction is not available: %s" % config_id)


func _unhandled_input(event: InputEvent) -> void:
	if not _player_in_range:
		return
	if event.is_action_pressed("interact"):
		_on_interact_panel_action_pressed()
		get_viewport().set_input_as_handled()
