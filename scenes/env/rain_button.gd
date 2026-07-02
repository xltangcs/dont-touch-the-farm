@tool
extends Node2D

const PLAYER_LAYER := 4
const TEX_RAIN_KEY := preload("res://assets/environment/tileset/rain_key.png")

@export var sprite: Texture2D = null
@export var rain_target_id: String = ""

var _target_rain_id: String = ""

@onready var _tile_sprite: Sprite2D = $TileSprite2D


func _ready() -> void:
	if not rain_target_id.is_empty():
		_target_rain_id = rain_target_id
	_apply_sprite()

	if Engine.is_editor_hint():
		return

	var trigger_area := get_node_or_null("Area2D") as Area2D
	if trigger_area == null:
		return
	trigger_area.collision_mask = PLAYER_LAYER
	if not trigger_area.body_entered.is_connected(_on_body_entered):
		trigger_area.body_entered.connect(_on_body_entered)


func setup_rain_button(target_id: String) -> void:
	rain_target_id = target_id
	_target_rain_id = target_id


func _apply_sprite() -> void:
	if not _tile_sprite:
		return
	if sprite:
		_tile_sprite.texture = sprite
	else:
		_tile_sprite.texture = TEX_RAIN_KEY


func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return
	if _target_rain_id.is_empty():
		return
	RainManager.stop_rain(_target_rain_id)
