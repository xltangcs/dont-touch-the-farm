class_name DialogueUi
extends Control

signal dialogue_started
signal dialogue_ended
signal choice_selected(choice_index: int)

@export var text_speed: float = 0.03
@export var auto_advance_delay: float = 0.0
@export var player_portrait: Texture2D

@onready var _panel: Panel = $DialoguePanel
@onready var _portrait: TextureRect = $DialoguePanel/MarginContainer/HBoxContainer/Portrait
@onready var _player_portrait: TextureRect = $DialoguePanel/MarginContainer/HBoxContainer/PlayerPortrait
@onready var _name_label: Label = $DialoguePanel/MarginContainer/HBoxContainer/TextArea/NameLabel
@onready var _text_label: RichTextLabel = $DialoguePanel/MarginContainer/HBoxContainer/TextArea/TextLabel
@onready var _choice_container: Control = $DialoguePanel/MarginContainer/HBoxContainer/TextArea/ChoiceContainer

var is_active: bool = false

var _current_node: DialogueNode
var _current_choices: Array[DialogueChoice] = []
var _tween: Tween
var _is_typing: bool = false


func _ready() -> void:
	visible = false
	_panel.modulate.a = 0.0


func show_dialogue(node: DialogueNode, choices: Array[DialogueChoice] = []) -> void:
	if is_active:
		push_warning("DialogueUi: dialogue already active")
		return
	is_active = true

	if _tween and _tween.is_valid():
		_tween.kill()
	_clear_choice_buttons()

	_current_node = node
	_current_choices = choices
	_text_label.clear()
	
	var was_visible := visible
	visible = true

	if not was_visible:
		dialogue_started.emit()
		_panel.modulate.a = 0.0
		var tween := create_tween()
		tween.set_ease(Tween.EASE_OUT)
		tween.set_trans(Tween.TRANS_CUBIC)
		tween.tween_property(_panel, "modulate:a", 1.0, 0.25)
		await tween.finished

	_text_label.text = ""
	_apply_player_portrait()
	_show_current_line()


func _show_current_line() -> void:
	_name_label.text = _current_node.speaker

	if _current_node.portrait != null:
		_portrait.texture = _current_node.portrait
		_portrait.visible = true
	else:
		_portrait.visible = false

	_type_text(_current_node.text)


func _type_text(text: String) -> void:
	if _tween and _tween.is_valid():
		_tween.kill()

	_is_typing = true
	_text_label.text = text
	_text_label.visible_characters = 0

	_tween = create_tween()
	_tween.tween_property(
		_text_label,
		"visible_characters",
		_text_label.get_total_character_count(),
		float(_text_label.get_total_character_count()) * text_speed
	).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_LINEAR)
	_tween.tween_callback(func(): _is_typing = false; _on_typing_complete())


func _on_typing_complete() -> void:
	if _current_choices.size() > 0:
		_show_choice_buttons()


func _input(event: InputEvent) -> void:
	if not visible or _panel.modulate.a < 1.0:
		return

	if _current_choices.size() > 0:
		return

	if event.is_action_pressed("ui_accept") or (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT):
		_handle_advance()
		get_viewport().set_input_as_handled()


func _handle_advance() -> void:
	if _is_typing:
		_skip_typing()
	# else: Component handles traversal via advance_requested (Task 11)


func _skip_typing() -> void:
	if _tween and _tween.is_valid():
		_tween.kill()
	_text_label.visible_characters = -1
	_is_typing = false
	_on_typing_complete()


func _show_choice_buttons() -> void:
	_clear_choice_buttons()

	print("DialogueUi: showing %d choices" % _current_choices.size())

	for i in range(_current_choices.size()):
		var btn := Button.new()
		btn.text = _current_choices[i].text
		btn.pressed.connect(_on_choice_pressed.bind(i))
		_choice_container.add_child(btn)


func _clear_choice_buttons() -> void:
	for child in _choice_container.get_children():
		child.queue_free()


func _on_choice_pressed(index: int) -> void:
	_clear_choice_buttons()
	_current_choices.clear()
	_text_label.text = ""
	choice_selected.emit(index)


func hide_dialogue() -> void:
	var tween := create_tween()
	tween.set_ease(Tween.EASE_IN)
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(_panel, "modulate:a", 0.0, 0.2)
	await tween.finished

	visible = false
	is_active = false
	_current_choices.clear()
	dialogue_ended.emit()


func force_hide() -> void:
	if not is_active:
		return
	if _tween and _tween.is_valid():
		_tween.kill()
	_panel.modulate.a = 0.0
	visible = false
	is_active = false
	_current_choices.clear()
	_text_label.text = ""
	dialogue_ended.emit()


func _apply_player_portrait() -> void:
	if player_portrait != null:
		_player_portrait.texture = player_portrait
		_player_portrait.visible = true
	else:
		_player_portrait.visible = false
