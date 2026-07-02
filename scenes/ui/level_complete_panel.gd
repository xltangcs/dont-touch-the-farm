extends CanvasLayer

const MAIN_MENU_SCENE_PATH := "res://scenes/ui/main_menu_scene.tscn"
const LEVEL_SELECT_SCENE_PATH := "res://scenes/ui/level_select_control.tscn"
const GAME_SCENE_PATH := "res://scenes/env/night_game_scene.tscn"

@onready var _next_button: Button = $PanelContainer/MarginContainer/VBoxContainer/HBoxContainer/NextButton


func _ready() -> void:
	visible = false
	$PanelContainer/MarginContainer/VBoxContainer/HBoxContainer/ReplayButton.pressed.connect(_on_replay_pressed)
	_next_button.pressed.connect(_on_next_pressed)
	$PanelContainer/MarginContainer/VBoxContainer/HBoxContainer/SelectLevelButton.pressed.connect(_on_select_level_pressed)
	$PanelContainer/MarginContainer/VBoxContainer/HBoxContainer/MainMenuButton.pressed.connect(_on_main_menu_pressed)


func show_panel() -> void:
	visible = true
	_next_button.disabled = not LevelManager.has_next_level()
	get_tree().paused = true


func _hide_panel() -> void:
	get_tree().paused = false


func _on_replay_pressed() -> void:
	_hide_panel()
	LevelManager.restart_current_level()
	get_tree().change_scene_to_file(GAME_SCENE_PATH)


func _on_next_pressed() -> void:
	_hide_panel()
	LevelManager.next_level()
	get_tree().change_scene_to_file(GAME_SCENE_PATH)


func _on_select_level_pressed() -> void:
	_hide_panel()
	get_tree().change_scene_to_file(LEVEL_SELECT_SCENE_PATH)


func _on_main_menu_pressed() -> void:
	_hide_panel()
	get_tree().change_scene_to_file(MAIN_MENU_SCENE_PATH)
