extends Button

@onready var _item_icon: TextureRect = $TextureRect/CenterContainer/slot_item/TextureRect
@onready var _quantity_label: Label = $TextureRect/CenterContainer/slot_item/Label


func _ready() -> void:
	pass


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
