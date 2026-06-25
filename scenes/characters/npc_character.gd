extends Node2D

@export var npc_name: String = "NPC"
@export var npc_portrait: Texture2D

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D

func _ready() -> void:
	animated_sprite_2d.play("idle")
