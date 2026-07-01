extends RefCounted
class_name DisabledKeyConfig

const ACTION_LABELS: Dictionary = {
	"walk_left": "A",
	"walk_up": "W",
	"walk_down": "S",
	"walk_right": "D",
}


static func get_label_for_action(action: String) -> String:
	if action.is_empty():
		return ""
	return str(ACTION_LABELS.get(action, action))


static func resolve_label(action: String, key_label: String) -> String:
	if not key_label.is_empty():
		return key_label
	return get_label_for_action(action)
