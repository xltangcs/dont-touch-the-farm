extends Node2D

@export var item_id: String = "stone"
@export var amount: int = 1
@export var pop_height: float = 12.0
@export var pop_up_duration: float = 0.12
@export var pop_down_duration: float = 0.16
@export var collect_delay: float = 0.1

@onready var _collectable_component: Area2D = $CollectableComponent


func _ready() -> void:
	add_to_group("dropped_item")
	if _collectable_component.has_method("set_item"):
		_collectable_component.set_item(item_id, amount)


func pop_to(target_position: Vector2) -> void:
	if _collectable_component.has_method("set_collectable"):
		_collectable_component.set_collectable(false)

	var mid_position := (global_position + target_position) * 0.5 + Vector2(0, -pop_height)
	scale = Vector2(0.8, 0.8)

	var total_duration := pop_up_duration + pop_down_duration
	var move_tween := create_tween()
	move_tween.tween_property(self, "global_position", mid_position, pop_up_duration)
	move_tween.tween_property(self, "global_position", target_position, pop_down_duration)

	var scale_tween := create_tween()
	scale_tween.tween_property(self, "scale", Vector2.ONE, total_duration)

	await move_tween.finished
	await get_tree().create_timer(collect_delay).timeout

	if _collectable_component.has_method("set_collectable"):
		_collectable_component.set_collectable(true)
