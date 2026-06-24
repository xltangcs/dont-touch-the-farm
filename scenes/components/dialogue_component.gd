extends Node
class_name DialogueComponent

## ────────────────────────────────────────────────────────────
## DialogueComponent — core dialogue engine attached as NPC child.
##
## Drives the entire dialogue flow:
##   TalkPrompt → DialogueUi → traversal → end.
##
## Wave 3 dependencies (DialogueUi refactor):
##   - signal advance_requested
##   - property is_active: bool
##   - method force_hide()
##   - method show_dialogue(node: DialogueNode, choices: Array[DialogueChoice] = [])
## These are accessed defensively (get / has_method / has_signal)
## so this component does NOT crash before Wave 3 is complete.
## ────────────────────────────────────────────────────────────

## ── Signals ───────────────────────────────────────────────

## Emitted when dialogue flow starts (after guards pass).
signal dialogue_started

## Emitted when dialogue flow ends (either normally or via abort).
signal dialogue_ended

## ── Exports ───────────────────────────────────────────────

## The DialogueTree resource that drives this NPC's conversation.
@export var dialogue_tree: DialogueTree

## Maximum distance (pixels) at which the TalkPrompt button appears.
@export var interaction_range: float = 150.0

## ── Internal state ────────────────────────────────────────

var _camera: Camera2D
var _dialogue_ui: DialogueUi
var _player: Node2D
var _player_in_range: bool = false
var _is_active: bool = false
var _current_index: int = 0
var _step_count: int = 0
var _max_steps: int = 100
var _prompt_button: Button

## ── Lifecycle ─────────────────────────────────────────────

func _ready() -> void:
	# --- cache camera ---
	_camera = get_viewport().get_camera_2d()

	# --- cache dialogue_ui via game_ui group ---
	var game_uis := get_tree().get_nodes_in_group("game_ui")
	if game_uis.is_empty():
		push_error("DialogueComponent: no node in group 'game_ui' found")
		return
	_dialogue_ui = game_uis[0].get_node("DialogueUi") as DialogueUi
	if _dialogue_ui == null:
		push_error("DialogueComponent: 'DialogueUi' node not found under game_ui")
		return

	# --- cache player ---
	var players := get_tree().get_nodes_in_group("player")
	if players.is_empty():
		push_error("DialogueComponent: no node in group 'player' found")
		return
	_player = players[0]

	# --- create TalkPrompt button as child of this component ---
	_prompt_button = Button.new()
	_prompt_button.text = "对话"
	_prompt_button.visible = false
	_prompt_button.pressed.connect(_on_talk_pressed)
	add_child(_prompt_button)

	# --- connect to DialogueUi signals ---
	if not _dialogue_ui.choice_selected.is_connected(_on_choice_selected):
		_dialogue_ui.choice_selected.connect(_on_choice_selected)
	if not _dialogue_ui.dialogue_ended.is_connected(_on_dialogue_ended):
		_dialogue_ui.dialogue_ended.connect(_on_dialogue_ended)

	# Wave 3: DialogueUi will gain an advance_requested signal.
	# Connect defensively now so it just works after the refactor.
	if _dialogue_ui.has_signal("advance_requested"):
		_dialogue_ui.advance_requested.connect(_on_advance_requested)
	# TODO(Wave 3): uncomment when signal exists:
	# _dialogue_ui.advance_requested.connect(_on_advance_requested)


func _process(_delta: float) -> void:
	if _camera == null:
		_prompt_button.visible = false
		return

	# --- position the prompt button above the NPC ---
	var npc_world_pos: Vector2 = get_parent().global_position
	_prompt_button.position = _camera.unproject_position(npc_world_pos)

	# --- range check ---
	var dist: float = _player.global_position.distance_to(npc_world_pos)
	_player_in_range = dist <= interaction_range

	# --- visibility logic ---
	# Wave 3: DialogueUi will have an is_active property.  Use get() for safety.
	var ui_active: bool = _dialogue_ui.get("is_active") if _dialogue_ui != null else false

	if _player_in_range and not ui_active:
		_prompt_button.visible = true
	else:
		_prompt_button.visible = false

	# --- force-hide if player walks away during dialogue ---
	# Wave 3: DialogueUi will have force_hide().
	if ui_active and not _player_in_range and _is_active:
		if _dialogue_ui.has_method("force_hide"):
			_dialogue_ui.force_hide()


