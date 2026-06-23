class_name InteractPanel
extends PanelContainer

const InteractConfigData = preload("res://scripts/interact_config_data.gd")

signal action_pressed

@onready var _action_button: Button = $MarginContainer/CenterContainer/ActionButton


func _ready() -> void:
	visible = false
	_action_button.pressed.connect(_on_action_button_pressed)


func setup(interact: InteractConfigData) -> void:
	_action_button.text = interact.action_text
	_action_button.theme_type_variation = interact.button_variation

	if interact.action_icon != null:
		_action_button.icon = interact.action_icon
		_action_button.icon_alignment = HORIZONTAL_ALIGNMENT_LEFT
		_action_button.alignment = HORIZONTAL_ALIGNMENT_CENTER
	else:
		_action_button.icon = null
		_action_button.alignment = HORIZONTAL_ALIGNMENT_CENTER


func show_panel() -> void:
	visible = true


func hide_panel() -> void:
	visible = false


func set_interactable(enabled: bool) -> void:
	_action_button.disabled = not enabled


func _on_action_button_pressed() -> void:
	action_pressed.emit()
