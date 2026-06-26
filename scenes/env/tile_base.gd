@tool
extends Node2D

@export var sprite: Texture2D = null

@onready var tile_sprite_2d: Sprite2D = $TileSprite2D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	tile_sprite_2d.texture = sprite
