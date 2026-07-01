extends CharacterBody2D

@export var speed: float = 300.0

var _is_mining: bool = false
var _input_enabled: bool = true
var _facing: String = "forward"
var _disabled_action: StringName = &""

@onready var _anim: AnimatedSprite2D = $AnimatedSprite2D

var _dialogue_ui: DialogueUi


func _ready() -> void:
	call_deferred("_find_dialogue_ui")


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


func apply_disabled_key(action: StringName, _key_label: String = "") -> void:
	_disabled_action = action


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
		_anim.play(_get_walk_animation(_facing))
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


func _get_facing_from_direction(direction: Vector2) -> String:
	if abs(direction.x) > abs(direction.y):
		if direction.x > 0:
			return "right"
		return "left"

	if direction.y > 0:
		return "forward"
	return "back"


func _get_walk_animation(facing: String) -> String:
	return "normal_%s" % facing


func _get_idle_animation(facing: String) -> String:
	return "idle_%s" % facing


func _get_mine_animation(facing: String) -> String:
	return "mine_%s" % facing


func _play_facing_idle() -> void:
	_anim.play(_get_idle_animation(_facing))


func _apply_walk_input(action: StringName, delta: Vector2, direction: Vector2) -> Vector2:
	if action == _disabled_action:
		return direction
	if Input.is_action_pressed(action):
		return direction + delta
	return direction
