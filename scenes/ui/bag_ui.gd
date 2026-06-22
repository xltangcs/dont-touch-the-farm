extends Control

@onready var _slot_container: HBoxContainer = $NinePatchRect/MarginContainer/HBoxContainer

var _inventory_manager: Node


func _ready() -> void:
	self_modulate = Color.WHITE
	_inventory_manager = get_node("/root/InventoryManager")
	_inventory_manager.inventory_changed.connect(_refresh_all_slots)
	_refresh_all_slots()


func _refresh_all_slots() -> void:
	for i in range(_slot_container.get_child_count()):
		var slot_button = _slot_container.get_child(i)
		var slot_data = _inventory_manager.get_slot(i)

		if slot_data == null or slot_data.item == null:
			slot_button.clear_slot()
			continue

		slot_button.set_item(slot_data.item, slot_data.item_count)
