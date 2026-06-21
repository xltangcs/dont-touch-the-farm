class_name BlockInteractPanel
extends PanelContainer

signal action_pressed

@export var mine_text: String = "mine"
@export var restricted_text: String = "mine?"

const MINE_BUTTON_VARIATION := &"BlockMineButton"
const RESTRICTED_BUTTON_VARIATION := &"BlockRestrictedMineButton"

@onready var _action_button: Button = $MarginContainer/HBoxContainer/ActionButton


func _ready() -> void:
	visible = false
	_action_button.pressed.connect(_on_action_button_pressed)


func setup(resource_icon: Texture2D, requires_force_mining: bool) -> void:
	if resource_icon != null:
		_action_button.icon = resource_icon

	if requires_force_mining:
		_action_button.text = restricted_text
		_action_button.theme_type_variation = RESTRICTED_BUTTON_VARIATION
	else:
		_action_button.text = mine_text
		_action_button.theme_type_variation = MINE_BUTTON_VARIATION


func show_panel() -> void:
	visible = true


func hide_panel() -> void:
	visible = false


func set_interactable(enabled: bool) -> void:
	_action_button.disabled = not enabled


func _on_action_button_pressed() -> void:
	action_pressed.emit()
