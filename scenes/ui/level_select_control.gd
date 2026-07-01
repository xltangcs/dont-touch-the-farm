extends Control

const MAIN_MENU_SCENE_PATH := "res://scenes/ui/main_menu_scene.tscn"
const MAIN_SCENE_PATH := "res://scenes/env/night_game_scene.tscn"
const MAX_COLUMNS := 6

@onready var _grid_container: GridContainer = $CenterContainer/VBoxContainer/MarginContainer/GridContainer
@onready var _back_button: Button = $CenterContainer/VBoxContainer/BackButton


func _ready() -> void:
	_back_button.pressed.connect(_on_back_pressed)
	_create_level_buttons()


func _create_level_buttons() -> void:
	var total := LevelManager.get_total_levels()
	for i in range(total):
		var name := LevelManager.get_level_name(i)
		var button := Button.new()
		button.custom_minimum_size = Vector2(180, 56)
		button.text = name
		button.add_theme_font_size_override("font_size", 22)
		button.pressed.connect(_on_level_pressed.bind(i))
		_grid_container.add_child(button)


func _on_level_pressed(index: int) -> void:
	LevelManager.start_level(index)
	get_tree().change_scene_to_file(MAIN_SCENE_PATH)


func _on_back_pressed() -> void:
	get_tree().change_scene_to_file(MAIN_MENU_SCENE_PATH)
