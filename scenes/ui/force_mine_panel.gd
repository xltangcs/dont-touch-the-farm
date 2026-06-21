class_name ForceMinePanel
extends PanelContainer

signal dialog_completed(confirmed: bool)

@onready var _message_label: Label = $MarginContainer/VBoxContainer/MessageLabel
@onready var _confirm_button: Button = $MarginContainer/VBoxContainer/HBoxContainer/ConfirmButton
@onready var _cancel_button: Button = $MarginContainer/VBoxContainer/HBoxContainer/CancelButton

var _is_waiting: bool = false


func _ready() -> void:
	visible = false
	_confirm_button.pressed.connect(_on_confirm_pressed)
	_cancel_button.pressed.connect(_on_cancel_pressed)


func setup(resource_id: String, resource_amount: int, debuff_id: String) -> void:
	_message_label.text = (
		"开采此地块可获得资源 %s x%d\n但是会获得 debuff：%s\n是否强行开采？"
		% [resource_id, resource_amount, debuff_id]
	)


func show_and_wait(resource_id: String, resource_amount: int, debuff_id: String) -> bool:
	if _is_waiting:
		return false

	setup(resource_id, resource_amount, debuff_id)
	_is_waiting = true
	visible = true

	var confirmed: bool = await dialog_completed
	visible = false
	_is_waiting = false
	return confirmed


func _on_confirm_pressed() -> void:
	if not _is_waiting:
		return

	dialog_completed.emit(true)


func _on_cancel_pressed() -> void:
	if not _is_waiting:
		return

	dialog_completed.emit(false)
