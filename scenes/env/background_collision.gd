@tool
extends TileMapLayer

@export var tile_source_id: int = 0
@export var tile_atlas_coords: Vector2i = Vector2i(0, 0)


func _ready():
	fill_collision()


func fill_collision():
	clear()

	var water_layer = get_parent().get_node("water") as TileMapLayer
	if not water_layer:
		push_warning("No 'water' TileMapLayer found")
		return

	var grass_layer = get_parent().get_node_or_null("grass") as TileMapLayer
	var grass_cells: Array[Vector2i] = grass_layer.get_used_cells() if grass_layer else []

	for cell in water_layer.get_used_cells():
		if cell not in grass_cells:
			set_cell(cell, tile_source_id, tile_atlas_coords)

	print("Collision filled: ", get_used_cells().size(), " cells")
