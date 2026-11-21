extends Label


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	text = "Memory: " + str(GameState.memory)
	GameState.memory_changed.connect(_on_memory_changed)

func _on_memory_changed(new_value):
	text = "Memory: " + str(new_value)
