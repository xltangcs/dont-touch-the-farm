class_name GameUi
extends CanvasLayer

@onready var _disabled_key_panel: PanelContainer = $DisableKeyControl/DisabledKeyPanel
@onready var _disabled_key_label: Label = $DisableKeyControl/DisabledKeyPanel/MarginContainer/Label


func _ready() -> void:
	add_to_group("game_ui")
	_disabled_key_panel.visible = false


func set_disabled_key(key_label: String) -> void:
	if key_label.is_empty():
		_disabled_key_panel.visible = false
		return

	_disabled_key_label.text = "禁用按键：%s" % key_label
	_disabled_key_panel.visible = true
