class_name BuildingProductionPanel
extends PanelContainer

const BuildingConfigData = preload("res://scripts/building_config_data.gd")
const BuildingRecipeData = preload("res://scripts/building_recipe_data.gd")
const BuildingRecipeInputData = preload("res://scripts/building_recipe_input_data.gd")

signal closed

@onready var _product_name_label: Label = $MarginContainer/VBoxContainer/HBoxContainer/ProductBox/ProductNameLabel
@onready var _product_icon: TextureRect = $MarginContainer/VBoxContainer/HBoxContainer/ProductBox/ProductIcon
@onready var _description_label: Label = $MarginContainer/VBoxContainer/HBoxContainer/ProductBox/DescriptionLabel
@onready var _input_slots_container: HBoxContainer = $MarginContainer/VBoxContainer/HBoxContainer/CraftBox/InputSlots
@onready var _fill_button: Button = $MarginContainer/VBoxContainer/HBoxContainer/CraftBox/HBoxContainer/FillButton
@onready var _produce_button: Button = $MarginContainer/VBoxContainer/HBoxContainer/CraftBox/HBoxContainer/ProduceButton
@onready var _close_button: Button = $MarginContainer/VBoxContainer/CloseButtonRow/CloseButton

var _building_config: BuildingConfigData
var _input_buffer: Array = []
var _craft_slots: Array = []
var _inventory_manager: Node
var _player: Node2D


func _ready() -> void:
	visible = false
	_inventory_manager = get_node("/root/InventoryManager")
	_close_button.pressed.connect(close)
	_fill_button.pressed.connect(_on_fill_pressed)
	_produce_button.pressed.connect(_on_produce_pressed)
	_produce_button.disabled = true
	_input_buffer.resize(3)
	_init_craft_slots()


func is_open() -> bool:
	return visible


func open(building_id: String) -> bool:
	_building_config = BuildingConfigManager.get_config(building_id)
	if _building_config == null:
		push_warning("BuildingProductionPanel: config not found: %s" % building_id)
		return false
	if not _building_config.has_recipe():
		push_warning("BuildingProductionPanel: no recipe for: %s" % building_id)
		return false

	_cache_player()
	_clear_input_buffer()
	_show_recipe()
	_set_player_input_enabled(false)
	visible = true
	return true


func close() -> void:
	if not visible:
		return

	_return_all_inputs_to_inventory()
	_set_player_input_enabled(true)
	visible = false
	closed.emit()


func try_take_from_inventory(item_id: String, amount: int = 1) -> bool:
	if not visible or amount <= 0:
		return false
	if not _inventory_manager.remove_item(item_id, amount):
		return false
	return _add_to_input_buffer(item_id, amount)


func _init_craft_slots() -> void:
	_craft_slots.clear()
	for i in range(_input_slots_container.get_child_count()):
		var slot := _input_slots_container.get_child(i) as CraftInputSlot
		if slot == null:
			continue
		slot.setup(i)
		slot.slot_clicked.connect(_on_craft_slot_clicked)
		_craft_slots.append(slot)


func _show_recipe() -> void:
	var recipe := _building_config.get_recipe()
	if recipe == null:
		return

	_product_name_label.text = recipe.display_name
	_product_icon.texture = recipe.product_texture
	if recipe.description.is_empty():
		_description_label.text = recipe.get_inputs_summary()
	else:
		_description_label.text = recipe.description
	_refresh_produce_button()


func _clear_input_buffer() -> void:
	for i in range(_input_buffer.size()):
		_input_buffer[i] = null
	_refresh_all_slot_displays()


func _refresh_all_slot_displays() -> void:
	for i in range(_craft_slots.size()):
		_sync_slot_display(i)


func _sync_slot_display(index: int) -> void:
	var entry = _input_buffer[index]
	if entry == null:
		_craft_slots[index].clear()
	else:
		_craft_slots[index].set_item(entry.item_id, entry.count)


