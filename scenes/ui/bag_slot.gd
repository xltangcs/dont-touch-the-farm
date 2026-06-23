extends Control

@onready var _item_icon: TextureRect = $Button/TextureRect/TextureRect
@onready var _quantity_label: Label = $Button/TextureRect/Label


func _ready() -> void:
	_item_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_item_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED


func set_item(item_data: ItemData, count: int) -> void:
	_item_icon.texture = item_data.texture
	_item_icon.visible = true
	_quantity_label.text = str(count)
	_quantity_label.visible = count > 1


func clear_slot() -> void:
	_item_icon.texture = null
	_item_icon.visible = false
	_quantity_label.text = ""
	_quantity_label.visible = false
