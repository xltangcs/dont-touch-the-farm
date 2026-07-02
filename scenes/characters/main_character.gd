extends CharacterBody2D

@export var speed: float = 300.0

var _is_mining: bool = false
var _input_enabled: bool = true
var _facing: String = "forward"
var _disabled_action: StringName = &""
var _has_lit_torch: bool = false

@onready var _anim: AnimatedSprite2D = $AnimatedSprite2D

var _dialogue_ui: DialogueUi


func _ready() -> void:
	call_deferred("_find_dialogue_ui")
	_play_facing_idle()


func _find_dialogue_ui() -> void:
	var game_uis := get_tree().get_nodes_in_group("game_ui")
	if game_uis.size() > 0:
		_dialogue_ui = game_uis[0].get_node_or_null("DialogueUi") as DialogueUi


func _is_in_dialogue() -> bool:
	return _dialogue_ui != null and _dialogue_ui.visible


func set_input_enabled(enabled: bool) -> void:
	_input_enabled = enabled
	if not _input_enabled:
		velocity = Vector2.ZERO


func has_lit_torch() -> bool:
	return _has_lit_torch


func light_torch() -> void:
	if _has_lit_torch:
		return
	_has_lit_torch = true
	_refresh_anim_for_torch_state()


func extinguish_torch() -> void:
	if not _has_lit_torch:
		return
	_has_lit_torch = false
	_refresh_anim_for_torch_state()


func apply_disabled_key(action: StringName, key_label: String = "") -> void:
	_disabled_action = action
	var label := DisabledKeyConfig.resolve_label(str(action), key_label)

	var game_ui := get_tree().get_first_node_in_group("game_ui") as GameUi
	if game_ui:
		game_ui.set_disabled_key(label)


func _physics_process(_delta: float) -> void:
	if not _input_enabled or _is_mining or _is_in_dialogue():
		velocity = Vector2.ZERO
		move_and_slide()
		return

	var direction := Vector2.ZERO

	direction = _apply_walk_input(&"walk_right", Vector2.RIGHT, direction)
	direction = _apply_walk_input(&"walk_left", Vector2.LEFT, direction)
	direction = _apply_walk_input(&"walk_down", Vector2.DOWN, direction)
	direction = _apply_walk_input(&"walk_up", Vector2.UP, direction)

	velocity = direction.normalized() * speed

	if direction != Vector2.ZERO:
		_facing = _get_facing_from_direction(direction)
		_anim.play(_get_torch_animation(_facing))
	else:
		_play_facing_idle()

	move_and_slide()


func play_mine_toward(target_position: Vector2) -> void:
	_is_mining = true
	velocity = Vector2.ZERO

	var direction := target_position - global_position
	if direction.length_squared() < 0.01:
		direction = Vector2.DOWN

	_facing = _get_facing_from_direction(direction)
	_anim.play(_get_mine_animation(_facing))
	await _anim.animation_finished
	_is_mining = false
	_play_facing_idle()


func play_light_torch_at(target_position: Vector2) -> void:
	if _has_lit_torch or _is_mining:
		return

	await play_mine_toward(target_position)
	light_torch()


func _get_facing_from_direction(direction: Vector2) -> String:
	if abs(direction.x) > abs(direction.y):
		if direction.x > 0:
			return "right"
		return "left"

	if direction.y > 0:
		return "forward"
	return "back"


func _get_torch_prefix() -> String:
	return "fire_on" if _has_lit_torch else "fire_off"


func _get_torch_animation(facing: String) -> String:
	return "%s_%s" % [_get_torch_prefix(), facing]


func _get_torch_idle_animation(facing: String) -> String:
	return "%s_idle_%s" % [_get_torch_prefix(), facing]


func _get_mine_animation(facing: String) -> String:
	return "mine_%s" % facing


func _play_facing_idle() -> void:
	_anim.play(_get_torch_idle_animation(_facing))


func _refresh_anim_for_torch_state() -> void:
	if _is_mining:
		return
	if velocity != Vector2.ZERO:
		_anim.play(_get_torch_animation(_facing))
	else:
		_play_facing_idle()


func _apply_walk_input(action: StringName, delta: Vector2, direction: Vector2) -> Vector2:
	if action == _disabled_action:
		return direction
	if Input.is_action_pressed(action):
		return direction + delta
	return direction