func _add_to_input_buffer(item_id: String, amount: int) -> bool:
	if amount <= 0:
		return false

	for i in range(_input_buffer.size()):
		var entry = _input_buffer[i]
		if entry != null and entry.item_id == item_id:
			entry.count += amount
			_sync_slot_display(i)
			_refresh_produce_button()
			return true

	for i in range(_input_buffer.size()):
		if _input_buffer[i] == null:
			_input_buffer[i] = {"item_id": item_id, "count": amount}
			_sync_slot_display(i)
			_refresh_produce_button()
			return true

	_inventory_manager.add_item(item_id, amount)
	return false


func _on_craft_slot_clicked(index: int) -> void:
	var entry = _input_buffer[index]
	if entry == null:
		return

	_inventory_manager.add_item(entry.item_id, entry.count)
	_input_buffer[index] = null
	_craft_slots[index].clear()
	_refresh_produce_button()


func _return_all_inputs_to_inventory() -> void:
	for i in range(_input_buffer.size()):
		var entry = _input_buffer[i]
		if entry == null:
			continue
		_inventory_manager.add_item(entry.item_id, entry.count)
		_input_buffer[i] = null
	_refresh_all_slot_displays()


func _get_buffer_totals() -> Dictionary:
	var totals := {}
	for entry in _input_buffer:
		if entry == null:
			continue
		totals[entry.item_id] = totals.get(entry.item_id, 0) + entry.count
	return totals


func _can_produce() -> bool:
	var recipe := _building_config.get_recipe()
	if recipe == null:
		return false

	var totals := _get_buffer_totals()
	for input in recipe.inputs:
		if input is BuildingRecipeInputData:
			var recipe_input := input as BuildingRecipeInputData
			if int(totals.get(recipe_input.item_id, 0)) < recipe_input.amount:
				return false
	return true


func _refresh_produce_button() -> void:
	_produce_button.disabled = not _can_produce()


func _on_fill_pressed() -> void:
	var recipe := _building_config.get_recipe()
	if recipe == null:
		return

	var totals := _get_buffer_totals()
	for input in recipe.inputs:
		if not input is BuildingRecipeInputData:
			continue

		var recipe_input := input as BuildingRecipeInputData
		var current_amount := int(totals.get(recipe_input.item_id, 0))
		var missing_amount := recipe_input.amount - current_amount
		if missing_amount <= 0:
			continue

		var available_amount: int = _inventory_manager.get_item_count(recipe_input.item_id)
		var fill_amount: int = mini(missing_amount, available_amount)
		if fill_amount <= 0:
			continue

		if try_take_from_inventory(recipe_input.item_id, fill_amount):
			totals[recipe_input.item_id] = current_amount + fill_amount

	_refresh_all_slot_displays()
	_refresh_produce_button()


func _on_produce_pressed() -> void:
	if not _can_produce():
		return

	var recipe := _building_config.get_recipe()
	if recipe == null:
		return

	_consume_for_recipe(recipe)
	_inventory_manager.add_item(recipe.output_id, recipe.output_amount)
	_refresh_all_slot_displays()
	_refresh_produce_button()


func _consume_for_recipe(recipe: BuildingRecipeData) -> void:
	for input in recipe.inputs:
		if not input is BuildingRecipeInputData:
			continue

		var recipe_input := input as BuildingRecipeInputData
		var remaining := recipe_input.amount
		for i in range(_input_buffer.size()):
			if remaining <= 0:
				break

			var entry = _input_buffer[i]
			if entry == null or entry.item_id != recipe_input.item_id:
				continue

			var used := mini(entry.count, remaining)
			entry.count -= used
			remaining -= used
			if entry.count <= 0:
				_input_buffer[i] = null
			_sync_slot_display(i)


func _cache_player() -> void:
	var players := get_tree().get_nodes_in_group("player")
	if players.is_empty():
		_player = null
		return
	_player = players[0]


func _set_player_input_enabled(enabled: bool) -> void:
	if not is_instance_valid(_player):
		return
	if _player.has_method("set_input_enabled"):
		_player.set_input_enabled(enabled)


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("ui_cancel"):
		close()
		get_viewport().set_input_as_handled()
