extends Area2D

const STONE_SCENE := preload("res://scenes/objects/stone.tscn")
const BlockConfigData = preload("res://scripts/block_config_data.gd")

@export var config_id: String = "normal_stone_block"

var max_mine_count: int = 3
var resource_id: String = "stone"
var resource_amount: int = 1
var requires_force_mining: bool = false
var debuff_id: String = ""

var _config: BlockConfigData

var _remaining_mine_count: int = 0
var _stones_spawned: int = 0
var _player_in_range: bool = false
var _is_mining: bool = false
var _nearby_player: Node2D = null

@onready var _sprite: Sprite2D = $Sprite2D
@onready var _dropped_component: DroppedComponent = $DroppedComponent
@onready var _interact_panel: InteractPanel = $InteractPanel


func _ready() -> void:
	_apply_config()
	_remaining_mine_count = max_mine_count
	if _config != null:
		_interact_panel.setup(_config.get_interact_config())
	_interact_panel.hide_panel()
	_interact_panel.action_pressed.connect(_on_interact_panel_action_pressed)


func _apply_config() -> void:
	_config = BlockConfigManager.get_config(config_id)
	if _config == null:
		push_warning("Block config not found: %s" % config_id)
		return

	max_mine_count = _config.max_mine_count
	resource_id = _config.resource_id
	resource_amount = _config.resource_amount
	requires_force_mining = _config.requires_force_mining
	debuff_id = _config.debuff_id

	if _config.block_texture != null:
		_sprite.texture = _config.block_texture


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
	if _remaining_mine_count <= 0 or _nearby_player == null or _is_mining:
		return

	if requires_force_mining:
		await _request_force_mine_confirmation()
		return

	_start_mining()


func _request_force_mine_confirmation() -> void:
	var game_ui := get_tree().get_first_node_in_group("game_ui")
	if game_ui == null:
		push_warning("GameScreen not found.")
		return

	_interact_panel.set_interactable(false)

	var confirmed: bool = await game_ui.request_force_mine_confirmation(
		resource_id,
		resource_amount,
		debuff_id
	)

	if _remaining_mine_count > 0:
		_interact_panel.set_interactable(true)

	if not confirmed:
		return

	_start_mining()


func _start_mining() -> void:
	_is_mining = true
	_interact_panel.set_interactable(false)

	if _nearby_player.has_method("play_mine_toward"):
		await _nearby_player.play_mine_toward(global_position)

	mine()

	_is_mining = false
	if _remaining_mine_count > 0:
		_interact_panel.set_interactable(true)


func mine() -> void:
	_remaining_mine_count -= 1
	_spawn_stone()

	if _remaining_mine_count <= 0:
		queue_free()


func _spawn_stone() -> void:
	var target_position := _dropped_component.get_spawn_position_for_index(
		_stones_spawned,
		max_mine_count
	)
	_stones_spawned += 1

	var stone: Node2D = STONE_SCENE.instantiate()
	stone.item_id = resource_id
	stone.amount = resource_amount
	get_tree().current_scene.add_child(stone)
	stone.global_position = global_position
	stone.pop_to(target_position)
