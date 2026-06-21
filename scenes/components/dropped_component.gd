class_name DroppedComponent
extends Area2D

@export var spawn_on_edge: bool = false
@export_range(0.0, 1.0, 0.05) var spawn_radius_ratio: float = 0.85

@onready var _collision_shape: CollisionShape2D = $CollisionShape2D


func _ready() -> void:
	monitoring = false
	monitorable = false


func get_spawn_position_for_index(index: int, total: int) -> Vector2:
	if total <= 0:
		return global_position

	var circle := _collision_shape.shape as CircleShape2D
	if circle == null:
		return global_position

	var radius := circle.radius if spawn_on_edge else circle.radius * spawn_radius_ratio
	var angle := TAU * float(index) / float(total) - PI * 0.5
	angle += randf_range(-0.25, 0.25)
	return global_position + Vector2.RIGHT.rotated(angle) * radius
