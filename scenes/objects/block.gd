extends Area2D

const STONE_SCENE := preload("res://scenes/objects/stone.tscn")

@export var max_mine_count: int = 3
@export var resource_id: String = "stone"
@export var resource_amount: int = 1

var _remaining_mine_count: int = 0
var _stones_spawned: int = 0
var _player_in_range: bool = false
var _is_mining: bool = false
var _nearby_player: Node2D = null

@onready var _button: Button = $Button
@onready var _dropped_component: DroppedComponent = $DroppedComponent


func _ready() -> void:
	_remaining_mine_count = max_mine_count
	_button.visible = false
	_update_button_text()


func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return

	_nearby_player = body
	_player_in_range = true
	_button.visible = true


func _on_body_exited(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return

	if _nearby_player == body:
		_nearby_player = null

	_player_in_range = false
	_button.visible = false


func _on_button_pressed() -> void:
	if _remaining_mine_count <= 0 or _nearby_player == null or _is_mining:
		return

	_start_mining()


func _start_mining() -> void:
	_is_mining = true
	_button.disabled = true

	if _nearby_player.has_method("play_mine_toward"):
		await _nearby_player.play_mine_toward(global_position)

	mine()

	_is_mining = false
	if _remaining_mine_count > 0:
		_button.disabled = false


func mine() -> void:
	_remaining_mine_count -= 1
	_spawn_stone()
	_update_button_text()

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


func _update_button_text() -> void:
	_button.text = "mine (%d)" % _remaining_mine_count
