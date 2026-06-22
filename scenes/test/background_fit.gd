extends Sprite2D

func _ready():
	var viewport_size = get_viewport().get_visible_rect().size
	var tex_size = texture.get_size()
	scale = viewport_size / tex_size
