@tool
extends Node2D

const TEX_UNLIT := preload("res://assets/environment/tileset/fire_off.png")
const TEX_LIT := preload("res://assets/environment/tileset/fire_on.png")
const PLAYER_LAYER := 4

@export var sprite: Texture2D = null
@export var initial_lit: bool = false

var _is_lit: bool = false
var _is_raining: bool = false
var _lighting_player: bool = false

@onready var _tile_sprite: Sprite2D = $TileSprite2D
@onready var _interact_area: Area2D = $InteractArea


func _ready() -> void:
	_is_lit = initial_lit
	_apply_sprite()

	if Engine.is_editor_hint():
		return

	add_to_group("campfire")
	_interact_area.collision_mask = PLAYER_LAYER
	_interact_area.body_entered.connect(_on_body_entered)


func set_raining(raining: bool) -> void:
	_is_raining = raining
	if raining and _is_lit:
		_is_lit = false
		_apply_sprite()


func is_lit() -> bool:
	return _is_lit


func _apply_sprite() -> void:
	if not _tile_sprite:
		return
	if _is_lit:
		_tile_sprite.texture = TEX_LIT
	elif sprite:
		_tile_sprite.texture = sprite
	else:
		_tile_sprite.texture = TEX_UNLIT


func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return
	_try_interact_with_player(body)


func _try_interact_with_player(player: Node2D) -> void:
	if _is_raining or _lighting_player:
		return

	if _is_lit:
		if player.has_method("has_lit_torch") and player.has_lit_torch():
			return
		if player.has_method("play_light_torch_at"):
			_lighting_player = true
			await player.play_light_torch_at(global_position)
			_lighting_player = false
		return

	if not player.has_method("has_lit_torch"):
		return
	if not player.has_lit_torch():
		return

	_is_lit = true
	_apply_sprite()
