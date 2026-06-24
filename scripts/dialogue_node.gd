extends Resource

class_name DialogueNode

@export var speaker: String = ""
@export_multiline var text: String = ""
@export var portrait: Texture2D
@export var next_index: int = -1
@export var choices: Array[DialogueChoice] = []
