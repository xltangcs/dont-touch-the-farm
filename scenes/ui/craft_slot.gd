class_name CraftInputSlot
extends Control

signal slot_clicked(slot_index: int)

var slot_index: int = -1
var item_id: String = ""
var count: int = 0

@onready var _action_button: Button = $Button
@onready var _item_icon: TextureRect = $Button/TextureRect/TextureRect
@onready var _quantity_label: Label = $Button/TextureRect/Label


func _ready() -> void:
	_item_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_item_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_item_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_quantity_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_action_button.pressed.connect(_on_button_pressed)
	clear()


func setup(index: int) -> void:
	slot_index = index


func set_item(new_item_id: String, new_count: int) -> void:
	if new_item_id.is_empty() or new_count <= 0:
		clear()
		return

	var item_data := _load_item_data(new_item_id)
	if item_data == null:
		push_warning("CraftInputSlot: item not found: %s" % new_item_id)
		clear()
		return

	item_id = new_item_id
	count = new_count
	_item_icon.texture = item_data.texture
	_item_icon.visible = true
	_quantity_label.text = str(count)
	_quantity_label.visible = count > 1


func clear() -> void:
	item_id = ""
	count = 0
	_item_icon.texture = null
	_item_icon.visible = false
	_quantity_label.text = ""
	_quantity_label.visible = false


func is_empty() -> bool:
	return item_id.is_empty() or count <= 0


func get_item_id() -> String:
	return item_id


func get_count() -> int:
	return count


func _on_button_pressed() -> void:
	slot_clicked.emit(slot_index)


func _load_item_data(id: String) -> ItemData:
	var path := "res://scenes/items/%s.tres" % id
	if not ResourceLoader.exists(path):
		return null
	return load(path) as ItemData
