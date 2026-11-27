extends Node2D

@export var free_retries := false

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	GameState.start_level(free_retries)


func _on_floor_button_activated() -> void:
	pass # Replace with function body.
