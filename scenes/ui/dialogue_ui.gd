class_name DialogueUi
extends Control

signal dialogue_started
signal dialogue_ended
signal line_changed(line_index: int)
signal choice_selected(choice_index: int)

@export var text_speed: float = 0.03
@export var auto_advance_delay: float = 0.0
@export var player_portrait: Texture2D

@onready var _panel: Panel = $DialoguePanel
@onready var _portrait: TextureRect = $DialoguePanel/MarginContainer/HBoxContainer/Portrait
@onready var _player_portrait: TextureRect = $DialoguePanel/MarginContainer/HBoxContainer/PlayerPortrait
@onready var _name_label: Label = $DialoguePanel/MarginContainer/HBoxContainer/TextArea/NameLabel
@onready var _text_label: RichTextLabel = $DialoguePanel/MarginContainer/HBoxContainer/TextArea/TextLabel
@onready var _choice_btn1: Button = $DialoguePanel/MarginContainer/HBoxContainer/TextArea/ChoiceContainer/ChoiceBtn1
@onready var _choice_btn2: Button = $DialoguePanel/MarginContainer/HBoxContainer/TextArea/ChoiceContainer/ChoiceBtn2

var _lines: Array[DialogueLine] = []
var _current_index: int = 0
var _tween: Tween
var _is_typing: bool = false
var _choices: Array[String] = []
var _has_choices: bool = false


func _ready() -> void:
	visible = false
	_panel.modulate.a = 0.0

	if _choice_btn1 == null:
		push_error("DialogueUi: ChoiceBtn1 not found — check scene node path")
	if _choice_btn2 == null:
		push_error("DialogueUi: ChoiceBtn2 not found — check scene node path")


func show_dialogue(lines: Array[DialogueLine]) -> void:
	if _tween and _tween.is_valid():
		_tween.kill()
	_clear_choice_buttons()

	_lines = lines
	_current_index = 0
	_choices.clear()
	_has_choices = false
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


func show_dialogue_with_choices(lines: Array[DialogueLine], choices: Array[String]) -> void:
	if _tween and _tween.is_valid():
		_tween.kill()
	_clear_choice_buttons()

	_lines = lines
	_current_index = 0
	_choices = choices
	_has_choices = true
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
	if _current_index >= _lines.size():
		if _has_choices:
			_show_choice_buttons()
		else:
			hide_dialogue()
		return

	var line: DialogueLine = _lines[_current_index]
	_name_label.text = line.speaker_name

	if line.portrait != null:
		_portrait.texture = line.portrait
		_portrait.visible = true
	else:
		_portrait.visible = false

	_type_text(line.text)
	line_changed.emit(_current_index)


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
		text.length(),
		float(text.length()) * text_speed
	).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_LINEAR)
	_tween.tween_callback(func(): _is_typing = false)

	if auto_advance_delay > 0.0:
		_tween.tween_callback(_advance).set_delay(auto_advance_delay)


func _input(event: InputEvent) -> void:
	if not visible or _panel.modulate.a < 1.0:
		return

	if _choice_btn1.visible or _choice_btn2.visible:
		return

	if event.is_action_pressed("ui_accept") or (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT):
		_handle_advance()
		get_viewport().set_input_as_handled()


func _handle_advance() -> void:
	if _is_typing:
		_skip_typing()
	else:
		_advance()


func _skip_typing() -> void:
	if _tween and _tween.is_valid():
		_tween.kill()
	_text_label.visible_characters = -1
	_is_typing = false


func _advance() -> void:
	_current_index += 1
	_show_current_line()


func _show_choice_buttons() -> void:
	_clear_choice_buttons()

	print("DialogueUi: showing %d choices" % _choices.size())

	for i in range(_choices.size()):
		var btn: Button
		match i:
			0: btn = _choice_btn1
			1: btn = _choice_btn2
			_: continue

		if btn == null:
			push_error("DialogueUi: choice button %d is null" % i)
			continue

		btn.text = _choices[i]
		btn.visible = true
		if not btn.pressed.is_connected(_on_choice_pressed):
			btn.pressed.connect(_on_choice_pressed.bind(i))


func _clear_choice_buttons() -> void:
	_choice_btn1.visible = false
	_choice_btn2.visible = false


func _on_choice_pressed(index: int) -> void:
	_clear_choice_buttons()
	_has_choices = false
	_text_label.text = ""
	choice_selected.emit(index)
	# Don't hide — caller handles next dialogue transition


func hide_dialogue() -> void:
	var tween := create_tween()
	tween.set_ease(Tween.EASE_IN)
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(_panel, "modulate:a", 0.0, 0.2)
	await tween.finished

	visible = false
	_lines.clear()
	_choices.clear()
	_has_choices = false
	dialogue_ended.emit()


func _apply_player_portrait() -> void:
	if player_portrait != null:
		_player_portrait.texture = player_portrait
		_player_portrait.visible = true
	else:
		_player_portrait.visible = false
