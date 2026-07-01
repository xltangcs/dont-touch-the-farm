@tool
extends Node2D

const PLAYER_LAYER := 4

@export var sprite: Texture2D = null

var _disabled_action: StringName = &""
var _disabled_key_label: String = ""

@onready var _tile_sprite: Sprite2D = $TileSprite2D
@onready var _trigger_area: Area2D = $Area2D


func _ready() -> void:
	_apply_sprite()
	if Engine.is_editor_hint():
		return

	_trigger_area.collision_mask = PLAYER_LAYER
	_trigger_area.body_entered.connect(_on_body_entered)


func setup_tile_effect(disabled_action: String, disabled_key_label: String = "") -> void:
	_disabled_action = StringName(disabled_action)
	_disabled_key_label = DisabledKeyConfig.resolve_label(disabled_action, disabled_key_label)


func _apply_sprite() -> void:
	if _tile_sprite and sprite:
		_tile_sprite.texture = sprite


func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return
	if _disabled_action.is_empty():
		return

	if body.has_method("apply_disabled_key"):
		body.apply_disabled_key(_disabled_action, _disabled_key_label)