func _exit_tree() -> void:
	# --- force-hide dialogue if still active on removal ---
	if is_instance_valid(_dialogue_ui):
		# Wave 3: is_active property
		if _dialogue_ui.get("is_active") == true:
			if _dialogue_ui.has_method("force_hide"):
				_dialogue_ui.force_hide()

		# --- disconnect signals with guards ---
		if _dialogue_ui.choice_selected.is_connected(_on_choice_selected):
			_dialogue_ui.choice_selected.disconnect(_on_choice_selected)
		if _dialogue_ui.dialogue_ended.is_connected(_on_dialogue_ended):
			_dialogue_ui.dialogue_ended.disconnect(_on_dialogue_ended)
		if _dialogue_ui.has_signal("advance_requested") and _dialogue_ui.advance_requested.is_connected(_on_advance_requested):
			_dialogue_ui.advance_requested.disconnect(_on_advance_requested)

	# --- free the prompt button ---
	if _prompt_button != null:
		_prompt_button.queue_free()

## ── Public API ────────────────────────────────────────────

## Start the dialogue flow from the supplied tree.
## Guards: null tree, empty nodes, already-active UI.
## Disables player input while dialogue runs.
func start_dialogue(tree: DialogueTree) -> void:
	if tree == null:
		push_error("DialogueComponent.start_dialogue: tree is null")
		return
	if tree.nodes.size() == 0:
		push_error("DialogueComponent.start_dialogue: tree has no nodes")
		return

	# Wave 3: is_active property on DialogueUi
	if _dialogue_ui != null and _dialogue_ui.get("is_active") == true:
		push_warning("DialogueComponent.start_dialogue: dialogue already active")
		return

	# --- disable player input ---
	if is_instance_valid(_player):
		_player.process_mode = Node.PROCESS_MODE_DISABLED

	_step_count = 0
	_is_active = true
	dialogue_started.emit()
	_traverse(tree.start_index)

## ── Internal traversal ────────────────────────────────────

## Traverse to the dialogue node at [index], enforcing the cycle guard.
func _traverse(index: int) -> void:
	_step_count += 1
	if _step_count > _max_steps:
		push_warning("DialogueComponent._traverse: max steps (%d) exceeded — aborting" % _max_steps)
		end_dialogue()
		return

	if index < 0 or index >= dialogue_tree.nodes.size():
		push_error("DialogueComponent._traverse: index %d out of bounds (0-%d)" % [index, dialogue_tree.nodes.size() - 1])
		end_dialogue()
		return

	_current_index = index
	var node: DialogueNode = dialogue_tree.nodes[index]

	# Wave 3: DialogueUi will have a merged show_dialogue(node, choices) signature.
	# For now the UI uses the old two-method API (show_dialogue / show_dialogue_with_choices).
	# This call targets the Wave 3 signature directly.
	_dialogue_ui.show_dialogue(node, node.choices)

## ── Signal handlers ───────────────────────────────────────

func _on_talk_pressed() -> void:
	# Wave 3: is_active property on DialogueUi
	if _dialogue_ui != null and _dialogue_ui.get("is_active") == true:
		push_warning("DialogueComponent: dialogue already active, ignoring talk press")
		return
	start_dialogue(dialogue_tree)


## Wave 3: connected to DialogueUi.advance_requested.
## Called when the player advances past a non-choice node.
func _on_advance_requested() -> void:
	var node: DialogueNode = dialogue_tree.nodes[_current_index]
	if node.choices.size() > 0:
		# Node has choices — player must pick one; ignore raw advance.
		return
	if node.next_index == -1:
		end_dialogue()
	else:
		_traverse(node.next_index)


func _on_choice_selected(choice_index: int) -> void:
	var node: DialogueNode = dialogue_tree.nodes[_current_index]
	if choice_index < 0 or choice_index >= node.choices.size():
		push_error("DialogueComponent._on_choice_selected: index %d out of bounds (0-%d)" % [choice_index, node.choices.size() - 1])
		return

	var choice: DialogueChoice = node.choices[choice_index]
	if choice.next_index == -1:
		end_dialogue()
	else:
		_traverse(choice.next_index)


## Called when DialogueUi finishes its hide animation (or is force-hidden).
## This signal exists on the current DialogueUi — no Wave 3 dependency.
func _on_dialogue_ended() -> void:
	_is_active = false
	if is_instance_valid(_player):
		_player.process_mode = Node.PROCESS_MODE_INHERIT

## ── Dialogue termination ──────────────────────────────────

## End the dialogue flow, restore player input, and emit dialogue_ended.
## Idempotent: safe to call even if already inactive.
func end_dialogue() -> void:
	_is_active = false
	if is_instance_valid(_player):
		_player.process_mode = Node.PROCESS_MODE_INHERIT
	dialogue_ended.emit()
