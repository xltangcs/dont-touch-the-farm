extends Area2D

@export var max_mine_count: int = 3
@export var resource_id: String = "stone"
@export var resource_amount: int = 1

var _remaining_mine_count: int = 0
var _player_in_range: bool = false

@onready var _button: Button = $Button


func _ready() -> void:
	_remaining_mine_count = max_mine_count
	_button.visible = false
	_update_button_text()


func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return

	_player_in_range = true
	_button.visible = true


func _on_body_exited(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return

	_player_in_range = false
	_button.visible = false


func _on_button_pressed() -> void:
	if _remaining_mine_count <= 0:
		return

	mine()


func mine() -> void:
	_remaining_mine_count -= 1
	_update_button_text()

	if _remaining_mine_count <= 0:
		queue_free()


func _update_button_text() -> void:
	_button.text = "mine (%d)" % _remaining_mine_count
