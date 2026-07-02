@tool
extends Node2D

const PLAYER_LAYER := 4

var _zone: Node = null
var _area: Area2D = null


func setup(zone: Node) -> void:
	_zone = zone
	_area = $Area2D
	if Engine.is_editor_hint():
		set_zone_active(zone.is_active())
		return
	_area.collision_mask = PLAYER_LAYER
	if not _area.body_entered.is_connected(_on_body_entered):
		_area.body_entered.connect(_on_body_entered)
	set_zone_active(zone.is_active())


func set_zone_active(active: bool) -> void:
	visible = active
	if _area:
		_area.monitoring = active


func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return
	if _zone and _zone.has_method("on_player_entered"):
		_zone.on_player_entered()
