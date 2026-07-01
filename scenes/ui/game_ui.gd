class_name GameUi
extends CanvasLayer

signal building_production_closed
signal building_production_opened

@onready var _force_mine_panel: ForceMinePanel = $CenterContainer/ForceMinePanel
@onready var _building_production_panel: BuildingProductionPanel = $CenterContainer/BuildingProductionPanel
@onready var _bag_ui: Control = $BagUi
@onready var _disabled_key_panel: PanelContainer = $DisabledKeyPanel
@onready var _disabled_key_label: Label = $DisabledKeyPanel/MarginContainer/Label


func _ready() -> void:
	add_to_group("game_ui")
	_building_production_panel.closed.connect(_on_building_production_closed)
	_bag_ui.inventory_slot_clicked.connect(_on_bag_inventory_slot_clicked)
	_disabled_key_panel.visible = false


func set_disabled_key(key_label: String) -> void:
	if key_label.is_empty():
		_disabled_key_panel.visible = false
		return

	_disabled_key_label.text = "禁用按键：%s" % key_label
	_disabled_key_panel.visible = true


func request_force_mine_confirmation(
	resource_id: String,
	resource_amount: int,
	debuff_id: String
) -> bool:
	return await _force_mine_panel.show_and_wait(resource_id, resource_amount, debuff_id)


func open_building_production(building_id: String) -> bool:
	var opened := _building_production_panel.open(building_id)
	if opened:
		building_production_opened.emit()
	return opened


func close_building_production() -> void:
	_building_production_panel.close()


func is_building_production_open() -> bool:
	return _building_production_panel.is_open()


func _on_bag_inventory_slot_clicked(inventory_index: int) -> void:
	if not _building_production_panel.is_open():
		return

	var slot := InventoryManager.get_slot(inventory_index)
	if slot == null or slot.item == null:
		return

	var item_id := slot.item.item_id
	if item_id.is_empty():
		return

	_building_production_panel.try_take_from_inventory(item_id, 1)


func _on_building_production_closed() -> void:
	building_production_closed.emit()
