extends RefCounted

const InteractConfigData = preload("res://scripts/interact_config_data.gd")

var id: String = ""
var display_name: String = ""
var block_texture: Texture2D
var resource_id: String = ""
var resource_icon: Texture2D
var resource_amount: int = 1
var max_mine_count: int = 1
var requires_force_mining: bool = false
var debuff_id: String = ""
var action_text: String = "mine"
var restricted_action_text: String = "mine?"


func get_interact_config() -> InteractConfigData:
	var interact := InteractConfigData.new()
	interact.action_icon = resource_icon

	if requires_force_mining:
		interact.action_text = restricted_action_text
		interact.button_variation = &"BlockRestrictedMineButton"
	else:
		interact.action_text = action_text
		interact.button_variation = &"BlockMineButton"

	return interact
