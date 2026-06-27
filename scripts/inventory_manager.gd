extends Node

signal inventory_changed

const INVENTORY_SIZE: int = 12

var inventory: Inventory


func _ready() -> void:
	_initalize_inventory()


func _initalize_inventory() -> void:
	inventory = Inventory.new()
	for _i in range(INVENTORY_SIZE):
		inventory.inventory_slots.append(null)


func add_item(item_id: String, amount: int) -> bool:
	var item_data := _get_item_data(item_id)
	if item_data == null:
		push_warning("ItemData not found for item_id: %s" % item_id)
		return false

	var remaining := amount

	for slot in inventory.inventory_slots:
		if slot == null:
			continue
		if slot.item != null and slot.item.name == item_data.name and slot.item_count < item_data.max_stack:
			var can_add := mini(remaining, item_data.max_stack - slot.item_count)
			slot.item_count += can_add
			remaining -= can_add
			if remaining <= 0:
				inventory_changed.emit()
				return true

	if remaining <= 0:
		inventory_changed.emit()
		return true

	for i in range(inventory.inventory_slots.size()):
		if inventory.inventory_slots[i] == null:
			return _create_new_slot(i, item_data, remaining)

		if inventory.inventory_slots[i].item == null:
			return _create_new_slot(i, item_data, remaining)

	inventory_changed.emit()
	return false


func _create_new_slot(index: int, item_data: ItemData, remaining: int) -> bool:
	var slot := InventorySlot.new()
	slot.item = item_data
	slot.item_count = mini(remaining, item_data.max_stack)
	inventory.inventory_slots[index] = slot
	inventory_changed.emit()
	return true


func get_slot(index: int) -> InventorySlot:
	if index < 0 or index >= inventory.inventory_slots.size():
		return null
	return inventory.inventory_slots[index]


func get_item_count(item_id: String) -> int:
	var total := 0
	for slot in inventory.inventory_slots:
		if slot == null or slot.item == null:
			continue
		if _slot_matches_item_id(slot, item_id):
			total += slot.item_count
	return total


func remove_item(item_id: String, amount: int) -> bool:
	if amount <= 0:
		return true

	var item_data := _get_item_data(item_id)
	if item_data == null:
		push_warning("ItemData not found for item_id: %s" % item_id)
		return false

	if get_item_count(item_id) < amount:
		return false

	var remaining := amount
	for slot in inventory.inventory_slots:
		if remaining <= 0:
			break
		if slot == null or slot.item == null:
			continue
		if not _slot_matches_item_id(slot, item_id):
			continue

		var removed := mini(remaining, slot.item_count)
		slot.item_count -= removed
		remaining -= removed
		if slot.item_count <= 0:
			slot.item = null

	inventory_changed.emit()
	return remaining == 0


func _slot_matches_item_id(slot: InventorySlot, item_id: String) -> bool:
	var item_data := _get_item_data(item_id)
	if item_data == null or slot.item == null:
		return false
	return slot.item == item_data


func _get_item_data(item_id: String) -> ItemData:
	if not ResourceLoader.exists("res://scenes/items/%s.tres" % item_id):
		return null
	return load("res://scenes/items/%s.tres" % item_id)
