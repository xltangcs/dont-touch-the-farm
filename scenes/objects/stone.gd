extends Node2D

@export var item_id: String = "stone"
@export var amount: int = 1

@onready var _collectable_component: Area2D = $CollectableComponent


func _ready() -> void:
	if _collectable_component.has_method("set_item"):
		_collectable_component.set_item(item_id, amount)
