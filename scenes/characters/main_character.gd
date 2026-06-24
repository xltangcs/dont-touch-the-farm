extends CharacterBody2D

@export var speed: float = 300.0

var _is_mining: bool = false

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


func _physics_process(_delta: float) -> void:
	if _is_mining or _is_in_dialogue():
		velocity = Vector2.ZERO
		move_and_slide()
		return

	var direction := Vector2.ZERO

	if Input.is_action_pressed("walk_right"):
		direction.x += 1
	if Input.is_action_pressed("walk_left"):
		direction.x -= 1
	if Input.is_action_pressed("walk_down"):
		direction.y += 1
	if Input.is_action_pressed("walk_up"):
		direction.y -= 1

	velocity = direction.normalized() * speed

	if direction != Vector2.ZERO:
		if abs(direction.x) > abs(direction.y):
			if direction.x > 0:
				_anim.play("normal_right")
			else:
				_anim.play("normal_left")
		else:
			if direction.y > 0:
				_anim.play("normal_forward")
			else:
				_anim.play("normal_back")
	else:
		_anim.play("idle")

	move_and_slide()


func play_mine_toward(target_position: Vector2) -> void:
	_is_mining = true
	velocity = Vector2.ZERO

	var direction := target_position - global_position
	if direction.length_squared() < 0.01:
		direction = Vector2.DOWN

	_anim.play(_get_mine_animation_name(direction))
	await _anim.animation_finished
	_is_mining = false


func _get_mine_animation_name(direction: Vector2) -> String:
	if abs(direction.x) > abs(direction.y):
		if direction.x > 0:
			return "mine_right"
		return "mine_left"

	if direction.y > 0:
		return "mine_forward"
	return "mine_back"
