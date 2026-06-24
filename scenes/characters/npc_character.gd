extends Node2D

@export var npc_name: String = "NPC"
@export var npc_portrait: Texture2D
@export var quest_item_name: String = "石头"
@export var quest_amount: int = 87

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision_shape_2d: CollisionShape2D = $CollisionShape2D/CollisionShape2D
@onready var _interaction_area: Area2D = $CollisionShape2D

var _player_in_range: bool = false
var _dialogue_ui: DialogueUi
var _talk_prompt: Button


func _ready() -> void:
	animated_sprite_2d.play("idle")

	_interaction_area.body_entered.connect(_on_body_entered)
	_interaction_area.body_exited.connect(_on_body_exited)

	var game_screen := _find_game_screen()
	if game_screen != null:
		_dialogue_ui = game_screen.get_node_or_null("DialogueUi") as DialogueUi
		_talk_prompt = game_screen.get_node_or_null("TalkPrompt") as Button

	if _dialogue_ui != null:
		_dialogue_ui.dialogue_ended.connect(_on_dialogue_ended)


func _find_game_screen() -> CanvasLayer:
	var game_uis := get_tree().get_nodes_in_group("game_ui")
	if game_uis.size() > 0:
		return game_uis[0] as CanvasLayer
	return null


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		_player_in_range = true
		_show_talk_prompt()


func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		_player_in_range = false
		_hide_talk_prompt()


func _on_dialogue_ended() -> void:
	if _player_in_range:
		_show_talk_prompt()


func _show_talk_prompt() -> void:
	if _talk_prompt == null:
		return
	if _dialogue_ui != null and _dialogue_ui.visible:
		return

	_talk_prompt.visible = true
	if not _talk_prompt.pressed.is_connected(_on_talk_pressed):
		_talk_prompt.pressed.connect(_on_talk_pressed)


func _hide_talk_prompt() -> void:
	if _talk_prompt == null:
		return

	_talk_prompt.visible = false
	if _talk_prompt.pressed.is_connected(_on_talk_pressed):
		_talk_prompt.pressed.disconnect(_on_talk_pressed)


func _on_talk_pressed() -> void:
	_hide_talk_prompt()
	_start_dialogue()


func _start_dialogue() -> void:
	var question := "你带来了我想要的%d个%s吗？" % [quest_amount, quest_item_name]

	var lines: Array[DialogueLine] = []
	var line := DialogueLine.new()
	line.speaker_name = npc_name
	line.text = question
	line.portrait = npc_portrait
	lines.append(line)

	_dialogue_ui.show_dialogue_with_choices(lines, ["是的，带来了", "不，还没有"])

	var choice: int = await _dialogue_ui.choice_selected

	if choice == 0:
		var count := _get_item_count(quest_item_name)
		var response_text: String
		if count >= quest_amount:
			response_text = "好的，谢谢！"
		else:
			response_text = "还不够哦！"

		var response_lines: Array[DialogueLine] = []
		var response_line := DialogueLine.new()
		response_line.speaker_name = npc_name
		response_line.text = response_text
		response_line.portrait = npc_portrait
		response_lines.append(response_line)

		_dialogue_ui.show_dialogue(response_lines)
	else:
		_dialogue_ui.hide_dialogue()


func _get_item_count(item_name: String) -> int:
	var manager := get_node("/root/InventoryManager")
	var total := 0
	for i in range(InventoryManager.INVENTORY_SIZE):
		var slot: InventorySlot = manager.get_slot(i)
		if slot != null and slot.item != null and slot.item.name == item_name:
			total += slot.item_count
	return total
