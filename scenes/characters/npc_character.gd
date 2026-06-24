extends Node2D

@export var npc_name: String = "NPC"
@export var npc_portrait: Texture2D

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var _interaction_area: Area2D = $CollisionShape2D
@onready var dialogue_component: DialogueComponent = $DialogueComponent

var _player_in_range: bool = false


func _ready() -> void:
	animated_sprite_2d.play("idle")
	_interaction_area.body_entered.connect(_on_body_entered)
	_interaction_area.body_exited.connect(_on_body_exited)


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		_player_in_range = true
		if dialogue_component:
			dialogue_component._player_in_range = true


func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		_player_in_range = false
		if dialogue_component:
			dialogue_component._player_in_range = false
