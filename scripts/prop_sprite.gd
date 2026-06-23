@tool
extends Sprite2D

var _last_texture: Texture2D


func _ready() -> void:
	_apply_settings()


func _process(_delta: float) -> void:
	if not Engine.is_editor_hint():
		set_process(false)
		return
	if texture != _last_texture:
		_last_texture = texture
		_apply_settings()


func _apply_settings() -> void:
	if not is_instance_valid(texture):
		return
	var h = texture.get_height()
	if h <= 0:
		return
	centered = true
	offset = Vector2(0, -h / 2.0)
	y_sort_enabled = true
	z_index = 1
