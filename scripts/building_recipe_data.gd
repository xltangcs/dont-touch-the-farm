extends RefCounted

const BuildingRecipeInputData = preload("res://scripts/building_recipe_input_data.gd")

var output_id: String = ""
var output_amount: int = 1
var display_name: String = ""
var description: String = ""
var product_texture: Texture2D
var inputs: Array = []


func get_input(item_id: String) -> BuildingRecipeInputData:
	for entry in inputs:
		if entry is BuildingRecipeInputData and entry.item_id == item_id:
			return entry
	return null


func get_required_amount(item_id: String) -> int:
	var input := get_input(item_id)
	if input == null:
		return 0
	return input.amount


func get_inputs_summary() -> String:
	if inputs.is_empty():
		return ""

	var parts: PackedStringArray = []
	for entry in inputs:
		if entry is BuildingRecipeInputData:
			parts.append("%s x%d" % [entry.item_id, entry.amount])
	return ", ".join(parts)
