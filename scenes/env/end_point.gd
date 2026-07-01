extends Node2D

const PLAYER_LAYER := 4

signal level_reached

@onready var _area: Area2D = $Area2D


func _ready() -> void:
	if Engine.is_editor_hint():
		return

	_area.collision_layer = 0
	_area.collision_mask = PLAYER_LAYER
	_area.body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return

	_area.set_deferred("monitoring", false)
	level_reached.emit()
