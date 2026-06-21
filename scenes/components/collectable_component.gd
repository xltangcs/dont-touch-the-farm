extends Area2D

signal collected(item_id: String, amount: int, collector: Node2D)

@export var item_id: String = ""
@export var amount: int = 1


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func set_item(new_item_id: String, new_amount: int) -> void:
	item_id = new_item_id
	amount = new_amount


func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return

	collected.emit(item_id, amount, body)
	get_parent().queue_free()
