@tool
extends TileMapLayer

@export var tile_source_id: int = 1
@export var tile_atlas_coords: Vector2i = Vector2i(0, 0)

func _ready():
	fill_with_tiles()

func fill_with_tiles():
	clear()

	var viewport_w = ProjectSettings.get_setting("display/window/size/viewport_width", 1920)
	var viewport_h = ProjectSettings.get_setting("display/window/size/viewport_height", 1080)

	var source = tile_set.get_source(tile_source_id)
	var real_tile_size = source.texture_region_size

	var columns = ceili(float(viewport_w) / real_tile_size.x)
	var rows = ceili(float(viewport_h) / real_tile_size.y)

	for x in range(columns):
		for y in range(rows):
			set_cell(Vector2i(x, y), tile_source_id, tile_atlas_coords)
	
	print("Generate Successfully!")
