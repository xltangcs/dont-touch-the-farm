extends CanvasLayer

@onready var _force_mine_panel: ForceMinePanel = $CenterContainer/ForceMinePanel


func _ready() -> void:
	add_to_group("game_ui")


func request_force_mine_confirmation(
	resource_id: String,
	resource_amount: int,
	debuff_id: String
) -> bool:
	return await _force_mine_panel.show_and_wait(resource_id, resource_amount, debuff_id)
