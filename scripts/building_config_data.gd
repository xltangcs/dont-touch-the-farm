extends RefCounted

const InteractConfigData = preload("res://scripts/interact_config_data.gd")

var id: String = ""
var display_name: String = ""
var building_texture: Texture2D
var action_text: String = "upgrade"
var button_variation: StringName = &"BuildingBuildButton"


func get_interact_config() -> InteractConfigData:
	var interact := InteractConfigData.new()
	interact.action_text = action_text
	interact.action_icon = null
	interact.button_variation = button_variation
	return interact
