extends Control

const MAIN_SCENE_PATH := "res://scenes/env/night_game_scene.tscn"

@onready var _menu_panel: Control = $MenuPanel
@onready var _credits_panel: Control = $CreditsPanel
@onready var _start_button: Button = $MenuPanel/CenterContainer/VBoxContainer/StartButton
@onready var _exit_button: Button = $MenuPanel/CenterContainer/VBoxContainer/ExitButton
@onready var _credits_button: Button = $MenuPanel/CenterContainer/VBoxContainer/CreditsButton
@onready var _credits_back_button: Button = $CreditsPanel/CenterContainer/VBoxContainer/BackButton


func _ready() -> void:
	_credits_panel.visible = false
	_start_button.pressed.connect(_on_start_pressed)
	_exit_button.pressed.connect(_on_exit_pressed)
	_credits_button.pressed.connect(_on_credits_pressed)
	_credits_back_button.pressed.connect(_on_credits_back_pressed)


func _on_start_pressed() -> void:
	LevelManager.start_level(0)
	get_tree().change_scene_to_file(MAIN_SCENE_PATH)


func _on_exit_pressed() -> void:
	get_tree().quit()


func _on_credits_pressed() -> void:
	_menu_panel.visible = false
	_credits_panel.visible = true


func _on_credits_back_pressed() -> void:
	_credits_panel.visible = false
	_menu_panel.visible = true
